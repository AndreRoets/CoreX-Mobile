import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_data.dart';
import '../widgets/task_card.dart';
import 'shared/quick_add_sheet.dart';

class TasksScreen extends StatefulWidget {
  final bool embedded;
  const TasksScreen({super.key, this.embedded = false});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _activeFilter = 'all';

  static const _filters = [
    {'key': 'all', 'label': 'All', 'color': null},
    {'key': 'todo', 'label': 'To Do', 'color': 0xFF6b7280},
    {'key': 'in_progress', 'label': 'In Progress', 'color': 0xFF0ea5e9},
    {'key': 'awaiting', 'label': 'Awaiting', 'color': 0xFFf59e0b},
    {'key': 'done', 'label': 'Done', 'color': 0xFF22c55e},
    {'key': 'overdue', 'label': 'Overdue', 'color': 0xFFef4444},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadTasks();
    });
  }

  List<CommandTask> _filteredTasks(List<CommandTask> all) {
    if (_activeFilter == 'all') return all;
    if (_activeFilter == 'overdue') return all.where((t) => t.isOverdue).toList();
    return all.where((t) => t.status == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final allTasks = dash.tasks.isNotEmpty ? dash.tasks : dash.data.myTasks;
    final filtered = _filteredTasks(allTasks);

    final body = SafeArea(
      child: RefreshIndicator(
        color: AppTheme.brand,
        backgroundColor: AppTheme.surface(context),
        onRefresh: () => context.read<DashboardProvider>().loadTasks(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tasks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
                    const SizedBox(height: 2),
                    Text(
                      '${dash.data.taskSummary.open} open · ${dash.data.taskSummary.overdue} overdue',
                      style: TextStyle(
                        fontSize: 12,
                        color: dash.data.taskSummary.overdue > 0 ? const Color(0xFFef4444) : AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _filters[i];
                      final key = f['key'] as String;
                      final isActive = _activeFilter == key;
                      final color = f['color'] != null ? Color(f['color'] as int) : AppTheme.brand;
                      return GestureDetector(
                        onTap: () => setState(() => _activeFilter = key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive ? color.withValues(alpha: 0.15) : AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(AppTheme.radius),
                            border: Border.all(color: isActive ? color.withValues(alpha: 0.4) : AppTheme.borderColor(context)),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              if (f['color'] != null) ...[
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                f['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isActive ? color : AppTheme.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: AppTheme.surface(context), shape: BoxShape.circle),
                        child: Icon(Icons.checklist_rounded, color: AppTheme.textMuted(context), size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text('No tasks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary(context))),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final task = filtered[i];
                    return TaskCard(
                      task: task,
                      onComplete: () => context.read<DashboardProvider>().completeTask(task.id),
                      onDismiss: () => context.read<DashboardProvider>().resolveTask(task.id, resolution: 'did_not_happen'),
                      onTap: () => _showTaskDetail(context, task),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    final fab = FloatingActionButton(
      heroTag: 'tasks_fab',
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const QuickAddSheet(initialMode: 'task'),
      ),
      backgroundColor: AppTheme.brand,
      child: const Icon(Icons.add, color: Colors.white),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(right: 16, bottom: 16, child: fab),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: body,
      floatingActionButton: fab,
    );
  }

  void _showTaskDetail(BuildContext context, CommandTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: AppTheme.textMuted(context), borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(task.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
            ),
            if (task.propertyAddress != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(task.propertyAddress!, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
              ),
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(task.description!, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  if (task.status != 'done') ...[
                    Expanded(
                      child: _ActionButton(
                        label: 'Complete',
                        color: const Color(0xFF22c55e),
                        onTap: () {
                          context.read<DashboardProvider>().completeTask(task.id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: "Didn't Happen",
                        color: const Color(0xFF6b7280),
                        onTap: () {
                          context.read<DashboardProvider>().resolveTask(task.id, resolution: 'did_not_happen');
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      ),
    );
  }
}
