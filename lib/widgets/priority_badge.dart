import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  Color get _color {
    switch (priority) {
      case 'critical': return const Color(0xFFef4444);
      case 'high': return const Color(0xFFf59e0b);
      case 'normal': return const Color(0xFF0ea5e9);
      default: return const Color(0xFF6b7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _color),
      ),
    );
  }
}
