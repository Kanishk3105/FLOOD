import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Task? task}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );
    if (mounted) {
      await context.read<TaskProvider>().loadTasks();
    }
  }

  Future<void> _onRefresh() => context.read<TaskProvider>().loadTasks();

  ({Color fg, Color bg, IconData icon}) _statusStyle(String status, ColorScheme scheme) {
    switch (status) {
      case TaskStatus.done:
        return (
          fg: const Color(0xFF1B5E20),
          bg: const Color(0xFFE8F5E9),
          icon: Icons.check_circle_rounded,
        );
      case TaskStatus.inProgress:
        return (
          fg: const Color(0xFFE65100),
          bg: const Color(0xFFFFF3E0),
          icon: Icons.timelapse_rounded,
        );
      default:
        return (
          fg: scheme.primary,
          bg: scheme.primaryContainer.withValues(alpha: 0.35),
          icon: Icons.radio_button_unchecked_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New task'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.75,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search, filter by status, tap a card to edit.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by title',
                          hintText: 'Find a task…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.setSearchQuery(null);
                                    setState(() {});
                                  },
                                ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                          provider.setSearchQuery(value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Status filter',
                          prefixIcon: Icon(Icons.filter_list_rounded),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All statuses'),
                          ),
                          ...TaskStatus.values.map(
                            (s) => DropdownMenuItem<String?>(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                          provider.setStatusFilter(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading tasks…',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : provider.tasks.isEmpty
                      ? _EmptyState(onCreate: () => _openForm())
                      : RefreshIndicator(
                          onRefresh: _onRefresh,
                          edgeOffset: 12,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                            itemCount: provider.tasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final task = provider.tasks[index];
                              final blocked = isTaskBlocked(task, provider.tasks);
                              final st = _statusStyle(task.status, scheme);
                              return _TaskCard(
                                task: task,
                                blocked: blocked,
                                statusFg: st.fg,
                                statusBg: st.bg,
                                statusIcon: st.icon,
                                onTap: () => _openForm(task: task),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        Icon(
          Icons.task_alt_rounded,
          size: 72,
          color: scheme.primary.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 20),
        Text(
          'No tasks yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Create your first task or pull down to refresh if the server already has data.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create task'),
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.blocked,
    required this.statusFg,
    required this.statusBg,
    required this.statusIcon,
    required this.onTap,
  });

  final Task task;
  final bool blocked;
  final Color statusFg;
  final Color statusBg;
  final IconData statusIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final card = Material(
      color: blocked ? scheme.surfaceContainerHighest.withValues(alpha: 0.65) : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: blocked
              ? scheme.outlineVariant
              : scheme.outline.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(statusIcon, size: 22, color: statusFg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: blocked ? scheme.onSurfaceVariant : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task.status,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat.MMMEd().add_jm().format(task.dueDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (blocked) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.lock_clock_rounded, size: 18, color: scheme.tertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Blocked until dependency is Done',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!blocked) return card;

    return Opacity(
      opacity: 0.78,
      child: card,
    );
  }
}
