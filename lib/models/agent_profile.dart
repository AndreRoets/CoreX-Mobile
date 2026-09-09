// The agent's own editable profile — the same `users` row the web app edits
// on My Portal → Profile. Both clients write the same validated fields, so
// there is no client-side merge: re-fetch on mount and pull-to-refresh and
// whatever the other side saved last is what shows.

String? _asNonEmptyString(dynamic v) {
  final s = v?.toString().trim();
  return (s != null && s.isNotEmpty) ? s : null;
}

class AgentProfile {
  final int? id;
  final String name;
  final String email;

  /// Storage-form role slug (`agent`, `admin`, …). Prefer [roleLabel] for UI.
  final String? role;

  /// Server-cased display label for [role] (`Agent`). Null on older backends
  /// that haven't started sending it.
  final String? roleLabel;

  final String? cell;
  final String? whatsappNumber;
  final String? ffcNumber;
  final String? facebookUrl;
  final String? instagramUrl;

  /// The agent's public listing page. Comes from the server so it always
  /// reflects the live slug — never derive it client-side.
  final String? publicProfileUrl;

  /// False when the signed-in user may view but not edit these fields; the
  /// form renders read-only and hides Save.
  final bool canEdit;

  const AgentProfile({
    this.id,
    required this.name,
    required this.email,
    this.role,
    this.roleLabel,
    this.cell,
    this.whatsappNumber,
    this.ffcNumber,
    this.facebookUrl,
    this.instagramUrl,
    this.publicProfileUrl,
    this.canEdit = false,
  });

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return AgentProfile(
      id: id is num ? id.toInt() : int.tryParse(id?.toString() ?? ''),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: _asNonEmptyString(json['role']),
      roleLabel: _asNonEmptyString(json['role_label']),
      cell: _asNonEmptyString(json['cell']),
      whatsappNumber: _asNonEmptyString(json['whatsapp_number']),
      ffcNumber: _asNonEmptyString(json['ffc_number']),
      facebookUrl: _asNonEmptyString(json['website_social_facebook']),
      instagramUrl: _asNonEmptyString(json['website_social_instagram']),
      publicProfileUrl: _asNonEmptyString(json['public_profile_url']),
      canEdit: json['can_edit'] == true,
    );
  }
}
