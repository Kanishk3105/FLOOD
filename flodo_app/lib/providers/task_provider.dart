import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  final TaskRepository _repository = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _searchQuery;
  String? _statusFilter;
  Task? _draftTask;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  Task? get draftTask => _draftTask;

  TaskProvider() {
    loadDraft();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _repository.getTasks(
        search: _searchQuery,
        status: _statusFilter,
      );
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask(Task task) async {
    try {
      final newTask = await _repository.createTask(task);
      _tasks.add(newTask);
      clearDraft();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final updatedTask = await _repository.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      clearDraft();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _repository.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    loadTasks();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadTasks();
  }

  void saveDraft(Task task) {
    _draftTask = task;
    _saveDraftToPrefs();
    notifyListeners();
  }

  void clearDraft() {
    _draftTask = null;
    _clearDraftFromPrefs();
    notifyListeners();
  }

  Future<void> _saveDraftToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_draftTask != null) {
      prefs.setString('draft_task', _draftTask!.toJson().toString());
    }
  }

  Future<void> _clearDraftFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('draft_task');
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString('draft_task');
    if (draftJson != null) {
      _draftTask = Task.fromJson(json.decode(draftJson));
      notifyListeners();
    }
  }
}
