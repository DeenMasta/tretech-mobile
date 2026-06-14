import 'package:flutter/material.dart';
import '../../../../shared/widgets/status_badge.dart';

/// Maps a stock-in session status to a [StatusBadge].
class StockInStatusBadge extends StatelessWidget {
  const StockInStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final (label, badgeStatus) = switch (lower) {
      'draft' => ('Draft', BadgeStatus.warning),
      'confirmed' => ('Confirmed', BadgeStatus.success),
      'finalized' => ('Confirmed', BadgeStatus.success),
      'cancelled' => ('Cancelled', BadgeStatus.error),
      _ => (status.isEmpty ? 'Unknown' : status, BadgeStatus.neutral),
    };

    return StatusBadge(label: label, status: badgeStatus);
  }
}
