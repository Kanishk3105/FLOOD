import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  TaskFormScreenState createState() => TaskFormScreenState();
}

class TaskFormScreenState extends State<TaskFormScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final TaskProvider _provider;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  late String _status;
  int? _blockedByTaskId;
  bool _isSaving = false;
  bool _persistDraftOnLeave = true;

  bool get _isNewTask => widget.task == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = context.read<TaskProvider>();
    final draft = _isNewTask ? _provider.draftTask : null;
    final task = widget.task ?? draft;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate ?? DateTime.now();
    _status = TaskStatus.normalize(task?.status);
    _blockedByTaskId = task?.blockedByTaskId;
    final selfId = widget.task?.id;
    if (selfId != null && _blockedByTaskId == selfId) {
      _blockedByTaskId = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isNewTask && _persistDraftOnLeave) {
      _persistDraftFromControllers();
    }
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isNewTask || !_persistDraftOnLeave) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _persistDraftFromControllers();
    }
  }

  void _persistDraftFromControllers() {
    final task = Task(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate,
      status: _status,
      blockedByTaskId: _blockedByTaskId,
    );
    _provider.saveDraft(task);
  }

  void _saveDraft() {
    if (!_isNewTask) return;
    _persistDraftFromControllers();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      status: _status,
      blockedByTaskId: _blockedByTaskId,
    );
    try {
      if (_isNewTask) {
        await _provider.createTask(task);
      } else {
        await _provider.updateTask(task);
      }
      _persistDraftOnLeave = false;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not save: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      _saveDraft();
    }
  }

  Future<void> _confirmDelete() async {
    final id = widget.task?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.delete_outline_rounded, color: Theme.of(ctx).colorScheme.error),
            title: const Text('Delete task?'),
            content: const Text('This removes the task from the server. Tasks that depended on it will be unblocked.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;
    try {
      await _provider.deleteTask(id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Could not delete: $e'),
          ),
        );
      }
    }
  }

  List<Task> _blockerCandidates(List<Task> all) {
    final selfId = widget.task?.id;
    return all.where((t) => t.id != null && t.id != selfId).toList();
  }

  /// Ensures dropdown value always matches exactly one [DropdownMenuItem].
  List<DropdownMenuItem<int?>> _blockedByItems(List<Task> blockers, int? selected) {
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(
        value: null,
        child: Text('No dependency'),
      ),
      ...blockers.map(
        (t) => DropdownMenuItem<int?>(
          value: t.id,
          child: Text(
            t.title,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    final selectableIds = blockers.map((t) => t.id).toSet();
    if (selected != null && !selectableIds.contains(selected)) {
      items.add(
        DropdownMenuItem<int?>(
          value: selected,
          child: Text(
            'Task #$selected (not in list — save to clear or pick another)',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return items;
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = context.watch<TaskProvider>().tasks;
    final blockers = _blockerCandidates(allTasks);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = DateFormat.yMMMEd().format(_dueDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewTask ? 'New task' : 'Edit task'),
        actions: [
          if (!_isNewTask)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _sectionLabel(context, 'DETAILS'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What needs to be done?',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Title is required' : null,
                      onChanged: (_) => _saveDraft(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add context, links, or acceptance criteria…',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      minLines: 3,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Description is required' : null,
                      onChanged: (_) => _saveDraft(),
                    ),
                  ],
                ),
              ),
            ),
            _sectionLabel(context, 'SCHEDULE & STATUS'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
                        child: Icon(Icons.event_rounded, color: scheme.primary),
                      ),
                      title: const Text('Due date'),
                      subtitle: Text(dateLabel, style: theme.textTheme.titleSmall),
                      trailing: FilledButton.tonal(
                        onPressed: _selectDate,
                        child: const Text('Change'),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag_rounded),
                        ),
                        items: TaskStatus.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _status = value);
                          _saveDraft();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _sectionLabel(context, 'DEPENDENCY'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int?>(
                  value: _blockedByTaskId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Blocked by (optional)',
                    helperText: 'This task stays visually blocked until the chosen task is Done.',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  items: _blockedByItems(blockers, _blockedByTaskId),
                  onChanged: (value) {
                    setState(() => _blockedByTaskId = value);
                    _saveDraft();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text(_isNewTask ? 'Save task' : 'Update task'),
            ),
            if (_isNewTask) ...[
              const SizedBox(height: 12),
              Text(
                'Drafts are saved automatically if you leave this screen or send the app to the background.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
