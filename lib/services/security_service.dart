import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns biometric capability checks, the secure-credential vault, and the
/// on-device prefs for "biometric enabled" / "first-login prompt shown".
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _vault = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kEmail = 'sec_email';
  static const _kPassword = 'sec_password';
  static const _kBiometricEnabled = 'sec_biometric_enabled';
  static const _kBiometricPrompted = 'sec_biometric_prompted';

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Sign in to CoreX'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'CoreX sign-in',
            cancelButton: 'Use password',
          ),
          IOSAuthMessages(cancelButton: 'Use password'),
        ],
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await _vault.write(key: _kEmail, value: email);
    await _vault.write(key: _kPassword, value: password);
  }

  Future<({String? email, String? password})> readCredentials() async {
    return (
      email: await _vault.read(key: _kEmail),
      password: await _vault.read(key: _kPassword),
    );
  }

  Future<void> clearCredentials() async {
    await _vault.delete(key: _kEmail);
    await _vault.delete(key: _kPassword);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
  }

  Future<bool> hasPromptedBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricPrompted) ?? false;
  }

  Future<void> markBiometricPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricPrompted, true);
  }
}
