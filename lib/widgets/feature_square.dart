import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/branding.dart';
import '../theme.dart';

/// Quick Access tile — large translucent icon as a watermark in the
/// upper-right, with the label and a hint pinned to the bottom-left.
/// Each tile picks up a subtle brand-color tint at the top edge.
class FeatureSquare extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  const FeatureSquare({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  @override
  State<FeatureSquare> createState() => _FeatureSquareState();
}

class _FeatureSquareState extends State<FeatureSquare>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down() {
    setState(() => _pressed = true);
    _controller.forward();
  }

  void _up() {
    setState(() => _pressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final accent = brand.icon;
    final dark = AppTheme.isDark(context);

    return GestureDetector(
      onTapDown: (_) => _down(),
      onTapUp: (_) {
        _up();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: _up,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: dark
                  ? [
                      Color.lerp(AppTheme.darkSurface, accent, 0.16)!,
                      AppTheme.darkSurface,
                    ]
                  : [
                      accent.withValues(alpha: 0.08),
                      AppTheme.lightSurface,
                    ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            boxShadow: [
              ...AppTheme.softShadow(context),
              if (_pressed)
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: Stack(
              children: [
                // Watermark icon — large, translucent, anchored top-right.
                Positioned(
                  top: -16,
                  right: -16,
                  child: Icon(
                    widget.icon,
                    size: 120,
                    color: accent.withValues(alpha: dark ? 0.22 : 0.18),
                  ),
                ),
                // Label + hint pinned bottom-left.
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Spacer(),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            widget.hint ?? 'Open',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppTheme.textSecondary(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
