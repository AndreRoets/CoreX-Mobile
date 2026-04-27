import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/dashboard_data.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme.dart';
import '../../widgets/pillar_link.dart';
import '../../widgets/pillar_tag_chip.dart';

/// Action queue — overdue tasks, overdue events, and supervisor candidate
/// docs in one scrollable urgency-ordered list. Replaces the old wizard-
/// style OverdueReviewScreen and the "9+" bell.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final data = dash.data;
    final total = data.inboxTotal;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppTheme.brand,
        backgroundColor: AppTheme.surface(context),
        onRefresh: () => dash.loadDashboard(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Inbox',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (total > 0
                                ? const Color(0xFFef4444)
                                : const Color(0xFF22c55e))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                      child: Text(
                        total > 0 ? '$total' : 'clear',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: total > 0
                              ? const Color(0xFFef4444)
                              : const Color(0xFF22c55e),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (total == 0)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyInbox(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList.separated(
                  itemCount: data.inboxOverdueTasks.length +
                      data.inboxOverdueEvents.length +
                      data.inboxCandidateDocs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    var idx = i;
                    if (idx < data.inboxOverdueTasks.length) {
                      return _OverdueTaskCard(task: data.inboxOverdueTasks[idx]);
                    }
                    idx -= data.inboxOverdueTasks.length;
                    if (idx < data.inboxOverdueEvents.length) {
                      return _OverdueEventCard(event: data.inboxOverdueEvents[idx]);
                    }
                    idx -= data.inboxOverdueEvents.length;
                    return _CandidateDocCard(doc: data.inboxCandidateDocs[idx]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverdueTaskCard extends StatefulWidget {
  final CommandTask task;
  const _OverdueTaskCard({required this.task});

  @override
  State<_OverdueTaskCard> createState() => _OverdueTaskCardState();
}

class _OverdueTaskCardState extends State<_OverdueTaskCard> {
  bool _rescheduling = false;
  int _days = 3;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    return _InboxCardFrame(
      stripeColour: const Color(0xFFef4444),
      hasLink: hasPillarLink(
        propertyId: t.propertyId,
        dealId: t.dealId,
        contactId: t.contactId,
      ),
      onTap: () => navigateToPillar(
        context,
        propertyId: t.propertyId,
        dealId: t.dealId,
        contactId: t.contactId,
      ),
      icon: Icons.assignment_late_outlined,
      iconColour: const Color(0xFFef4444),
      pillar: t.effectivePillarTag,
      title: t.title,
      subtitle: _timeLabel(t.dueDate, 'Due'),
      address: t.propertyAddress ?? t.contactName,
      actions: _rescheduling
          ? _ReschedulePanel(
              days: _days,
              onMinus: () => setState(() => _days = (_days - 1).clamp(1, 90)),
              onPlus: () => setState(() => _days = (_days + 1).clamp(1, 90)),
              onCancel: () => setState(() => _rescheduling = false),
              onSave: () {
                context.read<DashboardProvider>().rescheduleTask(t.id, _days);
                setState(() => _rescheduling = false);
              },
            )
          : Row(
              children: [
                _InlineAction(
                  label: 'Done',
                  colour: const Color(0xFF22c55e),
                  onTap: () =>
                      context.read<DashboardProvider>().completeTask(t.id),
                ),
                const SizedBox(width: 6),
                _InlineAction(
                  label: 'Reschedule',
                  colour: AppTheme.brand,
                  onTap: () => setState(() => _rescheduling = true),
                ),
                const SizedBox(width: 6),
                _InlineAction(
                  label: 'Skip',
                  colour: const Color(0xFF6b7280),
                  onTap: () => context
                      .read<DashboardProvider>()
                      .resolveTask(t.id, resolution: 'did_not_happen'),
                ),
              ],
            ),
    );
  }
}

class _OverdueEventCard extends StatefulWidget {
  final CalendarEvent event;
  const _OverdueEventCard({required this.event});

  @override
  State<_OverdueEventCard> createState() => _OverdueEventCardState();
}

class _OverdueEventCardState extends State<_OverdueEventCard> {
  bool _rescheduling = false;
  int _days = 3;

  Color get _stripe {
    try {
      return Color(int.parse(widget.event.colour.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6b7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return _InboxCardFrame(
      stripeColour: _stripe,
      hasLink: hasPillarLink(
        propertyId: e.propertyId,
        contactId: e.contactId,
      ),
      onTap: () => navigateToPillar(
        context,
        propertyId: e.propertyId,
        contactId: e.contactId,
      ),
      icon: Icons.event_busy_outlined,
      iconColour: _stripe,
      pillar: e.effectivePillarTag,
      title: e.title,
      subtitle: _timeLabel(e.eventDate, 'Was'),
      address: e.propertyAddress ?? e.contactName,
      actions: _rescheduling
          ? _ReschedulePanel(
              days: _days,
              onMinus: () => setState(() => _days = (_days - 1).clamp(1, 90)),
              onPlus: () => setState(() => _days = (_days + 1).clamp(1, 90)),
              onCancel: () => setState(() => _rescheduling = false),
              onSave: () {
                context.read<DashboardProvider>().rescheduleEvent(e.id, _days);
                setState(() => _rescheduling = false);
              },
            )
          : Row(
              children: [
                _InlineAction(
                  label: 'Done',
                  colour: const Color(0xFF22c55e),
                  onTap: () =>
                      context.read<DashboardProvider>().completeEvent(e.id),
                ),
                const SizedBox(width: 6),
                _InlineAction(
                  label: 'Reschedule',
                  colour: AppTheme.brand,
                  onTap: () => setState(() => _rescheduling = true),
                ),
                const SizedBox(width: 6),
                _InlineAction(
                  label: 'Skip',
                  colour: const Color(0xFF6b7280),
                  onTap: () => context
                      .read<DashboardProvider>()
                      .resolveEvent(e.id, resolution: 'did_not_happen'),
                ),
              ],
            ),
    );
  }
}

class _CandidateDocCard extends StatelessWidget {
  final CandidateDoc doc;
  const _CandidateDocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return _InboxCardFrame(
      stripeColour: const Color(0xFFf59e0b),
      hasLink: false,
      onTap: null,
      icon: Icons.description_outlined,
      iconColour: const Color(0xFFf59e0b),
      pillar: null,
      title: doc.documentName,
      subtitle: 'Uploaded by ${doc.creatorName}',
      address: null,
      actions: Row(
        children: [
          _InlineAction(
            label: 'Review & Authorise',
            colour: const Color(0xFFf59e0b),
            expanded: true,
            onTap: () async {
              final url = doc.reviewUrl;
              if (url == null || url.isEmpty) return;
              final uri = Uri.tryParse(url);
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }
}

class _InboxCardFrame extends StatelessWidget {
  final Color stripeColour;
  final bool hasLink;
  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColour;
  final String? pillar;
  final String title;
  final String subtitle;
  final String? address;
  final Widget actions;

  const _InboxCardFrame({
    required this.stripeColour,
    required this.hasLink,
    required this.onTap,
    required this.icon,
    required this.iconColour,
    required this.pillar,
    required this.title,
    required this.subtitle,
    required this.address,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: hasLink ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: stripeColour,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radius),
                      bottomLeft: Radius.circular(AppTheme.radius),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 16, color: iconColour),
                            const SizedBox(width: 6),
                            if (pillar != null) PillarTagChip(pillar: pillar),
                            const Spacer(),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (address != null && address!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            address!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        actions,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  final String label;
  final Color colour;
  final VoidCallback onTap;
  final bool expanded;

  const _InlineAction({
    required this.label,
    required this.colour,
    required this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap in its own GestureDetector so the tap doesn't bubble up to the
    // card's row-open handler (stopPropagation-equivalent).
    final btn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colour,
            ),
          ),
        ),
      ),
    );
    return expanded ? Expanded(child: btn) : btn;
  }
}

class _ReschedulePanel extends StatelessWidget {
  final int days;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ReschedulePanel({
    required this.days,
    required this.onMinus,
    required this.onPlus,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // swallow taps so row doesn't navigate
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 16, color: AppTheme.brand),
            onPressed: onMinus,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$days',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 16, color: AppTheme.brand),
            onPressed: onPlus,
          ),
          const SizedBox(width: 2),
          Text(days == 1 ? 'day' : 'days',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary(context))),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            child: Text('Cancel',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textMuted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand,
              minimumSize: const Size(58, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: onSave,
            child: const Text('Save', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

String _timeLabel(DateTime? at, String prefix) {
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inDays > 0) return '$prefix ${diff.inDays}d ago';
  if (diff.inHours > 0) return '$prefix ${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '$prefix ${diff.inMinutes}m ago';
  return '$prefix just now';
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF22c55e).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check,
                size: 34, color: Color(0xFF22c55e)),
          ),
          const SizedBox(height: 16),
          Text(
            'Inbox clear.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You're on top of things.",
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}
