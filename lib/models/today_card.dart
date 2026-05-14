/// Response payload for `GET /api/command-center/today` (and the matching
/// `POST /today/refresh`). The Today screen renders a dynamic, role-aware
/// list of cards — keyed by [card_id] — sorted by [urgency].
///
/// Card shapes are defined server-side by `CommandCentreService::assembleForUser`.
/// Keep the model permissive: unknown `card_id`s render via a generic fallback.
class TodayPayload {
  final TodayUser? user;
  final List<TodayCard> cards;

  const TodayPayload({this.user, this.cards = const []});

  factory TodayPayload.fromJson(Map<String, dynamic> json) {
    final raw = (json['cards'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => TodayCard.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    raw.sort((a, b) => a.urgencyRank.compareTo(b.urgencyRank));
    return TodayPayload(
      user: json['user'] is Map
          ? TodayUser.fromJson(Map<String, dynamic>.from(json['user'] as Map))
          : null,
      cards: raw,
    );
  }
}

class TodayUser {
  final int id;
  final String name;
  final String role;

  const TodayUser({required this.id, this.name = '', this.role = ''});

  factory TodayUser.fromJson(Map<String, dynamic> json) {
    return TodayUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

/// One card on the Today screen.
///
/// `items` shape varies per [cardId] — see the spec in the cockpit doc.
/// The renderer treats them generically (`title`/`label`, `value`/`subtitle`)
/// and the card router decides what to do on tap.
class TodayCard {
  final String cardId;
  final String title;
  final String icon;
  final String urgency; // critical | high | medium | low
  final int count;
  final List<Map<String, dynamic>> items;
  final String? viewAllUrl;
  final bool alwaysVisible;

  const TodayCard({
    required this.cardId,
    this.title = '',
    this.icon = '',
    this.urgency = 'low',
    this.count = 0,
    this.items = const [],
    this.viewAllUrl,
    this.alwaysVisible = false,
  });

  int get urgencyRank {
    switch (urgency) {
      case 'critical':
        return 0;
      case 'high':
        return 1;
      case 'medium':
        return 2;
      default:
        return 3;
    }
  }

  factory TodayCard.fromJson(Map<String, dynamic> json) {
    return TodayCard(
      cardId: json['card_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'low',
      count: (json['count'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      viewAllUrl: json['view_all_url']?.toString(),
      alwaysVisible: json['always_visible'] == true,
    );
  }
}
