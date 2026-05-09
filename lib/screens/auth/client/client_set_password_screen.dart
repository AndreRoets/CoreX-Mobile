import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/client_session_provider.dart';
import '../../../services/api_service.dart' show ApiException;
import '../../../services/client_auth_service.dart';
import 'client_auth_shared.dart';
import 'client_agency_picker_screen.dart';

// Screen 3 — set / rotate password.
//
// Two entry paths:
//   1. After OTP verify: [bearerToken] is the short-lived activation token
//      and [isFromActivation] is true. We do not have a session yet.
//   2. Forced rotation: [bearerToken] is the long-lived session token.
//      [isFromActivation] is false; the session is already in the provider.
class ClientSetPasswordScreen extends StatefulWidget {
  final String bearerToken;
  final bool isFromActivation;

  const ClientSetPasswordScreen({
    super.key,
    required this.bearerToken,
    required this.isFromActivation,
  });

  @override
  State<ClientSetPasswordScreen> createState() =>
      _ClientSetPasswordScreenState();
}

class _ClientSetPasswordScreenState extends State<ClientSetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _api = ClientAuthService();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final resp = await _api.setPassword(
        bearer: widget.bearerToken,
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
        deviceName: defaultDeviceName(),
      );

      // Persist long-lived session token + apply to provider.
      await _api.saveToken(resp.token);
      if (!mounted) return;

      final session = context.read<ClientSessionProvider>();
      session.applyLogin(resp);
      session.clearPasswordMustChange();

      if (resp.agencies.length > 1 &&
          resp.client.lockedToAgencyId == null &&
          resp.client.currentAgencyId == null) {
        // Multi-agency client → agency picker. AuthGate will land them on
        // home once an agency is chosen.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ClientAgencyPickerScreen(initialPick: true),
          ),
          (r) => false,
        );
      } else {
        // AuthGate will swap to ClientHomeScreen on next rebuild.
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 422
            ? e.message
            : e.statusCode == 401
                ? 'Activation expired. Please request a new code.'
                : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save password. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFromActivation
            ? 'Create Password'
            : 'Update Password'),
        automaticallyImplyLeading: widget.isFromActivation,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  widget.isFromActivation
                      ? 'Choose a password you will use to sign in next time.'
                      : 'Your agent set a temporary password. Pick a new one to continue.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(hintText: 'New password'),
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'At least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(hintText: 'Confirm password'),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Password & Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
