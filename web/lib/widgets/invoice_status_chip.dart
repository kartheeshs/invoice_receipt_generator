import 'package:flutter/material.dart';

import '../models/invoice.dart';

class InvoiceStatusChip extends StatelessWidget {
  const InvoiceStatusChip({super.key, required this.status, this.compact = false});

  final InvoiceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );

    return Chip(
      label: Text(status.label, style: labelStyle),
      avatar: Icon(status.icon, size: compact ? 14 : 18, color: color),
      side: BorderSide(color: color.withOpacity(0.3)),
      backgroundColor: color.withOpacity(0.08),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
