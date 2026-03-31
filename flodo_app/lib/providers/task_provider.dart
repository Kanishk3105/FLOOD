import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskProvider with ChangeNotifier {
  TaskProvider({TaskRepository? repository})
      : _repository = repository ?? TaskRepository() {
    loadDraft();
  }

  final TaskRepository _repository;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _statusFilter;
  Task? _draftTask;

  static const _draftKey = 'draft_task';

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  Task? get draftTask => _draftTask;

  TaskRepository get repository => _repository;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _repository.getTasks(
        search: _searchQuery,
        status: _statusFilter,
      );
    } catch (e, stackTrace) {
      debugPrint('loadTasks failed: $e\n$stackTrace');
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask(Task task) async {
    final newTask = await _repository.createTask(task);
    _tasks.add(newTask);
    await clearDraft();
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final updatedTask = await _repository.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
    }
    notifyListeners();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    final normalized = query?.trim();
    _searchQuery = normalized == null || normalized.isEmpty ? null : normalized;
    loadTasks();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadTasks();
  }

  Future<void> saveDraft(Task task) async {
    _draftTask = task;
    await _saveDraftToPrefs();
    notifyListeners();
  }

  Future<void> clearDraft() async {
    _draftTask = null;
    await _clearDraftFromPrefs();
    notifyListeners();
  }

  Future<void> _saveDraftToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_draftTask != null) {
      await prefs.setString(_draftKey, jsonEncode(_draftTask!.toJson()));
    }
  }

  Future<void> _clearDraftFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson != null) {
      try {
        _draftTask = Task.fromJsonMap(
          json.decode(draftJson) as Map<String, dynamic>,
        );
        notifyListeners();
      } catch (_) {
        await prefs.remove(_draftKey);
      }
    }
  }
}
