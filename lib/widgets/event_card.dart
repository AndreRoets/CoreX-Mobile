import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../theme.dart';
import 'priority_badge.dart';

class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onComplete, this.onTap});

  Color get _colour {
    try {
      return Color(int.parse(event.colour.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6b7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('event-${event.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onComplete?.call();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF22c55e),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, color: Colors.white, size: 20),
            SizedBox(height: 2),
            Text('Complete', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      child: Material(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _colour,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.allDay ? 'All day' : _formatTime(event.eventDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.brand),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _colour.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.eventType[0].toUpperCase() + event.eventType.substring(1),
                              style: TextStyle(fontSize: 10, color: _colour),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(event.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (event.propertyAddress != null) ...[
                        const SizedBox(height: 2),
                        Text(event.propertyAddress!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (event.priority == 'high' || event.priority == 'critical') ...[
                  const SizedBox(width: 8),
                  PriorityBadge(priority: event.priority),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
