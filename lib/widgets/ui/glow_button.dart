import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/branding.dart';
import '../../theme.dart';

/// Primary CTA with a brand-coloured halo. Use sparingly — at most one per
/// screen — to keep the glow signaling "this is the action".
class GlowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final bool loading;
  final Color? color;
  final double height;

  const GlowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.loading = false,
    this.color,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final bg = color ?? brand.button;
    final fg = Branding.onColor(bg);
    final enabled = onPressed != null && !loading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        boxShadow: enabled
            ? AppTheme.brandGlow(bg, intensity: 0.22, blur: 28, spread: -6)
            : null,
      ),
      child: Material(
        color: enabled ? bg : bg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              : null,
          child: Center(
            child: loading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 20),
                        const SizedBox(width: 10),
                      ],
                      DefaultTextStyle(
                        style: TextStyle(
                          color: fg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                        child: child,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action — elevated dark surface, no border, same dimensions
/// as [GlowButton]. Pair them on screens where two actions sit side-by-side
/// (e.g. login choice screen).
class SoftButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final double height;

  const SoftButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.textPrimary(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: fg, size: 20),
                  const SizedBox(width: 10),
                ],
                DefaultTextStyle(
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
