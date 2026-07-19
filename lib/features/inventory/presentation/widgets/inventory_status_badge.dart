import 'package:flutter/material.dart';

import '../../../../shared/widgets/status_badge.dart';

class InventoryStatusBadge extends StatelessWidget {
  const InventoryStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: _label(status), status: _map(status));
  }

  String _label(String value) {
    switch (value) {
      case 'stock_in':
        return 'Stock In';
      case 'returned_to_supplier':
        return 'Returned to Supplier';
      case 'supplied':
        return 'Supplied';
      default:
        if (value.trim().isEmpty) {
          return '-';
        }
        return value
            .split('_')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  BadgeStatus _map(String value) {
    switch (value) {
      case 'available':
      case 'returned':
      case 'stock_in':
        return BadgeStatus.success;
      case 'holding':
      case 'consigned':
        return BadgeStatus.warning;
      case 'used':
      case 'disposed':
      case 'returned_to_supplier':
        return BadgeStatus.error;
      default:
        return BadgeStatus.neutral;
    }
  }
}
