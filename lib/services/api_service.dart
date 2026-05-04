import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/contact.dart';
import '../models/core_match.dart';
import '../models/dashboard_data.dart';
import '../models/gallery_tags.dart';
import '../models/notification_models.dart';
import '../models/property.dart';
import '../models/property_options.dart';
import '../models/property_overview.dart';
import '../models/branding.dart';
import '../models/space.dart';

class ApiService {
  static String get baseUrl => Env.apiBaseUrl;
  static bool get useMockData => Env.useMockData;
  static const Duration _timeout = Duration(seconds: 15);

  static const String _tokenKey = 'auth_token';
  static const String _spacesCatalogKey = 'spaces_catalog_v1';
  static const String _spacesCatalogTsKey = 'spaces_catalog_v1_ts';
  static const Duration _spacesCatalogTtl = Duration(hours: 24);

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
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, 'Login failed');
  }

  // --- Branding ---

  /// Pre-login (public). Fetch agency branding by slug.
  Future<Branding> getBrandingBySlug(String slug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/branding/$slug'),
      headers: {'Accept': 'application/json'},
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final block = (body['branding'] as Map?) ?? body;
      return Branding.fromJson(Map<String, dynamic>.from(block));
    }
    throw ApiException(response.statusCode, 'Failed to load branding');
  }

  /// Post-login. Returns the full logged-user payload (user, agency,
  /// permissions, server_time, branding).
  Future<Map<String, dynamic>> getLoggedUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/v1/logged-user'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, 'Failed to load logged-user');
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
    ).timeout(_timeout);

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
    ).timeout(_timeout);

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

    final response = await http.get(uri, headers: await _headers()).timeout(_timeout);

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
    ).timeout(_timeout);

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
    ).timeout(_timeout);

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
    ).timeout(_timeout);

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
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to resolve task');
    }
  }

  /// Inbox reschedule — extends the task's due date by [days] days. Maps to
  /// the `resolve-task` endpoint with `resolution: extended`.
  Future<void> rescheduleTask(int taskId, int days) async {
    await resolveTask(taskId, resolution: 'extended', extendDays: days);
  }

  /// Inbox reschedule for events — extends the event date by [days] days.
  Future<void> rescheduleEvent(int eventId, int days) async {
    await resolveEvent(eventId, resolution: 'extended', extendDays: days);
  }

  /// Soft-delete (archive) a single task. Used by the Done-column per-card
  /// archive icon and also called by the server observer on status
  /// transition when `auto_archive_done_days = 0` (so after `completeTask`
  /// the task may already be archived — re-fetch rather than assume).
  Future<void> archiveTask(int taskId) async {
    if (useMockData) return;

    final response = await http.delete(
      Uri.parse('$baseUrl/command-center/tasks/$taskId'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Failed to archive task');
    }
  }

  /// Bulk archive — soft-deletes every Done-column task for the current user.
  /// Returns the server's `archived` count.
  Future<int> archiveAllDone() async {
    if (useMockData) return 0;

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/tasks/archive-done'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body is Map && body['archived'] is int ? body['archived'] as int : 0;
    }
    throw ApiException(response.statusCode, 'Failed to clear Done column');
  }

  /// Archived tasks, pre-grouped by `deleted_at` day.
  Future<ArchivedTasksData> getArchivedTasks() async {
    if (useMockData) return ArchivedTasksData();

    final response = await http.get(
      Uri.parse('$baseUrl/command-center/tasks/archived'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return ArchivedTasksData.fromJson(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to load archived tasks');
  }

  /// Restore a soft-deleted task. Returns the restored task (now back in the
  /// Done column).
  Future<CommandTask> restoreTask(int taskId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return CommandTask(id: taskId, title: '');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/command-center/tasks/$taskId/restore'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return CommandTask.fromJson(body is Map<String, dynamic> ? body : (body['task'] ?? {}));
    }
    throw ApiException(response.statusCode, 'Failed to restore task');
  }

  /// Performance payload (full scorecard, activity, property health).
  /// Returned as a raw Map for now — a dedicated model lands in PR 3.
  Future<Map<String, dynamic>> getPerformance() async {
    if (useMockData) return {};

    final response = await http.get(
      Uri.parse('$baseUrl/command-center/performance'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }
    throw ApiException(response.statusCode, 'Failed to load performance');
  }

  /// User settings (reminder panels, task board, calendar prefs, channels).
  /// The response includes `is_agency_controlled` — when true the UI must
  /// disable inputs and show the amber banner.
  Future<Map<String, dynamic>> getUserSettings() async {
    if (useMockData) return {};

    final response = await http.get(
      Uri.parse('$baseUrl/command-center/user-settings'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }
    throw ApiException(response.statusCode, 'Failed to load user settings');
  }

  /// PUT user settings. `auto_archive_done_days` accepts null (never), 0
  /// (immediate, via server observer), or 1..365. Empty-string submissions
  /// are coerced to null server-side.
  Future<Map<String, dynamic>> updateUserSettings(Map<String, dynamic> payload) async {
    if (useMockData) return payload;

    final response = await http.put(
      Uri.parse('$baseUrl/command-center/user-settings'),
      headers: await _headers(),
      body: jsonEncode(payload),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    }
    if (response.statusCode == 403) {
      throw ApiException(403, 'Agency-controlled — only agency admins can change these');
    }
    throw ApiException(response.statusCode, 'Failed to update user settings');
  }

  // --- Calendar Events ---

  Future<List<CalendarEvent>> getCalendarEvents({String? month}) async {
    if (useMockData) return _mockEvents();

    final uri = Uri.parse('$baseUrl/command-center/calendar/events')
        .replace(queryParameters: month != null ? {'month': month} : null);

    final response = await http.get(uri, headers: await _headers()).timeout(_timeout);

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
    ).timeout(_timeout);

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
    ).timeout(_timeout);

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
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to resolve event');
    }
  }

  // --- Properties ---

  /// Session-scoped in-memory cache for the property options dropdown data.
  /// Static so every [ApiService] instance shares it; cleared on app
  /// restart because it's never persisted to disk (per the spec — admins
  /// edit these on the web and stale cached entries would be confusing).
  static PropertyOptions? _cachedPropertyOptions;

  Future<PropertyOptions> getPropertyOptions({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPropertyOptions != null) {
      return _cachedPropertyOptions!;
    }
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/properties/options'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final options =
          PropertyOptions.fromJson(Map<String, dynamic>.from(data));
      _cachedPropertyOptions = options;
      return options;
    }
    throw ApiException(response.statusCode, 'Failed to load property options');
  }

  Future<List<Property>> getProperties() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/properties'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['properties'] as List? ?? [];
      return list.map((e) => Property.fromJson(e)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to load properties');
  }

  Future<Property> getProperty(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/properties/$id'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Property.fromJson(data['property']);
    }
    throw ApiException(response.statusCode, 'Failed to load property');
  }

  Future<Property> createProperty(Map<String, dynamic> data) async {
    final reqBody = jsonEncode(data);
    debugPrint('[createProperty] POST $baseUrl/mobile/properties');
    debugPrint('[createProperty] body: $reqBody');
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/properties'),
      headers: await _headers(),
      body: reqBody,
    ).timeout(_timeout);

    debugPrint('[createProperty] ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return Property.fromJson(body['property'] ?? body);
    }
    if (response.statusCode == 422) {
      throw _parseValidationError(response.body);
    }
    throw ApiException(
        response.statusCode, _serverErrorMessage(response.body, 'create'));
  }

  Future<Property> updateProperty(int id, Map<String, dynamic> data) async {
    final reqBody = jsonEncode(data);
    debugPrint('[updateProperty] PUT $baseUrl/mobile/properties/$id');
    debugPrint('[updateProperty] body: $reqBody');
    final response = await http.put(
      Uri.parse('$baseUrl/mobile/properties/$id'),
      headers: await _headers(),
      body: reqBody,
    ).timeout(_timeout);

    debugPrint('[updateProperty] ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Property.fromJson(body['property'] ?? body);
    }
    if (response.statusCode == 422) {
      throw _parseValidationError(response.body);
    }
    throw ApiException(
        response.statusCode, _serverErrorMessage(response.body, 'update'));
  }

  /// Best-effort extraction of a useful error message from a non-success
  /// response body. Tries Laravel's `message`/`exception` shape first,
  /// falls back to a truncated raw body so the user (and console log) can
  /// actually see what the server complained about instead of just
  /// "Failed to create property".
  String _serverErrorMessage(String body, String verb) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final msg = json['message']?.toString();
        final exc = json['exception']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return exc != null ? '$msg ($exc)' : msg;
        }
      }
    } catch (_) {}
    if (body.isEmpty) return 'Failed to $verb property (empty response)';
    return body.length > 400
        ? '${body.substring(0, 400)}…'
        : body;
  }

  /// Parses a Laravel-style 422 body into a [ValidationException] with one
  /// message per field (the first message in each `errors[field]` list).
  ValidationException _parseValidationError(String body) {
    String topMessage = 'Validation failed';
    final fieldErrors = <String, String>{};
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        if (json['message'] is String) topMessage = json['message'] as String;
        final errors = json['errors'];
        if (errors is Map) {
          errors.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              fieldErrors[k.toString()] = v.first.toString();
            } else if (v is String) {
              fieldErrors[k.toString()] = v;
            }
          });
        }
      }
    } catch (_) {}
    return ValidationException(topMessage, fieldErrors);
  }

  // --- Spaces & Features ---

  Future<SpacesCatalog> getSpacesCatalog({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = prefs.getString(_spacesCatalogKey);
      final ts = prefs.getInt(_spacesCatalogTsKey);
      if (cached != null && ts != null) {
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age < _spacesCatalogTtl.inMilliseconds) {
          try {
            return SpacesCatalog.fromJson(
                Map<String, dynamic>.from(jsonDecode(cached)));
          } catch (_) {
            // fall through to network
          }
        }
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mobile/properties/spaces/catalog'),
        headers: await _headers(),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final map = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};
        await prefs.setString(_spacesCatalogKey, jsonEncode(map));
        await prefs.setInt(
            _spacesCatalogTsKey, DateTime.now().millisecondsSinceEpoch);
        return SpacesCatalog.fromJson(map);
      }
      throw ApiException(response.statusCode, 'Failed to load spaces catalog');
    } on SocketException {
      // offline — fall back to stale cache if we have one
      final cached = prefs.getString(_spacesCatalogKey);
      if (cached != null) {
        return SpacesCatalog.fromJson(
            Map<String, dynamic>.from(jsonDecode(cached)));
      }
      rethrow;
    }
  }

  Future<PropertySpacesData> getPropertySpaces(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/properties/$id/spaces'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PropertySpacesData.fromJson(Map<String, dynamic>.from(data));
    }
    throw ApiException(response.statusCode, 'Failed to load property spaces');
  }

  Future<PropertySpacesData> updatePropertySpaces(
      int id, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('$baseUrl/mobile/properties/$id/spaces'),
      headers: await _headers(),
      body: jsonEncode(payload),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PropertySpacesData.fromJson(Map<String, dynamic>.from(data));
    }

    if (response.statusCode == 403) {
      throw ApiException(
          403, "You don't have permission to edit this property");
    }

    if (response.statusCode == 422) {
      String msg = 'Validation failed';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['errors'] is Map) {
          final errors = body['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first.toString();
            final firstVal = errors[firstKey];
            final firstMsg = (firstVal is List && firstVal.isNotEmpty)
                ? firstVal.first.toString()
                : firstVal.toString();
            msg = '$firstKey: $firstMsg';
          }
        } else if (body is Map && body['message'] is String) {
          msg = body['message'] as String;
        }
      } catch (_) {}
      throw ApiException(422, msg);
    }

    throw ApiException(response.statusCode, 'Failed to save spaces');
  }

  // --- Property Overview ---

  /// 60-second in-memory cache of the overview payload, keyed by property id.
  /// Expires the moment the TTL is exceeded; pull-to-refresh callers should
  /// pass [forceRefresh] to bypass it.
  static final Map<int, ({DateTime fetchedAt, PropertyOverview data})>
      _overviewCache = {};
  static const Duration _overviewTtl = Duration(seconds: 60);

  Future<PropertyOverview> getPropertyOverview(int id,
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _overviewCache[id];
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < _overviewTtl) {
        return cached.data;
      }
    }

    final response = await http.get(
      Uri.parse('$baseUrl/mobile/properties/$id/overview'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final map = raw is Map<String, dynamic>
          ? (raw['property'] is Map<String, dynamic>
              ? raw['property'] as Map<String, dynamic>
              : raw)
          : <String, dynamic>{};
      // The backend returns the full property record at the top level with a
      // sibling `placements` array; if `placements` lives outside `property`
      // when wrapped, fold it in so the model sees a flat shape.
      if (raw is Map<String, dynamic> &&
          raw['placements'] != null &&
          map['placements'] == null) {
        map['placements'] = raw['placements'];
      }
      final overview = PropertyOverview.fromJson(map);
      _overviewCache[id] =
          (fetchedAt: DateTime.now(), data: overview);
      return overview;
    }
    if (response.statusCode == 403) {
      throw ApiException(403, "You don't have access to this property");
    }
    throw ApiException(response.statusCode, 'Failed to load overview');
  }

  void invalidateOverviewCache(int id) => _overviewCache.remove(id);

  // --- Gallery Tags (custom tag CRUD) ---

  Future<GalleryTagsData> addGalleryTag(int propertyId, String tag) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/properties/$propertyId/gallery/tags'),
      headers: await _headers(),
      body: jsonEncode({'tag': tag}),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return GalleryTagsData.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    }
    if (response.statusCode == 422) {
      String msg = 'Tag is invalid';
      try {
        final body = jsonDecode(response.body);
        if (body is Map) {
          if (body['message'] is String) {
            msg = body['message'] as String;
          } else if (body['errors'] is Map) {
            final errors = body['errors'] as Map;
            if (errors['tag'] is List && (errors['tag'] as List).isNotEmpty) {
              msg = (errors['tag'] as List).first.toString();
            }
          }
        }
      } catch (_) {}
      throw ApiException(422, msg);
    }
    if (response.statusCode == 403) {
      throw ApiException(403, "You don't have permission to edit tags");
    }
    throw ApiException(response.statusCode, 'Failed to add tag');
  }

  Future<GalleryTagsData> deleteGalleryTag(int propertyId, String tag) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/mobile/properties/$propertyId/gallery/tags'),
      headers: await _headers(),
      body: jsonEncode({'tag': tag}),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return GalleryTagsData.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    }
    if (response.statusCode == 403) {
      throw ApiException(403, "You don't have permission to edit tags");
    }
    throw ApiException(response.statusCode, 'Failed to remove tag');
  }

  Future<GalleryTagsData> getGalleryTags(int propertyId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/properties/$propertyId/gallery/tags'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GalleryTagsData.fromJson(Map<String, dynamic>.from(data));
    }
    if (response.statusCode == 403) {
      throw ApiException(
          403, "You don't have permission to view this property");
    }
    throw ApiException(response.statusCode, 'Failed to load gallery tags');
  }

  /// Uploads a single image. Pass [roomTag] `null` to upload untagged.
  ///
  /// Throws [TagValidationException] on a 422 response whose body contains
  /// `available_tags`, so the caller can refresh its local tag list.
  Future<UploadedImage> uploadPropertyImage(
      int propertyId, File image, String? roomTag) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/mobile/properties/$propertyId/images'),
    );
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    if (roomTag != null) request.fields['room_tag'] = roomTag;

    final streamed = await request.send().timeout(_timeout);
    final body = await streamed.stream.bytesToString();
    final status = streamed.statusCode;

    if (status == 200 || status == 201) {
      try {
        final json = jsonDecode(body);
        if (json is Map) {
          return UploadedImage(
            url: json['url']?.toString() ?? '',
            roomTag: json['room_tag']?.toString(),
          );
        }
      } catch (_) {}
      return const UploadedImage(url: '');
    }

    if (status == 422) {
      List<String> available = const [];
      String message = "Tag is not available on this property";
      try {
        final json = jsonDecode(body);
        if (json is Map) {
          if (json['available_tags'] is List) {
            available = (json['available_tags'] as List)
                .map((e) => e.toString())
                .toList();
          }
          if (json['message'] is String) {
            message = json['message'] as String;
          } else if (json['errors'] is Map) {
            final errors = json['errors'] as Map;
            if (errors['room_tag'] is List &&
                (errors['room_tag'] as List).isNotEmpty) {
              message = (errors['room_tag'] as List).first.toString();
            }
          }
        }
      } catch (_) {}
      throw TagValidationException(message, available);
    }

    if (status == 403) {
      throw ApiException(
          403, "You don't have permission to upload to this property");
    }

    throw ApiException(status, 'Failed to upload image');
  }

  // --- Contacts ---

  Future<List<Contact>> listContacts({String? search, int perPage = 50}) async {
    final qp = <String, String>{
      'per_page': '$perPage',
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$baseUrl/mobile/contacts').replace(queryParameters: qp);
    final response = await http.get(uri, headers: await _headers()).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final list = body is List
          ? body
          : (body['data'] ?? body['contacts'] ?? []);
      return (list as List)
          .whereType<Map>()
          .map((e) => Contact.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw ApiException(response.statusCode, 'Failed to load contacts');
  }

  Future<Contact> getContact(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/contacts/$id'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final map = body is Map && body['contact'] is Map
          ? Map<String, dynamic>.from(body['contact'])
          : Map<String, dynamic>.from(body as Map);
      return Contact.fromJson(map);
    }
    throw ApiException(response.statusCode, 'Failed to load contact');
  }

  Future<List<ContactType>> getContactOptions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/contacts/options'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final list = body is Map ? (body['contact_types'] as List? ?? []) : [];
      return list
          .whereType<Map>()
          .map((e) => ContactType.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw ApiException(response.statusCode, 'Failed to load contact options');
  }

  Future<Contact> createContact(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/contacts'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      final map = json is Map && json['contact'] is Map
          ? Map<String, dynamic>.from(json['contact'])
          : Map<String, dynamic>.from(json as Map);
      return Contact.fromJson(map);
    }
    if (response.statusCode == 422) {
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['duplicate_id'] != null) {
          final dup = json['duplicate_id'];
          final dupId = dup is num ? dup.toInt() : int.tryParse(dup.toString()) ?? 0;
          throw DuplicateContactException(dupId, json['message']?.toString() ?? 'This contact already exists');
        }
      } catch (e) {
        if (e is DuplicateContactException) rethrow;
      }
      throw _parseValidationError(response.body);
    }
    throw ApiException(response.statusCode, _serverErrorMessage(response.body, 'create'));
  }

  Future<Contact> updateContact(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/mobile/contacts/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final map = json is Map && json['contact'] is Map
          ? Map<String, dynamic>.from(json['contact'])
          : Map<String, dynamic>.from(json as Map);
      return Contact.fromJson(map);
    }
    if (response.statusCode == 422) throw _parseValidationError(response.body);
    throw ApiException(response.statusCode, _serverErrorMessage(response.body, 'update'));
  }

  Future<Map<String, dynamic>> whatsappContact(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/contacts/$id/whatsapp'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? body : <String, dynamic>{};
    }
    throw ApiException(response.statusCode, 'Failed to log WhatsApp');
  }

  Future<ContactMatch> createMatch(int contactId, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/contacts/$contactId/matches'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      final map = json is Map && json['match'] is Map
          ? Map<String, dynamic>.from(json['match'])
          : Map<String, dynamic>.from(json as Map);
      return ContactMatch.fromJson(map);
    }
    if (response.statusCode == 422) throw _parseValidationError(response.body);
    throw ApiException(response.statusCode, _serverErrorMessage(response.body, 'create match'));
  }

  Future<Property> createPropertyForContact(
      int contactId, String role, Map<String, dynamic> propertyBody) async {
    final merged = {
      ...propertyBody,
      'link_contact_id': contactId,
      'link_contact_role': role,
    };
    return createProperty(merged);
  }

  // --- Core Matches ---

  Future<List<CoreMatchGroup>> listCoreMatches() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/core-matches'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final list = body is Map ? (body['groups'] as List? ?? const []) : const [];
      return list
          .whereType<Map>()
          .map((e) => CoreMatchGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw ApiException(response.statusCode, 'Failed to load core matches');
  }

  Future<CoreMatchDetail> getCoreMatch(int id,
      {bool showOtherAgents = false}) async {
    final uri = Uri.parse('$baseUrl/mobile/core-matches/$id').replace(
      queryParameters: showOtherAgents ? {'show_other_agents': '1'} : null,
    );
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);

    if (response.statusCode == 200) {
      return CoreMatchDetail.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    }
    throw ApiException(response.statusCode, 'Failed to load core match');
  }

  Future<bool> getCoreMatchAllowCrossAgent() async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/core-matches/settings'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body is Map && body['allow_cross_agent'] == true;
    }
    throw ApiException(response.statusCode, 'Failed to load core match settings');
  }

  Future<CoreMatch> updateCoreMatch(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/mobile/core-matches/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final map = json is Map && json['match'] is Map
          ? Map<String, dynamic>.from(json['match'])
          : Map<String, dynamic>.from(json as Map);
      return CoreMatch.fromJson(map);
    }
    if (response.statusCode == 422) throw _parseValidationError(response.body);
    throw ApiException(response.statusCode, _serverErrorMessage(response.body, 'update match'));
  }

  Future<void> setCoreMatchStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/mobile/core-matches/$id/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to update status');
    }
  }

  Future<bool> toggleHideMatchProperty(int matchId, int propertyId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/core-matches/$matchId/hide/$propertyId'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map && body['hidden'] is bool) return body['hidden'] as bool;
      return false;
    }
    throw ApiException(response.statusCode, 'Failed to toggle visibility');
  }

  Future<WhatsAppShare> previewMatchWhatsApp(int matchId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mobile/core-matches/$matchId/share-whatsapp'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return WhatsAppShare.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    }
    throw ApiException(response.statusCode, 'Failed to load WhatsApp preview');
  }

  Future<WhatsAppShare> sendMatchWhatsApp(int matchId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/core-matches/$matchId/share-whatsapp'),
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return WhatsAppShare.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    }
    throw ApiException(response.statusCode, 'Failed to send WhatsApp');
  }

  Future<void> deleteCoreMatch(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/mobile/core-matches/$id'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Failed to delete match');
    }
  }

  // --- Notifications ---

  /// Register an FCM/APNs token with the backend so the user receives push.
  Future<void> registerDeviceToken({
    required String platform,
    required String token,
    String? appVersion,
  }) async {
    if (useMockData) return;
    final response = await http.post(
      Uri.parse('$baseUrl/device-tokens'),
      headers: await _headers(),
      body: jsonEncode({
        'platform': platform,
        'token': token,
        if (appVersion != null) 'app_version': appVersion,
      }),
    ).timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, 'Failed to register device token');
    }
  }

  Future<void> revokeDeviceToken(String token) async {
    if (useMockData) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/device-tokens/${Uri.encodeComponent(token)}'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Failed to revoke device token');
    }
  }

  Future<({List<NotificationItem> items, int unread})> getNotifications({
    bool unreadOnly = false,
    int limit = 20,
    int? beforeId,
  }) async {
    if (useMockData) return (items: <NotificationItem>[], unread: 0);

    final qp = <String, String>{
      if (unreadOnly) 'unread': '1',
      'limit': '$limit',
      if (beforeId != null) 'before_id': '$beforeId',
    };
    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: qp);
    final response = await http.get(uri, headers: await _headers()).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (body['items'] as List? ?? [])
          .whereType<Map>()
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final unread = body['unread'] is num ? (body['unread'] as num).toInt() : 0;
      return (items: list, unread: unread);
    }
    throw ApiException(response.statusCode, 'Failed to load notifications');
  }

  Future<void> markNotificationRead(int id) async {
    if (useMockData) return;
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$id/read'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to mark read');
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (useMockData) return;
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/mark-all-read'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to mark all read');
    }
  }

  Future<OverdueSnapshot> getOverdueSnapshot() async {
    if (useMockData) return OverdueSnapshot.empty();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/overdue'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return OverdueSnapshot.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    }
    throw ApiException(response.statusCode, 'Failed to load overdue snapshot');
  }

  Future<NotificationPreferencesData> getNotificationPreferences() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notification-preferences'),
      headers: await _headers(),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return NotificationPreferencesData.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body)));
    }
    throw ApiException(response.statusCode, 'Failed to load notification preferences');
  }

  /// Returns saved count on success. Throws [AgencyControlledException] when
  /// the server returns 409 with `{ error: "agency_controlled" }`.
  Future<int> updateNotificationPreferences({
    MasterChannels? master,
    required List<NotificationPreference> preferences,
  }) async {
    final payload = {
      if (master != null) 'master': master.toJson(),
      'preferences': preferences.map((p) => p.toJson()).toList(),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/notification-preferences'),
      headers: await _headers(),
      body: jsonEncode(payload),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map && body['saved'] is num) {
        return (body['saved'] as num).toInt();
      }
      return preferences.length;
    }
    if (response.statusCode == 409) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] == 'agency_controlled') {
          throw AgencyControlledException();
        }
      } catch (e) {
        if (e is AgencyControlledException) rethrow;
      }
      throw AgencyControlledException();
    }
    throw ApiException(response.statusCode, 'Failed to save preferences');
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
      inboxOverdueTasks: [
        CommandTask(id: 100, title: 'Call attorney re: transfer', taskType: 'follow_up', priority: 'high',
            dueDate: DateTime.now().subtract(const Duration(days: 2)),
            propertyId: 1, propertyAddress: '12 Marine Drive, Amanzimtoti', pillarTag: 'property'),
        CommandTask(id: 101, title: 'Upload FICA documents', taskType: 'document_upload', priority: 'critical',
            dueDate: DateTime.now().subtract(const Duration(days: 5)),
            propertyId: 2, propertyAddress: '45 Beach Road, Umkomaas', pillarTag: 'property'),
      ],
      inboxOverdueEvents: [
        CalendarEvent(id: 200, title: 'Property viewing with buyer', eventType: 'deal', priority: 'high',
            eventDate: DateTime.now().subtract(const Duration(days: 1)), colour: '#3b82f6',
            propertyId: 4, propertyAddress: '23 Kingsway, Scottburgh', pillarTag: 'property'),
      ],
      inboxCandidateDocs: [
        CandidateDoc(id: 10, documentId: 1, documentName: 'Mandate Agreement', creatorName: 'Sarah Chen', status: 'pending'),
      ],
      inboxTotal: 4,
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

/// Thrown by [ApiService.uploadPropertyImage] when the server rejects a
/// [roomTag] because it isn't on the property's live tag list. The caller
/// should use [availableTags] to refresh its local picker and re-prompt.
class TagValidationException extends ApiException {
  final List<String> availableTags;
  TagValidationException(String message, this.availableTags)
      : super(422, message);
}

/// Thrown by create / update endpoints when the server returns a Laravel-
/// shaped 422 validation error. [fieldErrors] maps field name → first error
/// message, ready to surface inline in the form.
class ValidationException extends ApiException {
  final Map<String, String> fieldErrors;
  ValidationException(String message, this.fieldErrors) : super(422, message);
}

/// Server returned 409 + `{ error: "agency_controlled" }` from the
/// notification-preferences PUT — agency admin owns these settings, the UI
/// must freeze the form and surface the banner.
class AgencyControlledException extends ApiException {
  AgencyControlledException()
      : super(409, 'Your agency manages notification settings centrally.');
}

/// Server returned 422 with `duplicate_id` from POST /mobile/contacts —
/// caller should offer to open the existing contact instead of erroring.
class DuplicateContactException extends ApiException {
  final int duplicateId;
  DuplicateContactException(this.duplicateId, String message) : super(422, message);
}
