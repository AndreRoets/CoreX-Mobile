import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/client_models.dart';
import '../../../providers/client_session_provider.dart';
import '../../../services/api_service.dart' show ApiException;
import '../../../services/client_auth_service.dart';
import 'client_auth_shared.dart';

class ClientAgentQrSignupScreen extends StatefulWidget {
  final String slug;
  const ClientAgentQrSignupScreen({super.key, required this.slug});

  @override
  State<ClientAgentQrSignupScreen> createState() =>
      _ClientAgentQrSignupScreenState();
}

class _ClientAgentQrSignupScreenState extends State<ClientAgentQrSignupScreen> {
  final _api = ClientAuthService();
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  AgentQrAgent? _agent;
  bool _loadingAgent = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAgent();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _loadAgent() async {
    try {
      final agent = await _api.agentQrPreview(widget.slug);
      if (!mounted) return;
      setState(() {
        _agent = agent;
        _loadingAgent = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      showAuthToast(
        context,
        e.statusCode == 404 ? 'Agent QR not found' : e.message,
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      showAuthToast(context, 'Could not reach the server.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final resp = await _api.agentQrRegister(
        slug: widget.slug,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirm.text,
        deviceName: defaultDeviceName(),
      );

      await _api.saveToken(resp.token);
      if (!mounted) return;

      final session = context.read<ClientSessionProvider>();
      await session.refreshMe();

      if (!mounted) return;
      if (resp.existing) {
        showAuthToast(
          context,
          'Welcome back — also linked to ${resp.agent.fullName}.',
        );
      }
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 429
            ? 'Too many sign-ups from this device, try again later'
            : e.statusCode == 422
                ? e.message
                : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not sign up. Check your connection.';
      });
    }
  }

  Widget _header() {
    if (_loadingAgent || _agent == null) {
      return Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 180,
                  color: Colors.grey.withOpacity(0.2),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  color: Colors.grey.withOpacity(0.15),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final a = _agent!;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: a.photoUrl != null && a.photoUrl!.isNotEmpty
              ? NetworkImage(a.photoUrl!)
              : null,
          child: a.photoUrl == null || a.photoUrl!.isEmpty
              ? Text(a.firstName.isNotEmpty ? a.firstName[0] : '?')
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: "You're signing up with ",
                  style: const TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text: a.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (a.agency != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    a.agency!.name,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up with agent')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.givenName],
                  decoration: const InputDecoration(labelText: 'First name *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your first name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  decoration: const InputDecoration(labelText: 'Surname *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your surname'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(labelText: 'Cell phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email *'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(labelText: 'Password *'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password *'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _password.text) return 'Passwords do not match';
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
                  onPressed: (_busy || _loadingAgent) ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
