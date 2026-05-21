import 'package:flutter/material.dart';
import '../theme.dart';
import 'ui/hero_card.dart';

class StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color? dotColor;

  const StatPill({super.key, required this.value, required this.label, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: AppTheme.radiusChip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: dotColor!.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: -1),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppTheme.textPrimary(context))),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary(context))),
        ],
      ),
    );
  }
}
