import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications_provider.dart';
import '../screens/notifications/notifications_screen.dart';
import '../theme.dart';

/// AppBar action: bell + small dot when there are unread notifications.
/// Per cockpit UX rules: never a "9+" badge — just a dot.
class BellIcon extends StatelessWidget {
  const BellIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationsProvider, int>((p) => p.unread);

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        ));
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded,
              color: AppTheme.textPrimary(context)),
          if (unread > 0)
            const Positioned(
              right: -1,
              top: -1,
              child: _UnreadDot(),
            ),
        ],
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFef4444),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.surface(context), width: 1.5),
      ),
    );
  }
}
