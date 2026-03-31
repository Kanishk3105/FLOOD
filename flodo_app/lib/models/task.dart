class TaskStatus {
  static const todo = 'To-Do';
  static const inProgress = 'In Progress';
  static const done = 'Done';

  static const List<String> values = [todo, inProgress, done];

  /// Maps legacy or alternate API values (e.g. `pending`, `completed`) to [values].
  static String normalize(String? raw) {
    if (raw == null) return todo;
    final s = raw.trim();
    if (s.isEmpty) return todo;
    if (values.contains(s)) return s;

    final lower = s.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (lower == 'pending' || lower == 'todo' || lower == 'to do') return todo;
    if (lower.contains('progress')) return inProgress;
    if (lower == 'completed' || lower == 'done' || lower == 'complete') return done;
    return todo;
  }
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final int? blockedByTaskId;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedByTaskId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: TaskStatus.normalize(json['status'] as String?),
      blockedByTaskId: json['blocked_by_task_id'] as int?,
    );
  }

  /// JSON for API create/update (no `id`).
  Map<String, dynamic> toApiBody() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': status,
      'blocked_by_task_id': blockedByTaskId,
    };
  }

  /// Full map for local draft persistence.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toUtc().toIso8601String(),
      'status': status,
      'blocked_by_task_id': blockedByTaskId,
    };
  }

  factory Task.fromJsonMap(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      status: TaskStatus.normalize(json['status'] as String?),
      blockedByTaskId: json['blocked_by_task_id'] as int?,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    int? blockedByTaskId,
    bool clearBlockedBy = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedByTaskId: clearBlockedBy ? null : (blockedByTaskId ?? this.blockedByTaskId),
    );
  }
}

/// True when this task is blocked by another task that is not yet Done.
bool isTaskBlocked(Task task, List<Task> allTasks) {
  final blockerId = task.blockedByTaskId;
  if (blockerId == null) return false;
  for (final t in allTasks) {
    if (t.id == blockerId) {
      return TaskStatus.normalize(t.status) != TaskStatus.done;
    }
  }
  return false;
}
