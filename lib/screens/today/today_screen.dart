import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/branding.dart';
import '../../models/dashboard_data.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme.dart';
import '../../widgets/overdue_widget.dart';
import '../../widgets/pillar_link.dart';
import '../../widgets/pillar_tag_chip.dart';
import '../../widgets/priority_badge.dart';
import '../shared/quick_add_sheet.dart';

/// The primary screen after login — merged timeline of today's events + tasks.
/// Every row is an action: tap → open pillar, swipe right → Done,
/// swipe left → inline reschedule.
class TodayScreen extends StatefulWidget {
  /// Invoked when the user taps the "N need action" header badge — parent
  /// MainTabsScreen switches to the Inbox tab.
  final VoidCallback? onJumpToInbox;

  const TodayScreen({super.key, this.onJumpToInbox});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

enum _Horizon { today, tomorrow, week }

class _TodayScreenState extends State<TodayScreen> {
  _Horizon _horizon = _Horizon.today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dash = context.read<DashboardProvider>();
      if (dash.data.inboxTotal == 0 && dash.data.myTasks.isEmpty) {
        dash.loadDashboard();
      }
      // Load this month's events so Tomorrow/Week tabs have data.
      final m = DateTime.now();
      dash.loadEvents(month: '${m.year}-${m.month.toString().padLeft(2, '0')}');
    });
  }

  ({DateTime start, DateTime end}) _window() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (_horizon) {
      case _Horizon.today:
        return (start: startOfToday, end: startOfToday.add(const Duration(days: 1)));
      case _Horizon.tomorrow:
        final t = startOfToday.add(const Duration(days: 1));
        return (start: t, end: t.add(const Duration(days: 1)));
      case _Horizon.week:
        return (start: startOfToday, end: startOfToday.add(const Duration(days: 7)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final data = dash.data;
    final brand = BrandColors.of(context);

    final window = _window();

    // Source lists.
    final rawEvents = _horizon == _Horizon.today
        ? data.todayEvents
        : dash.events.where((e) =>
            !e.eventDate.isBefore(window.start) &&
            e.eventDate.isBefore(window.end)).toList();

    final rawTasks = data.myTasks.where((t) {
      if (t.dueDate == null) return _horizon == _Horizon.today;
      return !t.dueDate!.isBefore(window.start) && t.dueDate!.isBefore(window.end);
    }).toList();

    // Split all-day from scheduled; tasks with no due time treated as scheduled by date.
    final allDayEvents = rawEvents.where((e) => e.allDay).toList();
    final scheduledEvents = rawEvents.where((e) => !e.allDay).toList();

    final scheduledTasks = rawTasks.where((t) => t.dueDate != null).toList();
    final unscheduledTasks = rawTasks.where((t) => t.dueDate == null).toList();

    // Merge + sort scheduled items by time.
    final scheduled = <_TimelineItem>[
      ...scheduledEvents.map((e) => _TimelineItem.fromEvent(e)),
      ...scheduledTasks.map((t) => _TimelineItem.fromTask(t)),
    ]..sort((a, b) => a.sortAt.compareTo(b.sortAt));

    final allDay = allDayEvents.map((e) => _TimelineItem.fromEvent(e)).toList();

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          RefreshIndicator(
            color: brand.icon,
            backgroundColor: AppTheme.surface(context),
            onRefresh: () => dash.loadDashboard(),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: OverdueWidget()),
                // Horizon segmented — Today / Tomorrow / This Week
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface2(context),
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        children: [
                          _horizonTab(_Horizon.today, 'Today'),
                          _horizonTab(_Horizon.tomorrow, 'Tomorrow'),
                          _horizonTab(_Horizon.week, 'This Week'),
                        ],
                      ),
                    ),
                  ),
                ),

                // Empty state
                if (allDay.isEmpty && scheduled.isEmpty && unscheduledTasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyTimeline(
                      onAdd: () => _openQuickAdd(context, mode: 'event'),
                    ),
                  )
                else ...[
                  if (allDay.isNotEmpty) ...[
                    _sectionHeader('ALL DAY'),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: allDay.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _TimelineRow(
                          item: allDay[i],
                          onComplete: () => _complete(allDay[i]),
                          onReschedule: (d) => _reschedule(allDay[i], d),
                        ).animate().fadeIn(
                              duration: 240.ms,
                              delay: (40 * i).ms,
                            ).slideY(begin: 0.06, end: 0),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],

                  if (scheduled.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: scheduled.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _TimelineRow(
                          item: scheduled[i],
                          onComplete: () => _complete(scheduled[i]),
                          onReschedule: (d) => _reschedule(scheduled[i], d),
                        ).animate().fadeIn(
                              duration: 240.ms,
                              delay: (40 * i).ms,
                            ).slideY(begin: 0.06, end: 0),
                      ),
                    ),

                  if (unscheduledTasks.isNotEmpty) ...[
                    _sectionHeader('UNSCHEDULED'),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: unscheduledTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = _TimelineItem.fromTask(unscheduledTasks[i]);
                          return _TimelineRow(
                            item: item,
                            onComplete: () => _complete(item),
                            onReschedule: (d) => _reschedule(item, d),
                          ).animate().fadeIn(
                                duration: 240.ms,
                                delay: (40 * i).ms,
                              ).slideY(begin: 0.06, end: 0);
                        },
                      ),
                    ),
                  ],
                ],

                // Footer strip
                if (data.scorecard != null || data.mtdPoints > 0)
                  SliverToBoxAdapter(child: _FooterStrip(data: data)),

                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'today_fab',
              onPressed: () => _openQuickAdd(context, mode: 'task'),
              backgroundColor: brand.button,
              foregroundColor: brand.onButton,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horizonTab(_Horizon h, String label) {
    final active = _horizon == h;
    final brand = BrandColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _horizon = h),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? brand.icon : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radius - 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? brand.onIcon : AppTheme.textSecondary(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppTheme.textMuted(context),
          ),
        ),
      ),
    );
  }

  Future<void> _openQuickAdd(BuildContext context, {required String mode}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddSheet(initialMode: mode),
    );
  }

  void _complete(_TimelineItem item) {
    final dash = context.read<DashboardProvider>();
    if (item.kind == _Kind.task) {
      dash.completeTask(item.id);
    } else {
      dash.completeEvent(item.id);
    }
  }

  void _reschedule(_TimelineItem item, int days) {
    final dash = context.read<DashboardProvider>();
    if (item.kind == _Kind.task) {
      dash.rescheduleTask(item.id, days);
    } else {
      dash.rescheduleEvent(item.id, days);
    }
  }
}

enum _Kind { task, event }

/// Merged row model — abstracts task vs event so the row widget stays simple.
class _TimelineItem {
  final _Kind kind;
  final int id;
  final String title;
  final String? subtitle;
  final String? pillar;
  final String priority;
  final String colour;
  final DateTime sortAt;
  final String? time;
  final int? propertyId;
  final int? dealId;
  final int? contactId;

  _TimelineItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.priority,
    required this.colour,
    required this.sortAt,
    this.subtitle,
    this.pillar,
    this.time,
    this.propertyId,
    this.dealId,
    this.contactId,
  });

  factory _TimelineItem.fromEvent(CalendarEvent e) {
    return _TimelineItem(
      kind: _Kind.event,
      id: e.id,
      title: e.title,
      priority: e.priority,
      colour: e.colour,
      sortAt: e.eventDate,
      subtitle: e.propertyAddress ?? e.contactName,
      pillar: e.effectivePillarTag,
      time: e.allDay ? null : _fmtTime(e.eventDate),
      propertyId: e.propertyId,
      contactId: e.contactId,
    );
  }

  factory _TimelineItem.fromTask(CommandTask t) {
    return _TimelineItem(
      kind: _Kind.task,
      id: t.id,
      title: t.title,
      priority: t.priority,
      colour: '#6b7280',
      sortAt: t.dueDate ?? DateTime.now().add(const Duration(days: 3650)),
      subtitle: t.propertyAddress ?? t.contactName,
      pillar: t.effectivePillarTag,
      time: t.dueDate != null ? _fmtTime(t.dueDate!) : null,
      propertyId: t.propertyId,
      dealId: t.dealId,
      contactId: t.contactId,
    );
  }

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _TimelineRow extends StatefulWidget {
  final _TimelineItem item;
  final VoidCallback onComplete;
  final ValueChanged<int> onReschedule;

  const _TimelineRow({
    required this.item,
    required this.onComplete,
    required this.onReschedule,
  });

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  bool _rescheduling = false;
  int _days = 1;

  Color get _stripe {
    try {
      return Color(int.parse(widget.item.colour.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6b7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasLink = hasPillarLink(
      propertyId: item.propertyId,
      dealId: item.dealId,
      contactId: item.contactId,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dismissible(
          key: ValueKey('${item.kind}-${item.id}'),
          direction: DismissDirection.horizontal,
          background: const _SwipeBg(
            colour: Color(0xFF22c55e),
            icon: Icons.check,
            label: 'Done',
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _SwipeBg(
            colour: AppTheme.brand,
            icon: Icons.schedule,
            label: 'Reschedule',
            alignment: Alignment.centerRight,
          ),
          confirmDismiss: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              widget.onComplete();
            } else {
              setState(() {
                _rescheduling = !_rescheduling;
                _days = 1;
              });
            }
            return false;
          },
          child: Material(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              onTap: hasLink
                  ? () => navigateToPillar(
                        context,
                        propertyId: item.propertyId,
                        dealId: item.dealId,
                        contactId: item.contactId,
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.borderColor(context)),
                ),
                child: Row(
                  children: [
                    // Time column
                    SizedBox(
                      width: 46,
                      child: Text(
                        item.time ?? '—',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                    // Colour stripe
                    Container(
                      width: 3,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _stripe,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              PillarTagChip(pillar: item.pillar),
                              if (item.priority == 'high' || item.priority == 'critical') ...[
                                const SizedBox(width: 6),
                                PriorityBadge(priority: item.priority),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_rescheduling) _buildReschedule(),
      ],
    );
  }

  Widget _buildReschedule() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.brand.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text('+ ',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
          _iconBtn(Icons.remove, () {
            if (_days > 1) setState(() => _days--);
          }),
          SizedBox(
            width: 40,
            child: Center(
              child: Text('$_days',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context))),
            ),
          ),
          _iconBtn(Icons.add, () {
            if (_days < 90) setState(() => _days++);
          }),
          const SizedBox(width: 6),
          Text(_days == 1 ? 'day' : 'days',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _rescheduling = false),
            child: Text('Cancel',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand,
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () {
              widget.onReschedule(_days);
              setState(() => _rescheduling = false);
            },
            child: const Text('Save', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: AppTheme.brand),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Color colour;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const _SwipeBg({
    required this.colour,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTimeline({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.surface2(context),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wb_sunny_outlined,
                  size: 30, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 16),
            Text('Your day is clear.',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary(context))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.brand.withValues(alpha: 0.12),
                foregroundColor: AppTheme.brand,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('+ Add Event',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterStrip extends StatelessWidget {
  final DashboardData data;
  const _FooterStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final sc = data.scorecard;
    final target = data.monthlyTarget;
    final pts = data.mtdPoints;
    final pct = target > 0 ? (pts / target).clamp(0.0, 1.0) : 0.0;
    final overTarget = pts >= target && target > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (sc != null) ...[
                _FooterMetric(label: 'Score', value: '${sc.overallScore}'),
                _dot(context),
                _FooterMetric(
                    label: 'Tasks', value: '${sc.tasksCompleted}/${sc.tasksTotal}'),
                _dot(context),
              ],
              _FooterMetric(label: 'Open', value: '${data.taskSummary.open}'),
              const Spacer(),
              // Placeholder for View Performance link — lands in PR 3.
              Text('$pts / $target pts',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: overTarget
                          ? const Color(0xFF22c55e)
                          : const Color(0xFFf59e0b))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        overTarget ? const Color(0xFF22c55e) : AppTheme.brand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          width: 3, height: 3,
          decoration: BoxDecoration(
            color: AppTheme.textMuted(context),
            shape: BoxShape.circle,
          ),
        ),
      );
}

class _FooterMetric extends StatelessWidget {
  final String label;
  final String value;
  const _FooterMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context))),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
      ],
    );
  }
}
