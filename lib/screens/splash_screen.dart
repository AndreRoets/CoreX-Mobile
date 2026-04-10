import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Animated app-open splash.
///
/// Sequence:
///   1. "CoreX" spin-pops in (scale 0 → 1 + rotate 1.5 turns) with bounce
///   2. Brand underline sweeps in beneath it
///   3. Tagline fades up
///   4. Subtle idle pulse, then [onFinished]
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _titleScale;
  late final Animation<double> _titleRotate;
  late final Animation<double> _titleFade;
  late final Animation<double> _glowFade;
  late final Animation<double> _underlineSweep;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Pop + spin in
    _titleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.55, curve: Curves.elasticOut),
      ),
    );
    _titleRotate = Tween<double>(begin: -1.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.30, curve: Curves.easeOut),
    );

    // Glow behind wordmark
    _glowFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.55, curve: Curves.easeOut),
    );

    // Underline sweep
    _underlineSweep = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
    );

    // Tagline
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.90, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward().whenComplete(() async {
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final bgBottom = isDark ? AppTheme.darkSurface : AppTheme.lightSurface2;
    final titleColor =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final taglineColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wordmark stack: glow + spinning pop-in text
                  SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radial brand glow
                        Opacity(
                          opacity: _glowFade.value * 0.6,
                          child: Container(
                            width: 260,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.brand.withValues(alpha: 0.45),
                                  AppTheme.brand.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Spinning + popping wordmark
                        Opacity(
                          opacity: _titleFade.value,
                          child: Transform.rotate(
                            angle: _titleRotate.value * 2 * math.pi,
                            child: Transform.scale(
                              scale: _titleScale.value,
                              child: ShaderMask(
                                shaderCallback: (rect) => const LinearGradient(
                                  colors: [
                                    AppTheme.brand,
                                    Color(0xFF38BDF8),
                                    Color(0xFF7DD3FC),
                                  ],
                                ).createShader(rect),
                                child: Text(
                                  'CoreX',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Animated underline sweep
                  SizedBox(
                    width: 180,
                    height: 3,
                    child: Align(
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        widthFactor: _underlineSweep.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x000EA5E9),
                                AppTheme.brand,
                                Color(0x000EA5E9),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: Text(
                        'Powering your property universe',
                        style: TextStyle(
                          color: taglineColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
