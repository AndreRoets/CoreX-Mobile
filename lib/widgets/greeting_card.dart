import 'package:flutter/material.dart';
import '../theme.dart';

class GreetingCard extends StatelessWidget {
  final String userName;

  const GreetingCard({super.key, required this.userName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'sunrise';
    if (hour < 17) return 'sun';
    return 'moon';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.brandDark,
                  AppTheme.brandDark.withValues(alpha: 0.6),
                ]
              : [
                  AppTheme.brand.withValues(alpha: 0.08),
                  AppTheme.brandDark.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isDark
              ? AppTheme.brand.withValues(alpha: 0.15)
              : AppTheme.brand.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.brand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Icon(
              _greetingEmoji == 'sunrise'
                  ? Icons.wb_twilight_rounded
                  : _greetingEmoji == 'sun'
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
              color: AppTheme.brand,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedDate {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
