import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../theme.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final CommandTask task;
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onComplete, this.onDismiss, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('task-${task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete?.call();
        } else {
          onDismiss?.call();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
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
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF6b7280),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, color: Colors.white, size: 20),
            SizedBox(height: 2),
            Text("Didn't Happen", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: task.isOverdue ? const Color(0xFFef4444).withValues(alpha: 0.4) : AppTheme.border),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isOverdue ? const Color(0xFFef4444) : AppTheme.border,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title,
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary,
                            decoration: task.status == 'done' ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (task.propertyAddress != null) ...[
                        const SizedBox(height: 2),
                        Text(task.propertyAddress!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PriorityBadge(priority: task.priority),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(task.dueDate!),
                        style: TextStyle(fontSize: 10, color: task.isOverdue ? const Color(0xFFef4444) : AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
