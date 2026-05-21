import 'package:flutter/material.dart';
import '../../widgets/ui/status_chip.dart';

const Color kReactionInterested = Color(0xFF22C55E);
const Color kReactionNotInterested = Color(0xFFEF4444);
const Color kReactionSaved = Color(0xFFF59E0B);

const Color kStatusActive = Color(0xFF0EA5E9);
const Color kStatusPaused = Color(0xFF8890A4);
const Color kStatusFulfilled = Color(0xFF22C55E);
const Color kStatusExpired = Color(0xFFEF4444);

const List<String> kStatuses = ['active', 'paused', 'fulfilled', 'expired'];

Color statusColor(String? s) {
  switch (s) {
    case 'paused':
      return kStatusPaused;
    case 'fulfilled':
      return kStatusFulfilled;
    case 'expired':
      return kStatusExpired;
    default:
      return kStatusActive;
  }
}

Widget statusPill(String? status) {
  final c = statusColor(status);
  final label = (status == null || status.isEmpty) ? 'active' : status;
  return StatusChip(
    label: label[0].toUpperCase() + label.substring(1),
    color: c,
    dense: true,
  );
}

Widget reactionBadge(String reaction) {
  late Color c;
  late String label;
  switch (reaction) {
    case 'interested':
      c = kReactionInterested;
      label = 'Interested';
      break;
    case 'not_interested':
      c = kReactionNotInterested;
      label = 'Not for me';
      break;
    case 'saved':
      c = kReactionSaved;
      label = 'Saved';
      break;
    default:
      return const SizedBox.shrink();
  }
  return StatusChip(label: label, color: c);
}
