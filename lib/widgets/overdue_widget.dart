import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_models.dart';
import '../providers/notifications_provider.dart';
import '../screens/notifications/overdue_screen.dart';
import '../theme.dart';

/// Compact "Overdue" strip for the Today screen — four pill buttons that
/// drill into a pillar-filtered overdue list. Hides itself entirely when
/// there's nothing overdue (directive empty state on parent screen handles it).
class OverdueWidget extends StatefulWidget {
  const OverdueWidget({super.key});

  @override
  State<OverdueWidget> createState() => _OverdueWidgetState();
}

class _OverdueWidgetState extends State<OverdueWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadOverdue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final counts =
        context.select<NotificationsProvider, OverdueCounts>((p) => p.overdue.counts);

    if (counts.total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
            color: const Color(0xFFef4444).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 14, color: Color(0xFFef4444)),
              const SizedBox(width: 6),
              Text('${counts.total} overdue',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFef4444))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pill(context, 'Properties', counts.properties, 'property'),
              _pill(context, 'Contacts', counts.contacts, 'contact'),
              _pill(context, 'Deals', counts.deals, 'deal'),
              _pill(context, 'Tasks', counts.tasks, 'task'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label, int count, String filter) {
    if (count == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              OverdueScreen(title: '$label overdue', pillarFilter: filter),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
              color: const Color(0xFFef4444).withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary(context))),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFef4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
