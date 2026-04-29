import 'package:flutter/material.dart';

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
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: c,
        letterSpacing: 0.3,
      ),
    ),
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
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: c,
      ),
    ),
  );
}
