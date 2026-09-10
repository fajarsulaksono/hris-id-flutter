import 'package:flutter/material.dart';

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({
    required this.label,
    required this.status,
    super.key,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };

    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontSize: 11),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
    );
  }
}
