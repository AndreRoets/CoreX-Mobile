import 'package:flutter/material.dart';

import '../../../services/api_service.dart' show ApiException;
import '../../../services/client_auth_service.dart';
import 'client_otp_screen.dart';
import 'client_password_screen.dart';

// Screen 1 — email entry.
// Hits POST /v1/client-auth/lookup and routes based on the response shape.
class ClientEmailScreen extends StatefulWidget {
  const ClientEmailScreen({super.key});

  @override
  State<ClientEmailScreen> createState() => _ClientEmailScreenState();
}

class _ClientEmailScreenState extends State<ClientEmailScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _api = ClientAuthService();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _api.lookup(email);
      if (!mounted) return;
      if (!result.exists) {
        setState(() {
          _busy = false;
          _error = result.message ??
              'You are not on any agency contact list. Ask your agent to add you.';
        });
        return;
      }
      if (result.requiresOtp) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientOtpScreen(email: email, purpose: OtpPurpose.activation),
          ),
        );
      } else if (result.requiresPassword) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientPasswordScreen(email: email),
          ),
        );
      }
      if (mounted) setState(() => _busy = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 429
            ? 'Too many requests. Please slow down.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not reach the server. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Sign-in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Enter your email',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We will check whether your agent has added you, then take '
                  'you to the right next step.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'Email'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _continue,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
