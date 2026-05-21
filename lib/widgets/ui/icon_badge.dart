import 'package:flutter/material.dart';
import '../../models/branding.dart';
import '../../theme.dart';

/// Rounded-square tinted icon container — the signature visual element of
/// the app. Used in feature tiles, list rows, hero card corners, status
/// indicators. Tint is sourced from the active branding by default so each
/// tenant gets its own accent.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? tint;
  final double tintAlpha;
  final double radius;
  final bool glow;

  const IconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
    this.tint,
    this.tintAlpha = 0.14,
    this.radius = 12,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final color = tint ?? brand.icon;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: tintAlpha),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow ? AppTheme.brandGlow(color, intensity: 0.35) : null,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
