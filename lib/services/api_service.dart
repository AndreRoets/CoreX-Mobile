import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/dashboard_data.dart';

class ApiService {
  static String get baseUrl => Env.apiBaseUrl;
  static bool get useMockData => Env.useMockData;

  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Login ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        'token': 'mock-token-abc123',
        'user': {
          'id': 1,
          'name': 'John Moosa',
          'email': email,
          'branch': 'Amanzimtoti',
          'ffc_status': 'Active',
        },
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, 'Login failed');
  }

  // --- Profile ---

  Future<Map<String, dynamic>> getProfile() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'id': 1,
        'name': 'John Moosa',
        'email': 'john@hfcoastal.co.za',
        'branch': 'Amanzimtoti',
        'ffc_status': 'Active',
      };
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, 'Failed to load profile');
  }

  // --- Dashboard ---

  Future<DashboardData> getDashboard() async {
    if (useMockData) return _mockDashboard();

    final response = await http.get(
      Uri.parse('$baseUrl/command-center/dashboard'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return DashboardData.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to load dashboard');
  }

  // --- Tasks ---

  Future<List<CommandTask>> getTasks({String? status}) async {
    if (useMockData) return _mockTasks();

    final uri = Uri.parse('$baseUrl/command-center/tasks')
        .replace(queryParameters: status != null ? {'status': status} : null);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List ? data : (data['data'] ?? data['tasks'] ?? []);
      return (list as List).map((e) => CommandTask.fromJson(e)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to load tasks');
  }

  Future<CommandTask> createTask({
    required String title,
    String taskType = 'custom',
    String priority = 'normal',
    String? dueDate,
    String? description,
    bool sendReminder = true,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return CommandTask(id: 999, title: title, taskType: taskType, priority: priority);
    }

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/tasks'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'task_type': taskType,
        'priority': priority,
        if (dueDate != null) 'due_date': dueDate,
        if (description != null) 'description': description,
        'send_reminder': sendReminder,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CommandTask.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create task');
  }

  Future<void> completeTask(int taskId) async {
    if (useMockData) return;

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/tasks/$taskId/complete'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to complete task');
    }
  }

  Future<void> updateTaskStatus(int taskId, String status) async {
    if (useMockData) return;

    final response = await http.patch(
      Uri.parse('$baseUrl/command-center/tasks/$taskId/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to update task status');
    }
  }

  Future<void> resolveTask(int taskId, {required String resolution, int? extendDays, String? note}) async {
    if (useMockData) return;

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/resolve-task/$taskId'),
      headers: await _headers(),
      body: jsonEncode({
        'resolution': resolution,
        if (extendDays != null) 'extend_days': extendDays,
        if (note != null) 'resolution_note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to resolve task');
    }
  }

  // --- Calendar Events ---

  Future<List<CalendarEvent>> getCalendarEvents({String? month}) async {
    if (useMockData) return _mockEvents();

    final uri = Uri.parse('$baseUrl/command-center/calendar/events')
        .replace(queryParameters: month != null ? {'month': month} : null);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data is List ? data : (data['data'] ?? data['events'] ?? []);
      return (list as List).map((e) => CalendarEvent.fromJson(e)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to load events');
  }

  Future<CalendarEvent> createEvent({
    required String title,
    required String eventDate,
    String? endDate,
    String eventType = 'manual',
    String priority = 'normal',
    bool allDay = false,
    String? description,
    bool sendReminder = true,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return CalendarEvent(id: 999, title: title, eventDate: DateTime.parse(eventDate));
    }

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/calendar'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'event_date': eventDate,
        if (endDate != null) 'end_date': endDate,
        'event_type': eventType,
        'priority': priority,
        'all_day': allDay,
        if (description != null) 'description': description,
        'send_reminder': sendReminder,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CalendarEvent.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create event');
  }

  Future<void> completeEvent(int eventId) async {
    if (useMockData) return;

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/calendar/$eventId/complete'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to complete event');
    }
  }

  Future<void> resolveEvent(int eventId, {required String resolution, int? extendDays, String? note}) async {
    if (useMockData) return;

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/resolve-event/$eventId'),
      headers: await _headers(),
      body: jsonEncode({
        'resolution': resolution,
        if (extendDays != null) 'extend_days': extendDays,
        if (note != null) 'resolution_note': note,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to resolve event');
    }
  }

  // --- Properties ---

  Future<List<Map<String, dynamic>>> getProperties() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      return [
        {'id': 1, 'address': '12 Marine Drive, Amanzimtoti', 'price': 1250000, 'status': 'Active'},
        {'id': 2, 'address': '45 Beach Road, Umkomaas', 'price': 2100000, 'status': 'Pending'},
        {'id': 3, 'address': '8 Ocean View Crescent, Warner Beach', 'price': 875000, 'status': 'Sold'},
        {'id': 4, 'address': '23 Kingsway, Scottburgh', 'price': 1650000, 'status': 'Active'},
      ];
    }

    final response = await http.get(
      Uri.parse('$baseUrl/properties'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? data);
    }
    throw ApiException(response.statusCode, 'Failed to load properties');
  }

  // --- Mock Data ---

  DashboardData _mockDashboard() {
    return DashboardData(
      mtdPoints: 245,
      monthlyTarget: 300,
      taskSummary: const TaskSummary(today: 5, overdue: 3, thisWeek: 18, open: 12),
      propHealthSummary: const PropertyHealthSummary(critical: 3, attention: 8, good: 24),
      todayEvents: _mockEvents().where((e) {
        final now = DateTime.now();
        return e.eventDate.year == now.year && e.eventDate.month == now.month && e.eventDate.day == now.day;
      }).toList(),
      overdueEvents: [],
      myTasks: _mockTasks().where((t) => t.status != 'done').toList(),
      overdueTasks: _mockTasks().where((t) => t.isOverdue).toList(),
      propsNeedingAttention: [
        PropertyHealth(score: 35, grade: 'critical', propertyId: 1, propertyAddress: '12 Marine Drive, Amanzimtoti',
            factors: [HealthFactor(label: 'No viewings in 21 days', penalty: 30)]),
        PropertyHealth(score: 52, grade: 'attention', propertyId: 2, propertyAddress: '45 Beach Road, Umkomaas',
            factors: [HealthFactor(label: 'Price stale for 14 days', penalty: 20)]),
        PropertyHealth(score: 78, grade: 'good', propertyId: 3, propertyAddress: '8 Ocean View, Warner Beach',
            factors: [HealthFactor(label: 'Photos need update', penalty: 10)]),
      ],
      candidateDocs: [
        CandidateDoc(documentId: 1, documentName: 'Mandate Agreement', creatorName: 'Sarah Chen', status: 'pending'),
      ],
      scorecard: AgentScorecard(overallScore: 72, tasksCompleted: 18, tasksTotal: 25, propertiesAttended: 12, propertiesTotal: 16),
      totalOverdue: 3,
      overduePopupTasks: [
        CommandTask(id: 100, title: 'Call attorney re: transfer', taskType: 'follow_up', priority: 'high',
            dueDate: DateTime.now().subtract(const Duration(days: 2)), propertyAddress: '12 Marine Drive, Amanzimtoti'),
        CommandTask(id: 101, title: 'Upload FICA documents', taskType: 'document_upload', priority: 'critical',
            dueDate: DateTime.now().subtract(const Duration(days: 5)), propertyAddress: '45 Beach Road, Umkomaas'),
      ],
      overduePopupEvents: [
        CalendarEvent(id: 200, title: 'Property viewing with buyer', eventType: 'deal', priority: 'high',
            eventDate: DateTime.now().subtract(const Duration(days: 1)), colour: '#3b82f6', propertyAddress: '23 Kingsway, Scottburgh'),
      ],
    );
  }

  List<CommandTask> _mockTasks() {
    final now = DateTime.now();
    return [
      CommandTask(id: 1, title: 'Call attorney re: transfer', taskType: 'follow_up', priority: 'high',
          status: 'todo', dueDate: now.add(const Duration(days: 1)), propertyAddress: '12 Marine Drive, Amanzimtoti'),
      CommandTask(id: 2, title: 'Upload FICA documents', taskType: 'document_upload', priority: 'critical',
          status: 'in_progress', dueDate: now.subtract(const Duration(days: 1)), propertyAddress: '45 Beach Road, Umkomaas'),
      CommandTask(id: 3, title: 'Follow up with seller', taskType: 'follow_up', priority: 'normal',
          status: 'todo', dueDate: now.add(const Duration(days: 3))),
      CommandTask(id: 4, title: 'Schedule property photos', taskType: 'custom', priority: 'low',
          status: 'awaiting', dueDate: now.add(const Duration(days: 5)), propertyAddress: '8 Ocean View, Warner Beach'),
      CommandTask(id: 5, title: 'Review offer to purchase', taskType: 'deal_action', priority: 'critical',
          status: 'todo', dueDate: now, propertyAddress: '23 Kingsway, Scottburgh'),
    ];
  }

  List<CalendarEvent> _mockEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      CalendarEvent(id: 1, title: 'Property viewing - Marine Drive', eventType: 'deal',
          eventDate: today.add(const Duration(hours: 10)), colour: '#3b82f6',
          propertyAddress: '12 Marine Drive, Amanzimtoti', propertyId: 1),
      CalendarEvent(id: 2, title: 'Lease signing', eventType: 'lease',
          eventDate: today.add(const Duration(hours: 14)), colour: '#10b981',
          propertyAddress: '45 Beach Road, Umkomaas', propertyId: 2),
      CalendarEvent(id: 3, title: 'Compliance check', eventType: 'compliance',
          eventDate: today.add(const Duration(hours: 16)), colour: '#f59e0b'),
      CalendarEvent(id: 4, title: 'Open house', eventType: 'prospecting',
          eventDate: today.add(const Duration(days: 2, hours: 9)), colour: '#06b6d4',
          propertyAddress: '8 Ocean View, Warner Beach', propertyId: 3),
      CalendarEvent(id: 5, title: 'Meet with bond originator', eventType: 'deal',
          eventDate: today.add(const Duration(days: 3, hours: 11)), colour: '#3b82f6'),
    ];
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
