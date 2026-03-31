import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _error;
  DashboardData _data = DashboardData();
  List<CommandTask> _tasks = [];
  List<CalendarEvent> _events = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  DashboardData get data => _data;
  List<CommandTask> get tasks => _tasks;
  List<CalendarEvent> get events => _events;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _api.getDashboard();
    } catch (e) {
      _error = 'Failed to load dashboard';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    try {
      _tasks = await _api.getTasks();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tasks';
      notifyListeners();
    }
  }

  Future<void> loadEvents({String? month}) async {
    try {
      _events = await _api.getCalendarEvents(month: month);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load events';
      notifyListeners();
    }
  }

  Future<bool> createTask({
    required String title,
    String taskType = 'custom',
    String priority = 'normal',
    String? dueDate,
    String? description,
    bool sendReminder = true,
  }) async {
    try {
      await _api.createTask(
        title: title,
        taskType: taskType,
        priority: priority,
        dueDate: dueDate,
        description: description,
        sendReminder: sendReminder,
      );
      await loadDashboard();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createEvent({
    required String title,
    required String eventDate,
    String? endDate,
    String eventType = 'manual',
    String priority = 'normal',
    bool allDay = false,
    String? description,
    bool sendReminder = true,
  }) async {
    try {
      await _api.createEvent(
        title: title,
        eventDate: eventDate,
        endDate: endDate,
        eventType: eventType,
        priority: priority,
        allDay: allDay,
        description: description,
        sendReminder: sendReminder,
      );
      await loadDashboard();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> completeTask(int taskId) async {
    try {
      await _api.completeTask(taskId);
      await loadDashboard();
    } catch (_) {}
  }

  Future<void> completeEvent(int eventId) async {
    try {
      await _api.completeEvent(eventId);
      await loadDashboard();
    } catch (_) {}
  }

  Future<void> resolveTask(int taskId, {required String resolution, int? extendDays}) async {
    try {
      await _api.resolveTask(taskId, resolution: resolution, extendDays: extendDays);
      await loadDashboard();
    } catch (_) {}
  }

  Future<void> resolveEvent(int eventId, {required String resolution, int? extendDays}) async {
    try {
      await _api.resolveEvent(eventId, resolution: resolution, extendDays: extendDays);
      await loadDashboard();
    } catch (_) {}
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    try {
      await _api.updateTaskStatus(taskId, status);
      await loadDashboard();
    } catch (_) {}
  }
}
