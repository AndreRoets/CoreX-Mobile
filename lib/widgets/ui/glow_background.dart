import 'package:flutter/material.dart';
import '../../models/branding.dart';
import '../../theme.dart';

/// Full-bleed background with one or two soft radial glows. Used on
/// auth/login screens to give depth without a busy image.
class GlowBackground extends StatelessWidget {
  final Widget child;
  final Color? primaryGlow;
  final Color? secondaryGlow;
  final Alignment primaryAlignment;
  final Alignment secondaryAlignment;

  const GlowBackground({
    super.key,
    required this.child,
    this.primaryGlow,
    this.secondaryGlow,
    this.primaryAlignment = const Alignment(0, -0.6),
    this.secondaryAlignment = const Alignment(0.9, 0.9),
  });

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final p = primaryGlow ?? brand.button;
    final s = secondaryGlow ?? brand.icon;
    final dark = AppTheme.isDark(context);
    final intensity = dark ? 0.22 : 0.12;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppTheme.background(context)),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: primaryAlignment,
                  radius: 0.9,
                  colors: [
                    p.withValues(alpha: intensity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: secondaryAlignment,
                  radius: 0.8,
                  colors: [
                    s.withValues(alpha: intensity * 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
