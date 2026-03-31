import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_data.dart';
import '../widgets/stat_pill.dart';
import '../widgets/event_card.dart';
import '../widgets/task_card.dart';
import '../widgets/score_circle.dart';
import 'create_event_sheet.dart';
import 'overdue_review_screen.dart';
import 'calendar_screen.dart';
import 'tasks_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(const ['Dashboard', 'Calendar', 'Tasks'][_currentIndex]),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          CalendarScreen(embedded: true),
          TasksScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppTheme.surface(context),
          selectedItemColor: AppTheme.brand,
          unselectedItemColor: AppTheme.textMuted(context),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tasks'),
          ],
        ),
      ),
    );
  }

}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final data = dash.data;

    return RefreshIndicator(
        color: AppTheme.brand,
        backgroundColor: AppTheme.surface(context),
        onRefresh: () => context.read<DashboardProvider>().loadDashboard(),
        child: CustomScrollView(
          slivers: [
            // Overdue banner
            if (data.totalOverdue > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GestureDetector(
                    onTap: () => _showOverdueReview(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFef4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        border: Border.all(color: const Color(0xFFef4444).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFef4444).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text('${data.totalOverdue}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFef4444)))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Overdue items need review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFFef4444))),
                                Text('Tap to resolve', style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFef4444)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Stat pills
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      StatPill(value: '${data.taskSummary.today}', label: 'Today'),
                      const SizedBox(width: 8),
                      StatPill(value: '${data.taskSummary.overdue}', label: 'Overdue', dotColor: const Color(0xFFef4444)),
                      const SizedBox(width: 8),
                      StatPill(value: '${data.taskSummary.thisWeek}', label: 'This Week'),
                      const SizedBox(width: 8),
                      StatPill(
                        value: '${data.mtdPoints}/${data.monthlyTarget}',
                        label: 'pts',
                        dotColor: data.mtdPoints >= data.monthlyTarget ? const Color(0xFF22c55e) : const Color(0xFFf59e0b),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Today's Agenda header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Text("Today's Agenda", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                    const Spacer(),
                    Text('${data.todayEvents.length} events', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
                  ],
                ),
              ),
            ),

            // Today's events
            if (data.todayEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: AppTheme.surface2(context), shape: BoxShape.circle),
                          child: Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted(context), size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text('No events today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const CreateEventSheet(),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.brand.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.brand,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                          ),
                          child: const Text('+ Add Event', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: data.todayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final event = data.todayEvents[i];
                    return EventCard(
                      event: event,
                      onComplete: () => context.read<DashboardProvider>().completeEvent(event.id),
                    );
                  },
                ),
              ),

            // My Tasks header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Text('My Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                    const SizedBox(width: 6),
                    Text('${data.myTasks.length} open', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
                  ],
                ),
              ),
            ),

            // Tasks list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: data.myTasks.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final task = data.myTasks[i];
                  return TaskCard(
                    task: task,
                    onComplete: () => context.read<DashboardProvider>().completeTask(task.id),
                    onDismiss: () => context.read<DashboardProvider>().resolveTask(task.id, resolution: 'did_not_happen'),
                  );
                },
              ),
            ),

            // Properties Needing Attention
            if (data.propsNeedingAttention.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Properties Needing Attention', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                      const SizedBox(height: 4),
                      Text(
                        '${data.propHealthSummary.critical} critical · ${data.propHealthSummary.attention} attention · ${data.propHealthSummary.good} good',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 145,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    itemCount: data.propsNeedingAttention.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final health = data.propsNeedingAttention[i];
                      return _PropertyHealthCard(health: health);
                    },
                  ),
                ),
              ),
            ],

            // Scorecard
            if (data.scorecard != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _ScorecardSection(scorecard: data.scorecard!),
                ),
              ),

            // Candidate Docs
            if (data.candidateDocs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documents Awaiting Authorisation  (${data.candidateDocs.length})',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                      const SizedBox(height: 8),
                      ...data.candidateDocs.map((doc) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                          border: Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.documentName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Uploaded by ${doc.creatorName}', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFf59e0b).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: Text(doc.status.isNotEmpty ? doc.status[0].toUpperCase() + doc.status.substring(1) : '', style: const TextStyle(fontSize: 10, color: Color(0xFFf59e0b))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandDark,
                                  borderRadius: BorderRadius.circular(AppTheme.radius),
                                ),
                                child: const Text('Review & Authorise', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.brand)),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),

            // Loading indicator
            if (dash.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.brand, strokeWidth: 2)),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
    );
  }

  void _showOverdueReview(BuildContext context) {
    final data = context.read<DashboardProvider>().data;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OverdueReviewScreen(tasks: data.overduePopupTasks, events: data.overduePopupEvents)),
    );
  }
}

class _PropertyHealthCard extends StatelessWidget {
  final PropertyHealth health;
  const _PropertyHealthCard({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ScoreCircle(score: health.score, size: 36),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(health.grade[0].toUpperCase() + health.grade.substring(1),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _gradeColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(health.propertyAddress ?? 'Unknown', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textPrimary(context)),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          if (health.factors.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(health.factors.first.label, style: TextStyle(fontSize: 10, color: AppTheme.textMuted(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Color get _gradeColor {
    switch (health.grade) {
      case 'excellent': return const Color(0xFF22c55e);
      case 'good': return const Color(0xFF3b82f6);
      case 'attention': return const Color(0xFFf59e0b);
      case 'critical': return const Color(0xFFef4444);
      default: return const Color(0xFF6b7280);
    }
  }
}

class _ScorecardSection extends StatefulWidget {
  final AgentScorecard scorecard;
  const _ScorecardSection({required this.scorecard});

  @override
  State<_ScorecardSection> createState() => _ScorecardSectionState();
}

class _ScorecardSectionState extends State<_ScorecardSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final sc = widget.scorecard;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              children: [
                ScoreCircle(score: sc.overallScore, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Agent Scorecard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                      Text('Overall Performance', style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context))),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 20, color: AppTheme.textMuted(context)),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Column(
              children: [
                _MetricBar(label: 'Tasks Completed', value: sc.tasksCompleted, total: sc.tasksTotal),
                const SizedBox(height: 12),
                _MetricBar(label: 'Properties Attended', value: sc.propertiesAttended, total: sc.propertiesTotal),
              ],
            ),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  const _MetricBar({required this.label, required this.value, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
            Text('$value/$total', style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context))),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(color: AppTheme.surface2(context), borderRadius: BorderRadius.circular(3)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(decoration: BoxDecoration(color: AppTheme.brand, borderRadius: BorderRadius.circular(3))),
            ),
          ),
        ),
      ],
    );
  }
}
