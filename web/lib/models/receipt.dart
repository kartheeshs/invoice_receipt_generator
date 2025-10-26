import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

class ReceiptItem {
  const ReceiptItem({
    required this.id,
    required this.description,
    required this.amount,
  });

  factory ReceiptItem.empty() {
    return ReceiptItem(
      id: _uuid.v4(),
      description: 'Payment item',
      amount: 0,
    );
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] as String? ?? _uuid.v4(),
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String description;
  final double amount;

  ReceiptItem copyWith({
    String? id,
    String? description,
    double? amount,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
    };
  }
}

class Receipt {
  const Receipt({
    required this.id,
    required this.number,
    required this.clientName,
    required this.clientEmail,
    required this.clientAddress,
    required this.issueDate,
    required this.paymentMethod,
    required this.paymentReference,
    required this.currencyCode,
    required this.currencySymbol,
    required this.items,
    required this.taxRate,
    required this.notes,
    this.logoUrl,
  });

  factory Receipt.create({
    required String id,
    required String number,
    required String currencyCode,
    required String currencySymbol,
  }) {
    return Receipt(
      id: id,
      number: number,
      clientName: '',
      clientEmail: '',
      clientAddress: '',
      issueDate: DateTime.now(),
      paymentMethod: 'Bank transfer',
      paymentReference: '',
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      items: [ReceiptItem.empty()],
      taxRate: 0,
      notes: '',
    )._sanitizeItems();
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsedItems = <ReceiptItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(ReceiptItem.fromJson(item));
        } else if (item is Map) {
          parsedItems.add(ReceiptItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return Receipt(
      id: json['id'] as String? ?? _uuid.v4(),
      number: json['number'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      clientEmail: json['clientEmail'] as String? ?? '',
      clientAddress: json['clientAddress'] as String? ?? '',
      issueDate: DateTime.tryParse(json['issueDate'] as String? ?? '') ?? DateTime.now(),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentReference: json['paymentReference'] as String? ?? '',
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      items: parsedItems.isEmpty ? [ReceiptItem.empty()] : parsedItems,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
    )._sanitizeItems();
  }

  final String id;
  final String number;
  final String clientName;
  final String clientEmail;
  final String clientAddress;
  final DateTime issueDate;
  final String paymentMethod;
  final String paymentReference;
  final String currencyCode;
  final String currencySymbol;
  final List<ReceiptItem> items;
  final double taxRate;
  final String notes;
  final String? logoUrl;

  double get subtotal => items.fold<double>(0, (total, item) => total + item.amount);

  double get tax => subtotal * taxRate;

  double get total => subtotal + tax;

  Receipt copyWith({
    String? number,
    String? clientName,
    String? clientEmail,
    String? clientAddress,
    DateTime? issueDate,
    String? paymentMethod,
    String? paymentReference,
    String? currencyCode,
    String? currencySymbol,
    List<ReceiptItem>? items,
    double? taxRate,
    String? notes,
    String? logoUrl,
    bool clearLogoUrl = false,
  }) {
    return Receipt(
      id: id,
      number: number ?? this.number,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAddress: clientAddress ?? this.clientAddress,
      issueDate: issueDate ?? this.issueDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      notes: notes ?? this.notes,
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
    )._sanitizeItems();
  }

  Receipt addItem(ReceiptItem item) => copyWith(items: [...items, item]);

  Receipt updateItem(String itemId, ReceiptItem updated) {
    final updatedItems = items.map((item) => item.id == itemId ? updated : item).toList();
    return copyWith(items: updatedItems);
  }

  Receipt removeItem(String itemId) {
    final updatedItems = items.where((item) => item.id != itemId).toList();
    return copyWith(items: updatedItems.isEmpty ? [ReceiptItem.empty()] : updatedItems);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'clientAddress': clientAddress,
      'issueDate': issueDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
      'items': items.map((item) => item.toJson()).toList(),
      'taxRate': taxRate,
      'notes': notes,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
    };
  }

  Receipt _sanitizeItems() {
    final cleaned = items.isEmpty ? [ReceiptItem.empty()] : items;
    return Receipt(
      id: id,
      number: number,
      clientName: clientName,
      clientEmail: clientEmail,
      clientAddress: clientAddress,
      issueDate: issueDate,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      items: cleaned
          .map(
            (item) => item.id.isEmpty
                ? item.copyWith(id: _uuid.v4(), description: item.description.isEmpty ? 'Payment item' : item.description)
                : item,
          )
          .toList(),
      taxRate: taxRate,
      notes: notes,
      logoUrl: logoUrl,
    );
  }
}
