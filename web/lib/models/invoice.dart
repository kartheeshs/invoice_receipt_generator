enum InvoiceStatus { draft, sent, paid, overdue }

enum InvoiceTemplate { classic, modern, minimal }

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.projectName,
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.template,
    this.notes = '',
  });

  factory Invoice.create({
    required String id,
    required String currencyCode,
    required String currencySymbol,
    InvoiceTemplate template = InvoiceTemplate.classic,
  }) {
    final now = DateTime.now();
    return Invoice(
      id: id,
      number: '#${now.year}${now.month.toString().padLeft(2, '0')}$id',
      clientName: '',
      projectName: '',
      description: '',
      amount: 0,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)),
      status: InvoiceStatus.draft,
      template: template,
    );
  }

  Invoice copyWith({
    String? id,
    String? number,
    String? clientName,
    String? projectName,
    String? description,
    double? amount,
    String? currencyCode,
    String? currencySymbol,
    DateTime? issueDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    InvoiceTemplate? template,
    String? notes,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      template: template ?? this.template,
      notes: notes ?? this.notes,
    );
  }

  final String id;
  final String number;
  final String clientName;
  final String projectName;
  final String description;
  final double amount;
  final String currencyCode;
  final String currencySymbol;
  final DateTime issueDate;
  final DateTime dueDate;
  final InvoiceStatus status;
  final InvoiceTemplate template;
  final String notes;

  bool get isOverdue => status == InvoiceStatus.overdue;
}
