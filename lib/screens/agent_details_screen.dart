import 'package:flutter/material.dart';
import 'package:tabler_icons/tabler_icons.dart';
import '../models/agent_profile.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/external_launch.dart';
import '../widgets/ui/content_width.dart';

/// The agent's editable public details — the web app's My Portal → Profile
/// tab, backed by `/v1/mobile/profile`. Both clients write the same row, so
/// there is no merge logic: the form is re-fetched on mount and on
/// pull-to-refresh and shows whatever was saved last.
///
/// Lives on its own page (pushed from the Me tab) so the Me tab stays a short
/// glance-and-go screen instead of a form you scroll past to reach Sign out.
class AgentDetailsScreen extends StatefulWidget {
  /// Test seam; production uses a fresh [ApiService].
  final ApiService? api;

  const AgentDetailsScreen({super.key, this.api});

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen> {
  late final ApiService _api = widget.api ?? ApiService();

  AgentProfile? _profile;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;
  Map<String, String> _fieldErrors = const {};

  final _ffc = TextEditingController();
  final _cell = TextEditingController();
  final _whatsapp = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ffc.dispose();
    _cell.dispose();
    _whatsapp.dispose();
    _facebook.dispose();
    _instagram.dispose();
    super.dispose();
  }

  /// Re-fetches and overwrites the form. Deliberately no merge: a pull-to-
  /// refresh means "show me what's saved", which may include an edit made on
  /// the website since the screen opened.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await _api.getAgentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
        _fieldErrors = const {};
        _applyToForm(profile);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // A 401 is already handled: ApiService signals the auth layer, which
      // routes back to login. Anything else is worth a retry affordance.
      setState(() {
        _loading = false;
        _loadError = e.statusCode == 401 ? null : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = "Couldn't load your details. Check your connection.";
      });
    }
  }

  void _applyToForm(AgentProfile p) {
    _ffc.text = p.ffcNumber ?? '';
    _cell.text = p.cell ?? '';
    _whatsapp.text = p.whatsappNumber ?? '';
    _facebook.text = p.facebookUrl ?? '';
    _instagram.text = p.instagramUrl ?? '';
  }

  Future<void> _save() async {
    final cell = _cell.text.trim();
    // Cell is the one required field. Catching it here means a cleared Cell
    // never reaches the server, so the saved value can't be blanked by a
    // request the server would have rejected anyway.
    if (cell.isEmpty) {
      setState(() => _fieldErrors = const {'cell': 'Cell number is required.'});
      return;
    }
    setState(() {
      _saving = true;
      _fieldErrors = const {};
    });
    try {
      final updated = await _api.updateAgentProfile(
        cell: cell,
        whatsappNumber: _whatsapp.text.trim(),
        ffcNumber: _ffc.text.trim(),
        facebookUrl: _facebook.text.trim(),
        instagramUrl: _instagram.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _profile = updated;
        _applyToForm(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _fieldErrors = e.fieldErrors;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e.statusCode == 401) return; // auth layer is routing to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.statusCode == 403
              ? "You don't have permission to edit your profile."
              : e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  void _clearError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors = {..._fieldErrors}..remove(field));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final canEdit = profile?.canEdit ?? false;
    final enabled = canEdit && !_saving && !_loading;
    final previewUrl = profile?.publicProfileUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent details'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ContentSafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Shown on your public agent page and in My Portal on the '
                  'website.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted(context),
                  ),
                ),
                const SizedBox(height: 16),
                if (_loadError != null)
                  _LoadErrorCard(message: _loadError!, onRetry: _load)
                else ...[
                  if (profile != null && !canEdit) ...[
                    const _ReadOnlyNote(),
                    const SizedBox(height: 12),
                  ],
                  _Field(
                    label: 'FFC Number',
                    controller: _ffc,
                    field: 'ffc_number',
                    enabled: enabled,
                    errorText: _fieldErrors['ffc_number'],
                    onChanged: _clearError,
                    keyboard: TextInputType.text,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'Cell',
                    required: true,
                    controller: _cell,
                    field: 'cell',
                    enabled: enabled,
                    errorText: _fieldErrors['cell'],
                    onChanged: _clearError,
                    keyboard: TextInputType.phone,
                    action: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'WhatsApp',
                    controller: _whatsapp,
                    field: 'whatsapp_number',
                    enabled: enabled,
                    errorText: _fieldErrors['whatsapp_number'],
                    onChanged: _clearError,
                    keyboard: TextInputType.phone,
                    action: TextInputAction.next,
                    hint: 'South African mobile number',
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'Facebook Profile URL',
                    controller: _facebook,
                    field: 'website_social_facebook',
                    enabled: enabled,
                    errorText: _fieldErrors['website_social_facebook'],
                    onChanged: _clearError,
                    keyboard: TextInputType.url,
                    action: TextInputAction.next,
                    hint: 'https://facebook.com/your.profile',
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'Instagram Profile URL',
                    controller: _instagram,
                    field: 'website_social_instagram',
                    enabled: enabled,
                    errorText: _fieldErrors['website_social_instagram'],
                    onChanged: _clearError,
                    keyboard: TextInputType.url,
                    action: TextInputAction.done,
                    hint: 'https://instagram.com/your.profile',
                  ),
                  const SizedBox(height: 20),
                  if (canEdit) ...[
                    ElevatedButton.icon(
                      key: const ValueKey('profile-save'),
                      onPressed: enabled ? _save : null,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(TablerIcons.device_floppy, size: 20),
                      label: Text(_saving ? 'Saving…' : 'Save'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    key: const ValueKey('profile-preview'),
                    // The URL is whatever the server sent — never derived
                    // here, so it always matches the live slug the website
                    // uses.
                    onPressed: previewUrl == null
                        ? null
                        : () => launchExternal(context, previewUrl),
                    icon: const Icon(TablerIcons.external_link, size: 20),
                    label: const Text('Preview my agent page'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final String field;
  final bool enabled;
  final String? errorText;
  final String? hint;
  final TextInputType keyboard;
  final TextInputAction action;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    this.required = false,
    required this.controller,
    required this.field,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
    required this.keyboard,
    required this.action,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted(context),
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: ValueKey('profile-field-$field'),
          controller: controller,
          enabled: enabled,
          keyboardType: keyboard,
          textInputAction: action,
          autocorrect: false,
          decoration: InputDecoration(hintText: hint, errorText: errorText),
          onChanged: (_) => onChanged(field),
        ),
      ],
    );
  }
}

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(TablerIcons.lock, size: 16, color: AppTheme.textMuted(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'These details are managed by your agency. You can view but not '
            'edit them here.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
          ),
        ),
      ],
    );
  }
}

class _LoadErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message,
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textPrimary(context))),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(TablerIcons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }
}
