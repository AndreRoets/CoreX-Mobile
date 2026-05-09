import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/api_service.dart' show ApiException;
import '../../../services/client_auth_service.dart';
import 'client_set_password_screen.dart';

enum OtpPurpose { activation, recovery }

// Screen 2 — send + verify OTP. Same screen handles activation (first-time
// password set) and recovery (forgot-password flow).
class ClientOtpScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  const ClientOtpScreen({
    super.key,
    required this.email,
    this.purpose = OtpPurpose.activation,
  });

  @override
  State<ClientOtpScreen> createState() => _ClientOtpScreenState();
}

class _ClientOtpScreenState extends State<ClientOtpScreen> {
  final _codeController = TextEditingController();
  final _api = ClientAuthService();

  bool _busy = false;
  bool _sending = true;
  String? _error;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _api.sendOtp(widget.email);
      _startCooldown();
      if (mounted) setState(() => _sending = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.statusCode == 429
            ? 'Please wait before requesting another code.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send the code. Try again.';
      });
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown -= 1;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final activationToken = await _api.verifyOtp(widget.email, code);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientSetPasswordScreen(
            bearerToken: activationToken,
            isFromActivation: true,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 422
            ? 'Invalid or expired code'
            : e.statusCode == 429
                ? 'Too many requests. Please slow down.'
                : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not verify code. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purpose == OtpPurpose.recovery
            ? 'Recover Password'
            : 'Verify Email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'We sent a 6-digit code to ${widget.email}.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '······',
                  counterText: '',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_sending || _resendCooldown > 0) ? null : _send,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend in ${_resendCooldown}s'
                      : 'Resend code',
                ),
              ),
              if (widget.purpose == OtpPurpose.recovery)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'After verifying, you will set a new password.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
