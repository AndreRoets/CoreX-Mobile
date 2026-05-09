import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/client_session_provider.dart';
import '../../services/api_service.dart' show ApiException;
import '../../services/client_auth_service.dart';
import '../auth/client/client_agency_picker_screen.dart';

class ClientSettingsScreen extends StatelessWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClientSessionProvider>();
    final canSwitch = session.agencies.length > 1 &&
        session.client?.lockedToAgencyId == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (session.contact != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(session.contact!.fullName),
              subtitle:
                  Text(session.client?.email ?? session.contact!.email ?? ''),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const _ChangePasswordDialog(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch agency'),
            enabled: canSwitch,
            trailing: const Icon(Icons.chevron_right),
            onTap: canSwitch
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClientAgencyPickerScreen(
                            initialPick: false),
                      ),
                    )
                : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Sign out',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await context.read<ClientSessionProvider>().signOut();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _api = ClientAuthService();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.changePassword(
        currentPassword: _current.text,
        password: _password.text,
        passwordConfirmation: _confirm.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
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
        _error = 'Could not change password. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Current password'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (v) =>
                  (v == null || v.length < 8) ? 'At least 8 characters' : null,
            ),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm new password'),
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
