import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';

class InvoiceFormDialog extends StatefulWidget {
  const InvoiceFormDialog({
    super.key,
    required this.invoice,
    required this.onSubmit,
  });

  final Invoice invoice;
  final ValueChanged<Invoice> onSubmit;

  @override
  State<InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends State<InvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _clientController;
  late final TextEditingController _projectController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _numberController;
  late final TextEditingController _notesController;
  late DateTime _issueDate;
  late DateTime _dueDate;
  late InvoiceStatus _status;
  late InvoiceTemplate _template;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    _clientController = TextEditingController(text: invoice.clientName);
    _projectController = TextEditingController(text: invoice.projectName);
    _descriptionController = TextEditingController(text: invoice.description);
    _amountController = TextEditingController(
      text: invoice.amount == 0 ? '' : invoice.amount.toStringAsFixed(2),
    );
    _numberController = TextEditingController(text: invoice.number);
    _notesController = TextEditingController(text: invoice.notes);
    _issueDate = invoice.issueDate;
    _dueDate = invoice.dueDate;
    _status = invoice.status;
    _template = invoice.template;
  }

  @override
  void dispose() {
    _clientController.dispose();
    _projectController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appState = context.watch<AppState>();
    final availableTemplates = appState.availableTemplates;
    final templateOptions = InvoiceTemplate.values
        .where((template) => availableTemplates.contains(template) || template == _template)
        .toList();
    final isGuest = appState.isGuest;

    return AlertDialog(
      title: Text(l10n.text(widget.invoice.clientName.isEmpty ? 'newInvoice' : 'editInvoice')),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _clientController,
                  decoration: InputDecoration(labelText: l10n.text('clientLabel')),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.text('validationRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _projectController,
                  decoration: InputDecoration(labelText: l10n.text('projectLabel')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: l10n.text('descriptionLabel')),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: l10n.text('amountLabel')),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.text('validationRequired');
                    }
                    final parsed = double.tryParse(value.replaceAll(',', ''));
                    if (parsed == null) {
                      return l10n.text('validationAmount');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numberController,
                  decoration: InputDecoration(labelText: l10n.text('invoiceNumberLabel')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InvoiceTemplate>(
                  value: _template,
                  decoration: InputDecoration(labelText: l10n.text('templateFieldLabel')),
                  items: templateOptions
                      .map(
                        (template) => DropdownMenuItem(
                          value: template,
                          child: Text(l10n.invoiceTemplateLabel(template)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _template = value);
                    }
                  },
                ),
                if (isGuest && availableTemplates.length == 1) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.text('templatesLocked'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: l10n.text('issueDateLabel'),
                        value: _issueDate,
                        onTap: () => _pickDate(initialDate: _issueDate).then((date) {
                          if (date != null) {
                            setState(() => _issueDate = date);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: l10n.text('dueDateLabel'),
                        value: _dueDate,
                        onTap: () => _pickDate(initialDate: _dueDate).then((date) {
                          if (date != null) {
                            setState(() => _dueDate = date);
                          }
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InvoiceStatus>(
                  value: _status,
                  decoration: InputDecoration(labelText: l10n.text('statusLabel')),
                  items: InvoiceStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(l10n.invoiceStatusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status != null) {
                      setState(() => _status = status);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.text('notesLabel')),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.text('cancelButton')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.text('saveButton')),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate({required DateTime initialDate}) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      useRootNavigator: true,
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    widget.onSubmit(
      widget.invoice.copyWith(
        clientName: _clientController.text.trim(),
        projectName: _projectController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
        number: _numberController.text.trim(),
        issueDate: _issueDate,
        dueDate: _dueDate,
        status: _status,
        template: _template,
        notes: _notesController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(l10n.dateFormat.format(value)),
      ),
    );
  }
}
