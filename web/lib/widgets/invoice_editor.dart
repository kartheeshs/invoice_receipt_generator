import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/user_profile.dart';

class InvoiceEditor extends StatefulWidget {
  const InvoiceEditor({
    super.key,
    required this.invoice,
    required this.profile,
    required this.availableTemplates,
    required this.isNewDraft,
    required this.isGuest,
    required this.onSave,
    required this.onDelete,
    required this.onDownload,
    required this.onClose,
    required this.onRequestSignIn,
  });

  final Invoice invoice;
  final UserProfile profile;
  final List<InvoiceTemplate> availableTemplates;
  final bool isNewDraft;
  final bool isGuest;
  final Future<void> Function(Invoice invoice) onSave;
  final Future<void> Function(Invoice invoice)? onDelete;
  final Future<void> Function(Invoice invoice) onDownload;
  final VoidCallback onClose;
  final Future<void> Function() onRequestSignIn;

  @override
  State<InvoiceEditor> createState() => _InvoiceEditorState();
}

class _InvoiceEditorState extends State<InvoiceEditor> {
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
  late Invoice _workingInvoice;

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController();
    _projectController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
    _numberController = TextEditingController();
    _notesController = TextEditingController();
    _applyInvoice(widget.invoice);
  }

  @override
  void didUpdateWidget(covariant InvoiceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice != widget.invoice) {
      _applyInvoice(widget.invoice);
      setState(() {});
    }
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

  void _applyInvoice(Invoice invoice) {
    _workingInvoice = invoice;
    _clientController.text = invoice.clientName;
    _projectController.text = invoice.projectName;
    _descriptionController.text = invoice.description;
    _amountController.text = invoice.amount == 0 ? '' : invoice.amount.toStringAsFixed(2);
    _numberController.text = invoice.number;
    _notesController.text = invoice.notes;
    _issueDate = invoice.issueDate;
    _dueDate = invoice.dueDate;
    _status = invoice.status;
    _template = invoice.template;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accent = _templateAccent(_template, theme);
    final amountValue = double.tryParse(_amountController.text.replaceAll(',', '')) ?? _workingInvoice.amount;

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.text('invoiceFormTitle'), style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.text('invoiceEditorSubtitle')),
                const SizedBox(height: 16),
                _buildTemplateSelector(context, accent),
                const SizedBox(height: 16),
                if (widget.isNewDraft)
                  _DraftBadge(message: l10n.text('draftUnsavedBody')),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent.withOpacity(0.95), accent.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.profile.companyName,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.profile.address,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                                      ),
                                    ),
                                    if (widget.profile.phone.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.profile.phone,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: isNarrow ? 200 : 240,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      l10n.text('invoicePreviewTitle'),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFilledField(
                                      context,
                                      controller: _numberController,
                                      label: l10n.text('invoiceNumberLabel'),
                                      textAlign: TextAlign.right,
                                      onChanged: (value) => _updateInvoice(number: value.trim()),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDateField(
                                      context,
                                      label: l10n.text('issueDateLabel'),
                                      value: _issueDate,
                                      onPressed: () async {
                                        final date = await _pickDate(initialDate: _issueDate);
                                        if (date != null) {
                                          setState(() {
                                            _issueDate = date;
                                            _workingInvoice = _workingInvoice.copyWith(issueDate: date);
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDateField(
                                      context,
                                      label: l10n.text('dueDateLabel'),
                                      value: _dueDate,
                                      onPressed: () async {
                                        final date = await _pickDate(initialDate: _dueDate);
                                        if (date != null) {
                                          setState(() {
                                            _dueDate = date;
                                            _workingInvoice = _workingInvoice.copyWith(dueDate: date);
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: theme.colorScheme.surface,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 24,
                                runSpacing: 16,
                                children: [
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 280,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.text('companyDetailsTitle'), style: theme.textTheme.titleMedium),
                                        const SizedBox(height: 8),
                                        Text(widget.profile.displayName),
                                        if (widget.profile.taxId.isNotEmpty)
                                          Text(widget.profile.taxId),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 320,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.text('clientDetailsTitle'), style: theme.textTheme.titleMedium),
                                        const SizedBox(height: 12),
                                        _buildOutlinedField(
                                          controller: _clientController,
                                          label: l10n.text('clientLabel'),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return l10n.text('validationRequired');
                                            }
                                            return null;
                                          },
                                          onChanged: (value) => _updateInvoice(clientName: value.trim()),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildOutlinedField(
                                          controller: _projectController,
                                          label: l10n.text('projectLabel'),
                                          onChanged: (value) => _updateInvoice(projectName: value.trim()),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 24,
                                runSpacing: 16,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 420,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.text('descriptionLabel'), style: theme.textTheme.titleMedium),
                                        const SizedBox(height: 12),
                                        _buildOutlinedField(
                                          controller: _descriptionController,
                                          label: l10n.text('descriptionLabel'),
                                          maxLines: 3,
                                          onChanged: (value) => _updateInvoice(description: value.trim()),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildOutlinedField(
                                          controller: _notesController,
                                          label: l10n.text('notesLabel'),
                                          maxLines: 3,
                                          onChanged: (value) => _updateInvoice(notes: value.trim()),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: isNarrow ? double.infinity : 220,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.text('amountLabel'), style: theme.textTheme.titleMedium),
                                        const SizedBox(height: 12),
                                        _buildOutlinedField(
                                          controller: _amountController,
                                          label: l10n.text('amountLabel'),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return l10n.text('validationRequired');
                                            }
                                            final sanitized = value.replaceAll(',', '');
                                            if (double.tryParse(sanitized) == null) {
                                              return l10n.text('validationAmount');
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            final sanitized = value.replaceAll(',', '');
                                            final parsed = double.tryParse(sanitized);
                                            if (parsed != null) {
                                              setState(() {
                                                _workingInvoice = _workingInvoice.copyWith(amount: parsed);
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<InvoiceStatus>(
                                          value: _status,
                                          decoration: InputDecoration(
                                            labelText: l10n.text('statusLabel'),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
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
                                              setState(() {
                                                _status = status;
                                                _workingInvoice = _workingInvoice.copyWith(status: status);
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          l10n.currencyFormat(
                                            widget.invoice.currencyCode,
                                            widget.invoice.currencySymbol,
                                          ).format(amountValue),
                                          style: theme.textTheme.headlineSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (!widget.isNewDraft && widget.onDelete != null)
                      TextButton.icon(
                        onPressed: () async {
                          await widget.onDelete?.call(_workingInvoice);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.text('deleteButton')),
                      ),
                    OutlinedButton.icon(
                      onPressed: widget.isGuest
                          ? () async => widget.onRequestSignIn()
                          : () async => widget.onDownload(_workingInvoice),
                      icon: Icon(widget.isGuest ? Icons.lock_outline : Icons.picture_as_pdf_outlined),
                      label: Text(l10n.text('downloadPdf')),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() != true) {
                          return;
                        }
                        final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
                        final updated = _workingInvoice.copyWith(
                          clientName: _clientController.text.trim(),
                          projectName: _projectController.text.trim(),
                          description: _descriptionController.text.trim(),
                          notes: _notesController.text.trim(),
                          number: _numberController.text.trim(),
                          amount: amount,
                          issueDate: _issueDate,
                          dueDate: _dueDate,
                          status: _status,
                          template: _template,
                        );
                        await widget.onSave(updated);
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.text('saveButton')),
                    ),
                    TextButton(
                      onPressed: widget.onClose,
                      child: Text(l10n.text('closeEditor')),
                    ),
                  ],
                ),
                if (widget.isGuest)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.text('downloadRequiresAccount'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateSelector(BuildContext context, Color accent) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('templateFieldLabel'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: InvoiceTemplate.values.map((template) {
            final available = widget.availableTemplates.contains(template);
            final selected = _template == template;
            final previewColor = _templateAccent(template, theme);
            final descriptionKey = template == InvoiceTemplate.classic
                ? 'templateClassicBlurb'
                : template == InvoiceTemplate.modern
                    ? 'templateModernBlurb'
                    : 'templateMinimalBlurb';
            return GestureDetector(
              onTap: available
                  ? () {
                      setState(() {
                        _template = template;
                        _workingInvoice = _workingInvoice.copyWith(template: template);
                      });
                    }
                  : () async {
                      await widget.onRequestSignIn();
                    },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: available ? 1 : 0.45,
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? previewColor : theme.colorScheme.outlineVariant,
                      width: selected ? 2.5 : 1,
                    ),
                    gradient: LinearGradient(
                      colors: [previewColor.withOpacity(0.12), previewColor.withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: previewColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.invoiceTemplateLabel(template),
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  l10n.text(descriptionKey),
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: previewColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        width: 90,
                        decoration: BoxDecoration(
                          color: previewColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      if (!available) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.text('templatesLocked'),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context,
      {required String label, required DateTime value, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8))),
            const SizedBox(height: 4),
            Text(context.l10n.dateFormat.format(value),
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    TextAlign textAlign = TextAlign.left,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      textAlign: textAlign,
      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildOutlinedField({
    required TextEditingController controller,
    required String label,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
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

  void _updateInvoice({
    String? clientName,
    String? projectName,
    String? description,
    String? notes,
    String? number,
  }) {
    setState(() {
      _workingInvoice = _workingInvoice.copyWith(
        clientName: clientName ?? _workingInvoice.clientName,
        projectName: projectName ?? _workingInvoice.projectName,
        description: description ?? _workingInvoice.description,
        notes: notes ?? _workingInvoice.notes,
        number: number ?? _workingInvoice.number,
      );
    });
  }

  Color _templateAccent(InvoiceTemplate template, ThemeData theme) {
    switch (template) {
      case InvoiceTemplate.classic:
        return theme.colorScheme.primary;
      case InvoiceTemplate.modern:
        return theme.colorScheme.tertiary;
      case InvoiceTemplate.minimal:
        return theme.colorScheme.secondary;
    }
  }
}

class _DraftBadge extends StatelessWidget {
  const _DraftBadge({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.drafts_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('draftUnsavedLabel'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
