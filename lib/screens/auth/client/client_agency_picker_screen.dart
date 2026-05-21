import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/branding.dart';
import '../../../models/client_models.dart';
import '../../../providers/client_session_provider.dart';
import '../../../services/api_service.dart' show ApiException;
import '../../../services/client_auth_service.dart';
import '../../../theme.dart';
import '../../../widgets/ui/auth_scaffold.dart';
import '../../../widgets/ui/glow_button.dart';
import '../../../widgets/ui/icon_badge.dart';

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
      child: AuthScaffold(
        title: 'Choose agency',
        subtitle:
            'Your email is on more than one agency contact list. Pick the one you want to view.',
        showBack: !widget.initialPick,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in agencies)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AgencyRow(
                  agency: a,
                  selected: _selectedId == a.id,
                  onTap: () => setState(() => _selectedId = a.id),
                ),
              ),
            const SizedBox(height: 4),
            _LockToggle(
              value: _lock,
              onChanged: (v) => setState(() => _lock = v),
            ),
            if (_error != null) AuthError(_error!),
            const SizedBox(height: 20),
            GlowButton(
              onPressed: _busy || _selectedId == null ? null : _confirm,
              loading: _busy,
              child: const Text('Continue'),
            ),
          ],
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
    final brand = BrandColors.of(context);
    final accent = brand.button;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? null : AppTheme.cardGradient(context),
            color: selected ? accent.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.6) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Row(
            children: [
              IconBadge(
                icon: Icons.apartment_rounded,
                size: 40,
                iconSize: 20,
                tint: accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agency.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    if (agency.isLocked || agency.isPreferred) ...[
                      const SizedBox(height: 2),
                      Text(
                        agency.isLocked
                            ? 'Currently locked'
                            : 'Preferred',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? accent : AppTheme.textMuted(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _LockToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: value ? brand.button : AppTheme.textMuted(context),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Only use this agency',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Text(
                      'Skips this picker on future sign-ins.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
