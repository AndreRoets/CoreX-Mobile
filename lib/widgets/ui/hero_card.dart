import 'package:flutter/material.dart';
import '../../models/branding.dart';
import '../../theme.dart';

/// Large rounded card with a brand-tinted gradient and a soft halo. The
/// premium surface — reserve for greetings, KPIs, primary summary cards.
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;
  final bool glow;

  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
    this.tint,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final accent = tint ?? brand.button;

    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(context, accent),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          ...AppTheme.softShadow(context),
          if (glow)
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 40,
              spreadRadius: -12,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Standard tile / card surface — gradient + soft shadow, no border in
/// dark mode. Tappable; ripple is clipped to the rounded shape.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? radius;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppTheme.radius;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient(context),
        borderRadius: BorderRadius.circular(r),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
