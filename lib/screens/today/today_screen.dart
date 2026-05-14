import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_models.dart';
import '../../models/today_card.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/api_service.dart';
import '../../services/deep_link_router.dart';
import '../../theme.dart';

/// Today screen — two stacked blocks:
///   A. Today's Schedule (calendar events for today, from `/command-center/today`)
///   B. Unread Notifications (from `/notifications?unread=1`)
///
/// Pull-to-refresh refetches both. Foreground poll every 60s.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
      _startPolling();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startPolling();
    } else {
      _poll?.cancel();
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<DashboardProvider>().loadToday(),
      context.read<NotificationsProvider>().loadFeed(),
    ]);
  }

  Future<void> _pullRefresh() async {
    await Future.wait([
      context.read<DashboardProvider>().refreshToday(),
      context.read<NotificationsProvider>().loadFeed(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final notes = context.watch<NotificationsProvider>();
    final events = _todaysEvents(dash);
    final unread = notes.items.where((n) => !n.isRead).toList();

    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          const _SectionHeader(label: "Today's Schedule"),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const _EmptyTile(text: 'No events today.')
          else
            ...events.map((e) => _EventRow(
                  event: e,
                  onTap: () => _openEventSheet(context, e),
                )),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                  child: _SectionHeader(label: 'Unread Notifications')),
              if (notes.unread > 0)
                TextButton(
                  onPressed: () =>
                      context.read<NotificationsProvider>().markAllRead(),
                  child: const Text('Mark all read',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (unread.isEmpty)
            const _EmptyTile(text: "You're all caught up.")
          else
            ...unread.map((n) => _NotifRow(item: n)),
        ],
      ),
    );
  }

  List<_ScheduleItem> _todaysEvents(DashboardProvider dash) {
    // The unified /today payload exposes today's calendar events under the
    // `today_appointments` card. We render whatever items it returns,
    // permissively mapping common field aliases.
    final card = dash.cards.firstWhere(
      (c) => c.cardId == 'today_appointments',
      orElse: () => const TodayCard(cardId: ''),
    );
    final items = card.items.map(_ScheduleItem.fromMap).toList();
    items.sort((a, b) {
      final at = a.start, bt = b.start;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });
    return items;
  }

  Future<void> _openEventSheet(
      BuildContext context, _ScheduleItem event) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final messenger = ScaffoldMessenger.of(context);
        return _EventDetailSheet(
          event: event,
          onComplete: () async {
            Navigator.of(sheetCtx).pop();
            if (event.id == null) return;
            try {
              await ApiService().completeEvent(event.id!);
            } catch (e) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Complete failed: $e')));
              return;
            }
            if (mounted) _refresh();
          },
          onDismiss: () async {
            Navigator.of(sheetCtx).pop();
            if (event.id == null) return;
            try {
              await ApiService().dismissEvent(event.id!);
            } catch (e) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Dismiss failed: $e')));
              return;
            }
            if (mounted) _refresh();
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary(context),
        letterSpacing: 0.4,
      ),
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final String text;
  const _EmptyTile({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 13, color: AppTheme.textMuted(context))),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final _ScheduleItem event;
  final VoidCallback onTap;
  const _EventRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = event.color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 58,
                  child: Text(
                    event.timeLabel,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context)),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context))),
                      if (event.location != null &&
                          event.location!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.place_outlined,
                              size: 12,
                              color: AppTheme.textMuted(context)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(event.location!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        AppTheme.textSecondary(context))),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                if (event.attendeesCount > 0) ...[
                  const SizedBox(width: 8),
                  Row(children: [
                    Icon(Icons.people_outline,
                        size: 13, color: AppTheme.textMuted(context)),
                    const SizedBox(width: 2),
                    Text('${event.attendeesCount}',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary(context))),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventDetailSheet extends StatelessWidget {
  final _ScheduleItem event;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;
  const _EventDetailSheet({
    required this.event,
    required this.onComplete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = event.color ?? Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              _kv(context, Icons.schedule, event.fullTimeLabel),
              if (event.location != null && event.location!.isNotEmpty)
                _kv(context, Icons.place_outlined, event.location!),
              if (event.eventClassName != null)
                _kv(context, Icons.label_outline, event.eventClassName!),
              if (event.attendeesCount > 0)
                _kv(context, Icons.people_outline,
                    '${event.attendeesCount} attendees'),
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(event.description!,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary(context))),
              ],
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: event.id == null ? null : onDismiss,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: event.id == null ? null : onComplete,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Complete'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 14, color: AppTheme.textMuted(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary(context))),
        ),
      ]),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final NotificationItem item;
  const _NotifRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = _severity(item.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () async {
            final p = context.read<NotificationsProvider>();
            await p.markRead(item.id);
            if (!context.mounted) return;
            final url = item.actionUrl ?? item.data['url']?.toString();
            if (url != null && url.isNotEmpty) {
              await DeepLinkRouter.open(context, url);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_iconFor(item.type),
                  size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context))),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary(context))),
                    ],
                    const SizedBox(height: 4),
                    Text(_relTime(item.createdAt),
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted(context))),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static Color _severity(String s) {
    switch (s) {
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  static IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('task')) return Icons.checklist_rounded;
    if (t.contains('event') || t.contains('calendar')) {
      return Icons.calendar_today_rounded;
    }
    if (t.contains('invit')) return Icons.mail_outline;
    if (t.contains('deal')) return Icons.handshake_outlined;
    if (t.contains('property')) return Icons.home_outlined;
    if (t.contains('contact')) return Icons.person_outline;
    if (t.contains('overdue')) return Icons.warning_amber_rounded;
    return Icons.notifications_outlined;
  }

  static String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}

/// Normalised view of a today_appointments item — permissive on field names
/// so it survives minor server-side renames.
class _ScheduleItem {
  final int? id;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final bool allDay;
  final String? location;
  final String? description;
  final String? eventClassName;
  final Color? color;
  final int attendeesCount;

  const _ScheduleItem({
    this.id,
    required this.title,
    this.start,
    this.end,
    this.allDay = false,
    this.location,
    this.description,
    this.eventClassName,
    this.color,
    this.attendeesCount = 0,
  });

  factory _ScheduleItem.fromMap(Map<String, dynamic> m) {
    int? toInt(dynamic v) =>
        v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      return DateTime.tryParse(s)?.toLocal();
    }

    Color? toColor(dynamic v) {
      if (v == null) return null;
      var s = v.toString().trim();
      if (s.startsWith('#')) s = s.substring(1);
      if (s.length == 6) s = 'FF$s';
      final n = int.tryParse(s, radix: 16);
      return n == null ? null : Color(n);
    }

    final ec = m['event_class'];
    final ecMap = ec is Map ? Map<String, dynamic>.from(ec) : null;

    final attendees = m['attendees'];
    int attCount = 0;
    if (attendees is List) {
      attCount = attendees.length;
    } else if (m['attendees_count'] is num) {
      attCount = (m['attendees_count'] as num).toInt();
    }

    return _ScheduleItem(
      id: toInt(m['id'] ?? m['event_id']),
      title: (m['title'] ?? m['name'] ?? m['label'] ?? '(untitled)').toString(),
      start: toDate(m['starts_at'] ?? m['start'] ?? m['event_date'] ?? m['time']),
      end: toDate(m['ends_at'] ?? m['end'] ?? m['end_date']),
      allDay: m['all_day'] == true,
      location:
          (m['location'] ?? m['property_address'] ?? m['address'])?.toString(),
      description: m['description']?.toString(),
      eventClassName: (ecMap?['name'] ?? m['event_class_name'] ?? m['category'])
          ?.toString(),
      color: toColor(ecMap?['color'] ?? m['color'] ?? m['colour']),
      attendeesCount: attCount,
    );
  }

  String get timeLabel {
    if (allDay) return 'All day';
    final s = start;
    if (s == null) return '';
    return '${s.hour.toString().padLeft(2, '0')}:'
        '${s.minute.toString().padLeft(2, '0')}';
  }

  String get fullTimeLabel {
    if (allDay) return 'All day';
    final s = start;
    if (s == null) return '';
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    if (end != null) return '${fmt(s)} – ${fmt(end!)}';
    return fmt(s);
  }
}
