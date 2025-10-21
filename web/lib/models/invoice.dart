import 'package:flutter/material.dart';

enum InvoiceStatus { draft, sent, paid, overdue }

extension InvoiceStatusX on InvoiceStatus {
  Color get color {
    switch (this) {
      case InvoiceStatus.draft:
        return const Color(0xFF6F6F6F);
      case InvoiceStatus.sent:
        return const Color(0xFF6750A4);
      case InvoiceStatus.paid:
        return const Color(0xFF1B873F);
      case InvoiceStatus.overdue:
        return const Color(0xFFB3261E);
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceStatus.draft:
        return Icons.edit_note_outlined;
      case InvoiceStatus.sent:
        return Icons.outgoing_mail;
      case InvoiceStatus.paid:
        return Icons.verified_outlined;
      case InvoiceStatus.overdue:
        return Icons.warning_amber_rounded;
    }
  }
}

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String description;
  final int quantity;
  final double unitPrice;

  double get amount => quantity * unitPrice;

  InvoiceItem copyWith({
    String? id,
    String? description,
    int? quantity,
    double? unitPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class Invoice {
  Invoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.projectName,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.taxRate,
    required this.items,
    this.notes = '',
    this.billingEmail = '',
    this.downloadCount = 0,
  });

  final String id;
  final String number;
  final String clientName;
  final String projectName;
  final DateTime issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final double taxRate;
  final List<InvoiceItem> items;
  final String notes;
  final String billingEmail;
  final int downloadCount;

  double get subtotal =>
      items.fold(0, (previousValue, item) => previousValue + item.amount);

  double get tax => subtotal * taxRate;

  double get total => subtotal + tax;

  bool get isOverdue =>
      status != InvoiceStatus.paid && dueDate.isBefore(DateTime.now());

  bool get isDraft => status == InvoiceStatus.draft;

  Invoice copyWith({
    String? id,
    String? number,
    String? clientName,
    String? projectName,
    DateTime? issueDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    double? taxRate,
    List<InvoiceItem>? items,
    String? notes,
    String? billingEmail,
    int? downloadCount,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      taxRate: taxRate ?? this.taxRate,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      billingEmail: billingEmail ?? this.billingEmail,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }
}
