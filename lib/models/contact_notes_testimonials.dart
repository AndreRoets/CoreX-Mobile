// Models for a Contact's Notes & Testimonials — full parity with the web
// cockpit's "Notes & Testimonials" contact tab. Both write to the same DB
// rows the website shows, so there is no client-side merge logic: just
// re-fetch on pull-to-refresh.

/// Fixed quick-pick list for [ContactNote.type]. A note is otherwise free-form
/// (`type` is optional), but when set it must be one of these.
const List<String> kContactNoteTypes = [
  'Contacted',
  'Viewing booked',
  'Viewing done',
  'Offer discussed',
  'Not interested',
  'Follow up later',
];

int? _asInt(dynamic v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

String? _asNonEmptyString(dynamic v) {
  final s = v?.toString();
  return (s != null && s.isNotEmpty) ? s : null;
}

DateTime _asDate(dynamic v) => DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();

class ContactNote {
  final int id;
  final int contactId;
  final String? type;
  final String? body;
  final int userId;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContactNote({
    required this.id,
    required this.contactId,
    this.type,
    this.body,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactNote.fromJson(Map<String, dynamic> j) => ContactNote(
        id: _asInt(j['id']) ?? 0,
        contactId: _asInt(j['contact_id']) ?? 0,
        type: _asNonEmptyString(j['type']),
        body: _asNonEmptyString(j['body']),
        userId: _asInt(j['user_id']) ?? 0,
        userName: j['user_name']?.toString() ?? '',
        createdAt: _asDate(j['created_at']),
        updatedAt: _asDate(j['updated_at']),
      );
}

class ContactTestimonial {
  final int id;
  final int contactId;
  final String body;
  final String? displayName;
  final int? rating;
  final int? agentId;
  final String? agentName;
  final int userId;
  final String userName;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContactTestimonial({
    required this.id,
    required this.contactId,
    required this.body,
    this.displayName,
    this.rating,
    this.agentId,
    this.agentName,
    required this.userId,
    required this.userName,
    this.published = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactTestimonial.fromJson(Map<String, dynamic> j) => ContactTestimonial(
        id: _asInt(j['id']) ?? 0,
        contactId: _asInt(j['contact_id']) ?? 0,
        body: j['body']?.toString() ?? '',
        displayName: _asNonEmptyString(j['display_name']),
        rating: _asInt(j['rating']),
        agentId: _asInt(j['agent_id']),
        agentName: _asNonEmptyString(j['agent_name']),
        userId: _asInt(j['user_id']) ?? 0,
        userName: j['user_name']?.toString() ?? '',
        // Always false from this API — no publish control exists on mobile —
        // but read whatever the server sends rather than hard-coding it, so a
        // testimonial published from the web still shows its true state here.
        published: j['published'] == true,
        createdAt: _asDate(j['created_at']),
        updatedAt: _asDate(j['updated_at']),
      );
}
