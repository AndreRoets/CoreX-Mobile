import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_models.dart';
import '../../providers/notifications_provider.dart';
import '../../services/deep_link_router.dart';
import '../../theme.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationsProvider>();
    final grouped = _groupByPillar(p.items);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (p.unread > 0)
            TextButton(
              onPressed: () => context.read<NotificationsProvider>().markAllRead(),
              child: const Text('Mark all read',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.brand,
        onRefresh: () => context.read<NotificationsProvider>().loadFeed(),
        child: p.loadingFeed && p.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : p.items.isEmpty
                ? _empty(context)
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final entry in grouped.entries) ...[
                        _PillarHeader(label: _pillarLabel(entry.key)),
                        ...entry.value.map((n) => _NotificationRow(item: n)),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 48, color: AppTheme.textMuted(context)),
                const SizedBox(height: 12),
                Text("You're all caught up.",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary(context))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Group by pillar; within each pillar, overdue first.
  Map<String, List<NotificationItem>> _groupByPillar(List<NotificationItem> items) {
    const pillarOrder = ['property', 'contact', 'deal', 'agent', ''];
    const sevOrder = {'overdue': 0, 'warning': 1, 'info': 2};

    final out = <String, List<NotificationItem>>{};
    for (final n in items) {
      out.putIfAbsent(n.pillar, () => []).add(n);
    }
    for (final list in out.values) {
      list.sort((a, b) {
        final s = (sevOrder[a.severity] ?? 99).compareTo(sevOrder[b.severity] ?? 99);
        if (s != 0) return s;
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    final ordered = <String, List<NotificationItem>>{};
    for (final p in pillarOrder) {
      if (out.containsKey(p)) ordered[p] = out[p]!;
    }
    for (final k in out.keys) {
      ordered.putIfAbsent(k, () => out[k]!);
    }
    return ordered;
  }

  String _pillarLabel(String pillar) {
    switch (pillar) {
      case 'property':
        return 'Properties';
      case 'contact':
        return 'Contacts';
      case 'deal':
        return 'Deals';
      case 'agent':
        return 'My activity';
      default:
        return 'Other';
    }
  }
}

class _PillarHeader extends StatelessWidget {
  final String label;
  const _PillarHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textMuted(context),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationItem item;
  const _NotificationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colour = severityColor(item.severity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final p = context.read<NotificationsProvider>();
          await p.markRead(item.id);
          if (!context.mounted) return;
          await DeepLinkRouter.open(context, item.actionUrl);
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: item.isRead
                  ? AppTheme.borderColor(context)
                  : colour.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: colour,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      _relTime(item.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textMuted(context)),
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

  static String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
