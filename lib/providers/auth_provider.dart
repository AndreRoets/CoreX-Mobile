import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/messaging_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final MessagingService _messaging = MessagingService.instance;

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isChecking = true;
  String? _error;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isChecking => _isChecking;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  String get userName => _user?['name'] ?? 'Agent';

  Future<void> checkAuth() async {
    final token = await _api.getToken();
    if (token != null) {
      try {
        _user = await _api.getProfile();
        _isLoggedIn = true;
        // Re-register the push token on cold start in case it rotated.
        unawaited(_messaging.onLogin());
      } catch (_) {
        await _api.clearToken();
        _isLoggedIn = false;
        _user = null;
      }
    }
    _isChecking = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.login(email, password);
      await _api.saveToken(result['token']);
      _user = result['user'];
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      unawaited(_messaging.onLogin());
      return true;
    } catch (e) {
      _error = 'Invalid email or password';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Revoke the push token while we still have a Sanctum bearer.
    await _messaging.onLogout();
    await _api.clearToken();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }
}

