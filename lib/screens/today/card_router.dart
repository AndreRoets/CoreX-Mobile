import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/today_card.dart';
import '../calendar/invitations_screen.dart';
import '../calendar_screen.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/overdue_screen.dart';
import '../tasks_screen.dart';
import 'card_fallback_screen.dart';

/// Maps a Today [TodayCard.cardId] to the screen the user should land on
/// when they tap the card header.
///
/// Cards whose dedicated mobile screen has not been built yet route to
/// [CardFallbackScreen] — a generic list view + "View on web" button.
/// Unknown ids also fall through to the same fallback (with a debug warning,
/// never a crash — per the cockpit UX rules).
class CardRouter {
  CardRouter._();

  static final Map<String, _CardDestination> _table = {
    'today_appointments': (ctx, _) => const CalendarScreen(),
    'pending_invitations': (ctx, _) => const InvitationsScreen(),
    'overdue_items': (ctx, card) => OverdueScreen(title: card.title),
    'unread_notifications': (ctx, _) => const NotificationsScreen(),
    'events_feedback': (ctx, _) => const CalendarScreen(),
    'my_deal_steps': (ctx, _) => const TasksScreen(),
    // Everything below falls through to the generic fallback for Phase 1.
    // Dedicated screens land in Phase 2+.
  };

  /// Tap handler for a card header. Always pushes *something* — never throws.
  static void open(BuildContext context, TodayCard card) {
    final builder = _table[card.cardId];
    if (builder == null) {
      if (kDebugMode) {
        debugPrint('[CardRouter] Unknown card_id "${card.cardId}" '
            '— routing to fallback. Title: ${card.title}');
      }
    }
    final screen = builder != null
        ? builder(context, card)
        : CardFallbackScreen(card: card);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

typedef _CardDestination = Widget Function(BuildContext context, TodayCard card);
