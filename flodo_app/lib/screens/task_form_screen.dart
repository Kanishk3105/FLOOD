import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  TaskFormScreenState createState() => TaskFormScreenState();
}

class TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _blockedController;
  late DateTime _dueDate;
  late String _status;
  int? _blockedByTaskId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<TaskProvider>();
    final draft = provider.draftTask;
    final task = widget.task ?? draft;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _blockedController = TextEditingController(
      text: _blockedByTaskId?.toString(),
    );
    _dueDate = task?.dueDate ?? DateTime.now();
    _status = task?.status ?? 'pending';
    _blockedByTaskId = task?.blockedByTaskId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _blockedController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate,
      status: _status,
      blockedByTaskId: int.tryParse(_blockedController.text),
    );
    context.read<TaskProvider>().saveDraft(task);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<TaskProvider>();
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate,
      status: _status,
      blockedByTaskId: int.tryParse(_blockedController.text),
    );
    try {
      if (widget.task == null) {
        await provider.createTask(task);
      } else {
        await provider.updateTask(task);
      }
      provider.clearDraft();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create Task' : 'Edit Task'),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await context.read<TaskProvider>().deleteTask(widget.task!.id!);
                if (mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (_) => _saveDraft(),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onChanged: (_) => _saveDraft(),
              ),
              Row(
                children: [
                  Text('Due Date: ${DateFormat.yMd().format(_dueDate)}'),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _status,
                items: ['pending', 'completed'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => setState(() => _status = value!),
                decoration: InputDecoration(labelText: 'Status'),
              ),
              TextFormField(
                controller: _blockedController,
                decoration: InputDecoration(
                  labelText: 'Blocked by Task ID (optional)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _blockedByTaskId = int.tryParse(value),
              ),
              SizedBox(height: 20),
              _isSaving
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.task == null ? 'Create' : 'Update'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
