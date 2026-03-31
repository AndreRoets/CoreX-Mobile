import 'package:flutter/material.dart';
import '../theme.dart';

class StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color? dotColor;

  const StatPill({super.key, required this.value, required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
          ],
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }
}
