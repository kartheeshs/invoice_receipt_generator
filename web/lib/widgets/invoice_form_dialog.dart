import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';

class InvoiceFormDialog extends StatefulWidget {
  const InvoiceFormDialog({
    super.key,
    required this.invoiceId,
    this.initialInvoice,
    required this.initialNumber,
    required this.autoNumberingEnabled,
    required this.defaultTaxRate,
  });

  final String invoiceId;
  final Invoice? initialInvoice;
  final String initialNumber;
  final bool autoNumberingEnabled;
  final double defaultTaxRate;

  @override
  State<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends State<InvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _clientController;
  late final TextEditingController _projectController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;

  late DateTime _issueDate;
  late DateTime _dueDate;
  late InvoiceStatus _status;
  late double _taxRate;

  final List<_InvoiceItemEntry> _itemEntries = [];
  String? _itemError;

  @override
  void initState() {
    super.initState();
    final invoice = widget.initialInvoice;
    _numberController = TextEditingController(
      text: invoice?.number.isNotEmpty == true ? invoice!.number : widget.initialNumber,
    );
    _clientController = TextEditingController(text: invoice?.clientName ?? '');
    _projectController = TextEditingController(text: invoice?.projectName ?? '');
    _emailController = TextEditingController(text: invoice?.billingEmail ?? '');
    _notesController = TextEditingController(text: invoice?.notes ?? '');

    _issueDate = invoice?.issueDate ?? DateTime.now();
    _dueDate = invoice?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _status = invoice?.status ?? InvoiceStatus.draft;
    _taxRate = invoice?.taxRate ?? widget.defaultTaxRate;

    if (invoice != null) {
      for (final item in invoice.items) {
        _itemEntries.add(_InvoiceItemEntry(
          id: item.id,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
        ));
      }
    } else {
      _itemEntries.add(_InvoiceItemEntry());
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _clientController.dispose();
    _projectController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    for (final entry in _itemEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 720,
        height: 640,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.initialInvoice == null ? '請求書を作成' : '請求書を編集',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: 320,
                              child: TextFormField(
                                controller: _numberController,
                                readOnly: widget.autoNumberingEnabled && widget.initialInvoice == null,
                                decoration: const InputDecoration(
                                  labelText: '請求書番号',
                                  hintText: 'INV-202405-001',
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return '請求書番号を入力してください。';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: 320,
                              child: DropdownButtonFormField<InvoiceStatus>(
                                value: _status,
                                items: InvoiceStatus.values
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
                                decoration: const InputDecoration(labelText: 'ステータス'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _clientController,
                          decoration: const InputDecoration(labelText: '請求先（会社名）'),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return '請求先を入力してください。';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _projectController,
                          decoration: const InputDecoration(labelText: '案件名 / 件名'),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return '案件名を入力してください。';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: 320,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: '請求書送付先メールアドレス',
                                  hintText: 'billing@example.jp',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 320,
                              child: DropdownButtonFormField<double>(
                                value: _taxRate,
                                decoration: const InputDecoration(labelText: '税率'),
                                items: const [
                                  DropdownMenuItem(value: 0.0, child: Text('0%')), 
                                  DropdownMenuItem(value: 0.08, child: Text('8% (軽減税率)')), 
                                  DropdownMenuItem(value: 0.1, child: Text('10% (標準税率)')), 
                                  DropdownMenuItem(value: 0.2, child: Text('20%')), 
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _taxRate = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: '発行日',
                                value: _issueDate,
                                onTap: () => _selectDate(context, isIssueDate: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DateField(
                                label: '支払期限',
                                value: _dueDate,
                                onTap: () => _selectDate(context, isIssueDate: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('請求内容', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ..._itemEntries.map((entry) => _ItemCard(
                              entry: entry,
                              onChanged: () => setState(() {}),
                              onRemove: _itemEntries.length > 1
                                  ? () => setState(() {
                                        _itemEntries.remove(entry);
                                        entry.dispose();
                                      })
                                  : null,
                            )),
                        if (_itemError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _itemError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() {
                              final entry = _InvoiceItemEntry();
                              _itemEntries.add(entry);
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text('品目を追加'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '備考・メッセージ',
                            hintText: '例: お振込手数料は貴社負担にてお願いいたします。',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Builder(
                          builder: (context) {
                            final subtotal = _calculateSubtotal();
                            final tax = subtotal * _taxRate;
                            final total = subtotal + tax;
                            return _SummaryCard(
                              subtotal: currency.format(subtotal),
                              tax: currency.format(tax),
                              total: currency.format(total),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _handleSubmit,
                    child: Text(widget.initialInvoice == null ? '作成する' : '更新する'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (final entry in _itemEntries) {
      final quantity = int.tryParse(entry.quantityController.text) ?? 0;
      final unitPrice = double.tryParse(entry.unitPriceController.text) ?? 0;
      subtotal += quantity * unitPrice;
    }
    return subtotal;
  }

  Future<void> _selectDate(BuildContext context, {required bool isIssueDate}) async {
    final initial = isIssueDate ? _issueDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          if (_dueDate.isBefore(picked)) {
            _dueDate = picked.add(const Duration(days: 30));
          }
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      return;
    }

    final items = <InvoiceItem>[];
    for (final entry in _itemEntries) {
      final description = entry.descriptionController.text.trim();
      final quantity = int.tryParse(entry.quantityController.text) ?? 0;
      final unitPrice = double.tryParse(entry.unitPriceController.text) ?? 0;

      if (description.isEmpty) {
        continue;
      }
      if (quantity <= 0) {
        setState(() => _itemError = '数量は1以上で入力してください。');
        return;
      }
      items.add(InvoiceItem(
        id: entry.id,
        description: description,
        quantity: quantity,
        unitPrice: unitPrice,
      ));
    }

    if (items.isEmpty) {
      setState(() => _itemError = '品目を1件以上追加してください。');
      return;
    }

    setState(() => _itemError = null);

    final invoice = Invoice(
      id: widget.invoiceId,
      number: _numberController.text.trim(),
      clientName: _clientController.text.trim(),
      projectName: _projectController.text.trim(),
      issueDate: _issueDate,
      dueDate: _dueDate,
      status: _status,
      taxRate: _taxRate,
      items: items,
      notes: _notesController.text.trim(),
      billingEmail: _emailController.text.trim(),
      downloadCount: widget.initialInvoice?.downloadCount ?? 0,
    );

    Navigator.of(context).pop(invoice);
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy/MM/dd');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(formatter.format(value)),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.entry, required this.onChanged, this.onRemove});

  final _InvoiceItemEntry entry;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFF7F2FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.descriptionController,
                    decoration: const InputDecoration(labelText: '品目名'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return '品目名を入力してください。';
                      }
                      return null;
                    },
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                if (onRemove != null)
                  IconButton(
                    tooltip: '削除',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.quantityController,
                    decoration: const InputDecoration(labelText: '数量'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: entry.unitPriceController,
                    decoration: const InputDecoration(labelText: '単価 (¥)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.subtotal, required this.tax, required this.total});

  final String subtotal;
  final String tax;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryRow(label: '小計', value: subtotal),
            _SummaryRow(label: '消費税', value: tax),
            const Divider(height: 24),
            _SummaryRow(
              label: '合計',
              value: total,
              isEmphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.isEmphasized = false});

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final textStyle = isEmphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: textStyle),
        ],
      ),
    );
  }
}

class _InvoiceItemEntry {
  _InvoiceItemEntry({
    String? id,
    String? description,
    int? quantity,
    double? unitPrice,
  })  : id = id ?? UniqueKey().toString(),
        descriptionController = TextEditingController(text: description ?? ''),
        quantityController = TextEditingController(text: (quantity ?? 1).toString()),
        unitPriceController = TextEditingController(
          text: unitPrice != null
              ? (unitPrice % 1 == 0
                  ? unitPrice.toStringAsFixed(0)
                  : unitPrice.toStringAsFixed(2))
              : '0',
        );

  final String id;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
