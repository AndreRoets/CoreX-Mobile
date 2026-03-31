import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://91.99.130.85:8084/api';
  static const bool useMockData = false;

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

  // --- Properties ---

  Future<List<Map<String, dynamic>>> getProperties() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      return [
        {
          'id': 1,
          'address': '12 Marine Drive, Amanzimtoti',
          'price': 1250000,
          'status': 'Active',
        },
        {
          'id': 2,
          'address': '45 Beach Road, Umkomaas',
          'price': 2100000,
          'status': 'Pending',
        },
        {
          'id': 3,
          'address': '8 Ocean View Crescent, Warner Beach',
          'price': 875000,
          'status': 'Sold',
        },
        {
          'id': 4,
          'address': '23 Kingsway, Scottburgh',
          'price': 1650000,
          'status': 'Active',
        },
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
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
