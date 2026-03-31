import 'dart:math';
import 'package:flutter/material.dart';

class ScoreCircle extends StatelessWidget {
  final int score;
  final double size;

  const ScoreCircle({super.key, required this.score, this.size = 40});

  Color get _color {
    if (score >= 90) return const Color(0xFF22c55e);
    if (score >= 70) return const Color(0xFF3b82f6);
    if (score >= 50) return const Color(0xFFf59e0b);
    return const Color(0xFFef4444);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreCirclePainter(score: score, color: _color),
        child: Center(
          child: Text(
            '$score',
            style: TextStyle(fontSize: size * 0.28, fontWeight: FontWeight.w700, color: _color),
          ),
        ),
      ),
    );
  }
}

class _ScoreCirclePainter extends CustomPainter {
  final int score;
  final Color color;

  _ScoreCirclePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Background arc
    canvas.drawCircle(center, radius, Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Score arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * (score / 100),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter old) => old.score != score;
}
