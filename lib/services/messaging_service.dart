import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Wraps push-token registration with the backend.
///
/// FCM/APNs is **not** wired up in this project yet (no `firebase_core` /
/// `firebase_messaging` dependency, no `google-services.json`). When those
/// are added, replace [_obtainToken] with `FirebaseMessaging.instance.getToken()`
/// and forward `onTokenRefresh` events to [registerCurrentToken]. The rest of
/// the app — bell badge, notifications screen, overdue widget, settings —
/// works against the REST API today and will start receiving live pushes the
/// moment a real token is registered with the server.
class MessagingService {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  static const _kRegisteredTokenKey = 'fcm_registered_token_v1';

  final ApiService _api = ApiService();

  /// Called from `AuthProvider.login` once a session token exists.
  Future<void> onLogin() async {
    final token = await _obtainToken();
    if (token == null) return;
    await _registerWithServer(token);
  }

  /// Called from `AuthProvider.logout` before the auth token is cleared.
  Future<void> onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kRegisteredTokenKey);
    if (token == null) return;
    try {
      await _api.revokeDeviceToken(token);
    } catch (e) {
      debugPrint('[messaging] revoke failed: $e');
    }
    await prefs.remove(_kRegisteredTokenKey);
  }

  /// Hook this to FCM `onTokenRefresh` once the SDK is wired.
  Future<void> registerCurrentToken(String token) async {
    await _registerWithServer(token);
  }

  Future<void> _registerWithServer(String token) async {
    try {
      await _api.registerDeviceToken(
        platform: _platform,
        token: token,
        appVersion: _appVersion,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRegisteredTokenKey, token);
    } catch (e) {
      debugPrint('[messaging] register failed: $e');
    }
  }

  /// Stub — replace with `FirebaseMessaging.instance.getToken()`.
  Future<String?> _obtainToken() async {
    // No FCM SDK present; return null so we skip registration cleanly.
    return null;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  String get _appVersion => '1.0.0';
}
