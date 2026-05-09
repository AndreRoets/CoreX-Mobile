import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/client_models.dart';
import '../../../providers/client_session_provider.dart';
import '../../../services/api_service.dart' show ApiException;
import '../../../services/client_auth_service.dart';

// Screen 5 — agency picker.
//
// [initialPick] true means this is the first time the client lands here
// (post-login on a multi-agency account). We block back-navigation in that
// mode — they must pick before they can use the app. When opened later (gear
// → Switch Agency, or the home top-bar tap), the back button is allowed.
class ClientAgencyPickerScreen extends StatefulWidget {
  final bool initialPick;
  const ClientAgencyPickerScreen({super.key, this.initialPick = false});

  @override
  State<ClientAgencyPickerScreen> createState() =>
      _ClientAgencyPickerScreenState();
}

class _ClientAgencyPickerScreenState extends State<ClientAgencyPickerScreen> {
  final _api = ClientAuthService();

  int? _selectedId;
  bool _lock = false;
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ClientSessionProvider>();
    final agencies = session.agencies;
    _selectedId ??= session.currentAgency?.id;

    return PopScope(
      canPop: !widget.initialPick,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Choose Agency'),
          automaticallyImplyLeading: !widget.initialPick,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  child: Text(
                    'Your email is on more than one agency contact list. '
                    'Pick the one you want to view.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: agencies.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _AgencyRow(
                          agency: agencies[i],
                          selected: _selectedId == agencies[i].id,
                          onTap: () =>
                              setState(() => _selectedId = agencies[i].id),
                        ),
                  ),
                ),
                CheckboxListTile(
                  value: _lock,
                  onChanged: (v) => setState(() => _lock = v ?? false),
                  title: const Text('Only use this agency'),
                  subtitle: const Text(
                      'Skips this picker on future sign-ins.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy || _selectedId == null ? null : _confirm,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_selectedId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _api.selectAgency(
        agencyId: _selectedId!,
        lock: _lock,
        favourite: false,
      );
      if (!mounted) return;
      context.read<ClientSessionProvider>().applyAgencySelection(
            client: result.client,
            agencies: result.agencies,
          );
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.statusCode == 401
            ? 'Session expired. Please sign in again.'
            : e.message;
      });
      if (e.statusCode == 401) {
        await context.read<ClientSessionProvider>().signOutLocal();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not switch agency. Try again.';
      });
    }
  }
}

class _AgencyRow extends StatelessWidget {
  final ClientAgency agency;
  final bool selected;
  final VoidCallback onTap;

  const _AgencyRow({
    required this.agency,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(agency.name),
      subtitle: agency.isLocked
          ? const Text('Currently locked')
          : (agency.isPreferred ? const Text('Preferred') : null),
      trailing: agency.isPreferred
          ? const Icon(Icons.star, size: 18)
          : const Icon(Icons.star_border, size: 18),
    );
  }
}
