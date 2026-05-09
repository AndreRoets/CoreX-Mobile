import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/client_session_provider.dart';
import '../../../services/api_service.dart' show ApiException;
import '../../../services/client_auth_service.dart';
import 'client_auth_shared.dart';
import 'client_agency_picker_screen.dart';
import 'client_otp_screen.dart';
import 'client_set_password_screen.dart';

// Screen 4 — returning client signs in with email + password.
class ClientPasswordScreen extends StatefulWidget {
  final String email;
  const ClientPasswordScreen({super.key, required this.email});

  @override
  State<ClientPasswordScreen> createState() => _ClientPasswordScreenState();
}

class _ClientPasswordScreenState extends State<ClientPasswordScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _api = ClientAuthService();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final resp = await _api.login(
        email: widget.email,
        password: _passwordController.text,
        deviceName: defaultDeviceName(),
      );

      await _api.saveToken(resp.token);
      if (!mounted) return;

      final session = context.read<ClientSessionProvider>();
      session.applyLogin(resp);

      if (resp.client.passwordMustChange) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ClientSetPasswordScreen(
              bearerToken: resp.token,
              isFromActivation: false,
            ),
          ),
          (r) => false,
        );
        return;
      }

      if (resp.client.lockedToAgencyId == null &&
          resp.client.currentAgencyId == null &&
          resp.agencies.length > 1) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ClientAgencyPickerScreen(initialPick: true),
          ),
          (r) => false,
        );
      } else {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 422
            ? 'Invalid credentials'
            : e.statusCode == 429
                ? 'Too many requests. Please slow down.'
                : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not sign in. Check your connection.';
      });
    }
  }

  Future<void> _forgot() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.forgotPassword(widget.email);
      if (!mounted) return;
      setState(() => _busy = false);
      showAuthToast(context, 'Code sent. Check your email.');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClientOtpScreen(
            email: widget.email,
            purpose: OtpPurpose.recovery,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not start recovery. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text('Welcome back, ${widget.email}',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(hintText: 'Password'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _signIn,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                TextButton(
                  onPressed: _busy ? null : _forgot,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
