import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/task.dart';

class TaskRepository {
  TaskRepository({String? baseUrl}) : baseUrl = baseUrl ?? taskApiBaseUrl();

  final String baseUrl;

  Future<List<Task>> getTasks({String? search, String? status}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    final uri = Uri.parse('$baseUrl/tasks').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load tasks (${response.statusCode})');
  }

  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toApiBody()),
    );
    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create task (${response.statusCode})');
  }

  Future<Task> updateTask(Task task) async {
    final id = task.id;
    if (id == null) {
      throw Exception('Task id required for update');
    }
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toApiBody()),
    );
    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update task (${response.statusCode})');
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete task (${response.statusCode})');
    }
  }
}
