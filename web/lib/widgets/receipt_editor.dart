import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/receipt.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';

class ReceiptEditor extends StatefulWidget {
  const ReceiptEditor({
    super.key,
    required this.receipt,
    required this.profile,
    required this.isNewDraft,
    required this.onSave,
    required this.onDelete,
    required this.onDownload,
    required this.onClose,
    required this.onRequestSignIn,
  });

  final Receipt receipt;
  final UserProfile profile;
  final bool isNewDraft;
  final Future<void> Function(Receipt receipt) onSave;
  final Future<void> Function(Receipt receipt)? onDelete;
  final Future<void> Function(Receipt receipt) onDownload;
  final VoidCallback onClose;
  final Future<void> Function() onRequestSignIn;

  @override
  State<ReceiptEditor> createState() => _ReceiptEditorState();
}

class _ReceiptEditorState extends State<ReceiptEditor> {
  late Receipt _workingReceipt;
  late final ScrollController _scrollController;
  late final TextEditingController _numberController;
  late final TextEditingController _clientNameController;
  late final TextEditingController _clientEmailController;
  late final TextEditingController _clientAddressController;
  late final TextEditingController _paymentMethodController;
  late final TextEditingController _paymentReferenceController;
  late final TextEditingController _taxRateController;
  late final TextEditingController _notesController;
  final Map<String, TextEditingController> _descriptionControllers = {};
  final Map<String, TextEditingController> _amountControllers = {};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _numberController = TextEditingController();
    _clientNameController = TextEditingController();
    _clientEmailController = TextEditingController();
    _clientAddressController = TextEditingController();
    _paymentMethodController = TextEditingController();
    _paymentReferenceController = TextEditingController();
    _taxRateController = TextEditingController();
    _notesController = TextEditingController();
    _applyReceipt(widget.receipt);
  }

  @override
  void didUpdateWidget(covariant ReceiptEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt.id != widget.receipt.id) {
      _disposeItemControllers();
      _applyReceipt(widget.receipt);
    }
  }

  void _applyReceipt(Receipt receipt) {
    _workingReceipt = receipt;
    _numberController.text = receipt.number;
    _clientNameController.text = receipt.clientName;
    _clientEmailController.text = receipt.clientEmail;
    _clientAddressController.text = receipt.clientAddress;
    _paymentMethodController.text = receipt.paymentMethod;
    _paymentReferenceController.text = receipt.paymentReference;
    _taxRateController.text = receipt.taxRate == 0 ? '' : (receipt.taxRate * 100).toStringAsFixed(1);
    _notesController.text = receipt.notes;
    _refreshItemControllers();
  }

  void _refreshItemControllers() {
    final existingIds = _descriptionControllers.keys.toSet();
    final currentIds = _workingReceipt.items.map((item) => item.id).toSet();
    for (final removedId in existingIds.difference(currentIds)) {
      _descriptionControllers.remove(removedId)?.dispose();
      _amountControllers.remove(removedId)?.dispose();
    }
    for (final item in _workingReceipt.items) {
      final descriptionController =
          _descriptionControllers[item.id] ?? TextEditingController(text: item.description);
      if (!_descriptionControllers.containsKey(item.id)) {
        _descriptionControllers[item.id] = descriptionController;
      } else if (descriptionController.text != item.description) {
        descriptionController.text = item.description;
      }
      final amountController = _amountControllers[item.id] ??
          TextEditingController(text: item.amount == 0 ? '' : item.amount.toStringAsFixed(2));
      if (!_amountControllers.containsKey(item.id)) {
        _amountControllers[item.id] = amountController;
      } else {
        final formatted = item.amount == 0 ? '' : item.amount.toStringAsFixed(2);
        if (amountController.text != formatted) {
          amountController.text = formatted;
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _numberController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    _paymentMethodController.dispose();
    _paymentReferenceController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    _disposeItemControllers();
    super.dispose();
  }

  void _disposeItemControllers() {
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    _descriptionControllers.clear();
    _amountControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      name: _workingReceipt.currencyCode,
      symbol: _workingReceipt.currencySymbol,
    );

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, l10n),
              const SizedBox(height: 20),
              _buildReceiptDetails(theme, l10n),
              const SizedBox(height: 20),
              _buildItemsCard(theme, l10n, currencyFormat),
              const SizedBox(height: 20),
              _buildNotesCard(theme, l10n),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : widget.onClose,
                      icon: const Icon(Icons.close),
                      label: Text(l10n.text('closeButton')),
                    ),
                    if (widget.onDelete != null && !widget.isNewDraft)
                      OutlinedButton.icon(
                        onPressed: _saving ? null : () => _handleDelete(context),
                        icon: const Icon(Icons.delete),
                        label: Text(l10n.text('deleteButton')),
                      ),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _handleDownload(context),
                      icon: const Icon(Icons.download),
                      label: Text(l10n.text('receiptDownloadButton')),
                    ),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _handleSave(context),
                      icon: const Icon(Icons.save),
                      label: Text(l10n.text('saveButton')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: widget.onClose,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 12),
            Text(l10n.text('receiptFormTitle'), style: theme.textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.text('receiptEditorSubtitle'), style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildReceiptDetails(ThemeData theme, AppLocalizations l10n) {
    final dateFormat = l10n.longDateFormat;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('receiptDetailsSection'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _numberController,
                    decoration: InputDecoration(
                      labelText: l10n.text('receiptNumberLabel'),
                    ),
                    onChanged: (value) => _workingReceipt = _workingReceipt.copyWith(number: value.trim()),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: _DatePickerField(
                    label: l10n.text('receiptIssueDateLabel'),
                    selectedDate: _workingReceipt.issueDate,
                    displayValue: dateFormat.format(_workingReceipt.issueDate),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _workingReceipt.issueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() {
                          _workingReceipt = _workingReceipt.copyWith(issueDate: selected);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _paymentMethodController,
                    decoration: InputDecoration(labelText: l10n.text('receiptPaymentMethodLabel')),
                    onChanged: (value) =>
                        _workingReceipt = _workingReceipt.copyWith(paymentMethod: value.trim()),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextFormField(
                    controller: _paymentReferenceController,
                    decoration: InputDecoration(labelText: l10n.text('receiptPaymentReferenceLabel')),
                    onChanged: (value) =>
                        _workingReceipt = _workingReceipt.copyWith(paymentReference: value.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 360,
                  child: TextFormField(
                    controller: _clientNameController,
                    decoration: InputDecoration(labelText: l10n.text('receiptClientNameLabel')),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? l10n.text('fieldRequired') : null,
                    onChanged: (value) =>
                        _workingReceipt = _workingReceipt.copyWith(clientName: value.trim()),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _clientEmailController,
                    decoration: InputDecoration(labelText: l10n.text('receiptClientEmailLabel')),
                    onChanged: (value) =>
                        _workingReceipt = _workingReceipt.copyWith(clientEmail: value.trim()),
                  ),
                ),
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _clientAddressController,
                    decoration: InputDecoration(labelText: l10n.text('receiptClientAddressLabel')),
                    minLines: 2,
                    maxLines: 3,
                    onChanged: (value) =>
                        _workingReceipt = _workingReceipt.copyWith(clientAddress: value.trim()),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: _taxRateController,
                    decoration: InputDecoration(
                      labelText: l10n.text('receiptTaxRateLabel'),
                      suffixText: '%',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      setState(() {
                        _workingReceipt = _workingReceipt.copyWith(taxRate: parsed == null ? 0 : parsed / 100);
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(
    ThemeData theme,
    AppLocalizations l10n,
    NumberFormat currencyFormat,
  ) {
    final items = _workingReceipt.items;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.text('receiptItemsHeading'), style: theme.textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _workingReceipt = _workingReceipt.addItem(ReceiptItem.empty());
                      _refreshItemControllers();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.text('addReceiptItem')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: items.map((item) {
                final descriptionController = _descriptionControllers[item.id]!;
                final amountController = _amountControllers[item.id]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ReceiptItemRow(
                    descriptionController: descriptionController,
                    amountController: amountController,
                    currencySymbol: _workingReceipt.currencySymbol,
                    onChanged: () {
                      final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
                      setState(() {
                        _workingReceipt = _workingReceipt.updateItem(
                          item.id,
                          item.copyWith(
                            description: descriptionController.text.trim(),
                            amount: amount,
                          ),
                        );
                      });
                    },
                    onRemove: items.length <= 1
                        ? null
                        : () {
                            setState(() {
                              _workingReceipt = _workingReceipt.removeItem(item.id);
                              _refreshItemControllers();
                            });
                          },
                    l10n: l10n,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildTotalsRow(
              label: l10n.text('receiptSubtotalLabel'),
              value: currencyFormat.format(_workingReceipt.subtotal),
              theme: theme,
            ),
            const SizedBox(height: 6),
            _buildTotalsRow(
              label: l10n.text('receiptTaxLabel'),
              value: currencyFormat.format(_workingReceipt.tax),
              theme: theme,
            ),
            const SizedBox(height: 6),
            _buildTotalsRow(
              label: l10n.text('receiptTotalLabel'),
              value: currencyFormat.format(_workingReceipt.total),
              theme: theme,
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme, AppLocalizations l10n) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('receiptNotesLabel'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: l10n.text('receiptNotesPlaceholder'),
              ),
              minLines: 3,
              maxLines: 6,
              onChanged: (value) => _workingReceipt = _workingReceipt.copyWith(notes: value.trim()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsRow({
    required String label,
    required String value,
    required ThemeData theme,
    bool emphasize = false,
  }) {
    final style = emphasize
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyLarge;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_workingReceipt);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.text('receiptSaved'))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await onDelete(_workingReceipt);
      if (!mounted) return;
      widget.onClose();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _handleDownload(BuildContext context) async {
    try {
      await widget.onDownload(_workingReceipt);
    } on AccessDeniedException {
      await widget.onRequestSignIn();
    }
  }
}

class _ReceiptItemRow extends StatelessWidget {
  const _ReceiptItemRow({
    required this.descriptionController,
    required this.amountController,
    required this.currencySymbol,
    required this.onChanged,
    required this.onRemove,
    required this.l10n,
  });

  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final String currencySymbol;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: l10n.text('receiptItemDescriptionLabel')),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: l10n.text('receiptItemAmountLabel'),
                      prefixText: currencySymbol,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: l10n.text('removeLineItem'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.displayValue,
    required this.onTap,
  });

  final String label;
  final DateTime selectedDate;
  final String displayValue;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(displayValue, style: theme.textTheme.titleMedium),
              ],
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
