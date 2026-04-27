import 'package:flutter/material.dart';

/// 9px uppercase chip that matches the web cockpit's pillar tags.
/// Renders nothing (a zero-sized SizedBox) when [pillar] is null/unknown —
/// orphan items are forbidden per the cockpit spec, so this absence is a
/// signal that something's off, not a layout concern.
class PillarTagChip extends StatelessWidget {
  final String? pillar;

  const PillarTagChip({super.key, required this.pillar});

  static const _colours = {
    'property': Color(0xFFF97316),
    'deal': Color(0xFF3B82F6),
    'contact': Color(0xFF8B5CF6),
  };

  static const _labels = {
    'property': 'PROPERTY',
    'deal': 'DEAL',
    'contact': 'CONTACT',
  };

  @override
  Widget build(BuildContext context) {
    final key = pillar?.toLowerCase();
    final colour = _colours[key];
    final label = _labels[key];
    if (colour == null || label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: colour,
        ),
      ),
    );
  }
}
