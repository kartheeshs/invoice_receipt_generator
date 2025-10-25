import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_template_spec.dart';
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
    final palette = invoiceTemplateSpec(_template);
    final currencyFormatter =
        l10n.currencyFormat(widget.invoice.currencyCode, widget.invoice.currencySymbol);
    final amountValue =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? _workingInvoice.amount;

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 960;
          final preview =
              _buildInvoicePreview(context, palette, isNarrow, currencyFormatter, amountValue);
          final formFields =
              _buildFormFields(context, palette, isNarrow, currencyFormatter, amountValue);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.text('invoiceFormTitle'), style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(l10n.text('invoiceEditorSubtitle')),
                const SizedBox(height: 16),
                _buildTemplateSelector(context),
                const SizedBox(height: 16),
                if (widget.isNewDraft)
                  _DraftBadge(message: l10n.text('draftUnsavedBody')),
                const SizedBox(height: 16),
                if (isNarrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      preview,
                      const SizedBox(height: 24),
                      formFields,
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: preview),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: formFields),
                    ],
                  ),
                const SizedBox(height: 24),
                _buildActionButtons(context),
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

  Widget _buildTemplateSelector(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('templateFieldLabel'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: InvoiceTemplate.values.map((template) {
            final palette = invoiceTemplateSpec(template);
            final available = widget.availableTemplates.contains(template);
            final selected = _template == template;
            return Opacity(
              opacity: available ? 1 : 0.4,
              child: GestureDetector(
                onTap: available
                    ? () {
                        setState(() {
                          _template = template;
                          _workingInvoice =
                              _workingInvoice.copyWith(template: template);
                        });
                      }
                    : null,
                child: Container(
                  width: 220,
                  constraints: const BoxConstraints(minHeight: 140),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? palette.accent : palette.border,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: palette.accent.withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 12),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.text(palette.labelKey),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle,
                                color: palette.accent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.text(palette.blurbKey),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.muted,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: palette.headerGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
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

  Widget _buildInvoicePreview(
    BuildContext context,
    InvoiceTemplateSpec palette,
    bool isNarrow,
    NumberFormat currencyFormatter,
    double amountValue,
  ) {
    final l10n = context.l10n;
    final project = _projectController.text.trim().isEmpty
        ? l10n.text('invoiceDefaultProject')
        : _projectController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? l10n.text('invoiceDefaultDescription')
        : _descriptionController.text.trim();
    final client = _clientController.text.trim().isEmpty
        ? l10n.text('invoiceDefaultClient')
        : _clientController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? l10n.text('invoiceDefaultNotes')
        : _notesController.text.trim();
    final statusLabel = l10n.invoiceStatusLabel(_status);
    final issueDateText = l10n.longDateFormat.format(_issueDate);
    final dueDateText = l10n.longDateFormat.format(_dueDate);
    final dueMessage = _dueMessage(l10n);

    if (palette.isJapanese) {
      return _buildJapanesePreview(
        context: context,
        palette: palette,
        currencyFormatter: currencyFormatter,
        amountValue: amountValue,
        project: project,
        description: description,
        client: client,
        notes: notes,
        statusLabel: statusLabel,
        issueDateText: issueDateText,
        dueDateText: dueDateText,
        dueMessage: dueMessage,
        l10n: l10n,
      );
    }

    return _buildGlobalPreview(
      context: context,
      palette: palette,
      isNarrow: isNarrow,
      currencyFormatter: currencyFormatter,
      amountValue: amountValue,
      project: project,
      description: description,
      client: client,
      notes: notes,
      statusLabel: statusLabel,
      issueDateText: issueDateText,
      dueDateText: dueDateText,
      dueMessage: dueMessage,
      l10n: l10n,
    );
  }

  Widget _buildGlobalPreview({
    required BuildContext context,
    required InvoiceTemplateSpec palette,
    required bool isNarrow,
    required NumberFormat currencyFormatter,
    required double amountValue,
    required String project,
    required String description,
    required String client,
    required String notes,
    required String statusLabel,
    required String issueDateText,
    required String dueDateText,
    required String dueMessage,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final amountText = currencyFormatter.format(amountValue);
    final companyName = widget.profile.companyName.isEmpty
        ? widget.profile.displayName
        : widget.profile.companyName;
    final numberText = _numberController.text.trim().isEmpty
        ? _workingInvoice.number
        : _numberController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: palette.headerGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: palette.headerText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.profile.tagline.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.profile.tagline,
                              style: theme.textTheme.titleSmall?.copyWith(color: palette.tagline),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (widget.profile.address.isNotEmpty)
                                _buildHeaderPill(context, palette, widget.profile.address),
                              if (widget.profile.phone.isNotEmpty)
                                _buildHeaderPill(context, palette, widget.profile.phone),
                              if (widget.profile.email.isNotEmpty)
                                _buildHeaderPill(context, palette, widget.profile.email),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildLogoPreview(palette),
                        const SizedBox(height: 12),
                        Text(
                          l10n.text('invoicePreviewTitle').toUpperCase(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: palette.headerText,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: palette.badgeBackground.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            numberText,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: palette.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusChip(context, palette, statusLabel),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildHeaderBadge(
                      context,
                      palette,
                      l10n.text('invoiceIssuedLabel'),
                      issueDateText,
                    ),
                    _buildHeaderBadge(
                      context,
                      palette,
                      l10n.text('invoiceDueLabel'),
                      dueDateText,
                    ),
                    _buildHeaderBadge(
                      context,
                      palette,
                      l10n.text('invoiceTimelineLabel'),
                      dueMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildInfoCard(
                      context: context,
                      palette: palette,
                      title: l10n.text('companyDetailsTitle'),
                      width: isNarrow ? double.infinity : 260,
                      children: [
                        Text(widget.profile.displayName, style: theme.textTheme.bodyLarge),
                        if (widget.profile.taxId.isNotEmpty)
                          Text(widget.profile.taxId, style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted)),
                        if (widget.profile.email.isNotEmpty)
                          Text(widget.profile.email, style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted)),
                      ],
                    ),
                    _buildInfoCard(
                      context: context,
                      palette: palette,
                      title: l10n.text('clientDetailsTitle'),
                      width: isNarrow ? double.infinity : 260,
                      children: [
                        Text(client, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 4),
                        Text(project, style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted)),
                      ],
                    ),
                    _buildInfoCard(
                      context: context,
                      palette: palette,
                      title: l10n.text('invoiceMetaTitle'),
                      width: isNarrow ? double.infinity : 260,
                      children: [
                        Text('${l10n.text('invoiceIssuedLabel')}: $issueDateText'),
                        Text('${l10n.text('invoiceDueLabel')}: $dueDateText'),
                        Text('${l10n.text('statusLabel')}: $statusLabel'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildSummaryTable(
                  context,
                  palette,
                  currencyFormatter,
                  amountValue,
                  project,
                  description,
                  l10n,
                ),
                const SizedBox(height: 24),
                _buildBalanceCard(
                  context,
                  palette,
                  amountText,
                  dueMessage,
                  l10n,
                ),
                const SizedBox(height: 24),
                _buildNotesCard(context, palette, notes, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJapanesePreview({
    required BuildContext context,
    required InvoiceTemplateSpec palette,
    required NumberFormat currencyFormatter,
    required double amountValue,
    required String project,
    required String description,
    required String client,
    required String notes,
    required String statusLabel,
    required String issueDateText,
    required String dueDateText,
    required String dueMessage,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final amountText = currencyFormatter.format(amountValue);
    final companyName = widget.profile.companyName.isEmpty
        ? widget.profile.displayName
        : widget.profile.companyName;
    final numberText = _numberController.text.trim().isEmpty
        ? _workingInvoice.number
        : _numberController.text.trim();
    final suffix = l10n.text('invoiceJapaneseBillTo');
    final recipient = client.endsWith(suffix) ? client : '$client$suffix';

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: palette.headerGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: palette.headerText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.profile.tagline.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.profile.tagline,
                          style: theme.textTheme.bodyLarge?.copyWith(color: palette.tagline),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (widget.profile.address.isNotEmpty)
                            _buildHeaderPill(context, palette, widget.profile.address),
                          if (widget.profile.phone.isNotEmpty)
                            _buildHeaderPill(context, palette, widget.profile.phone),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildLogoPreview(palette),
                    const SizedBox(height: 12),
                    Text(
                      l10n.text('invoiceJapaneseTitle'),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: palette.headerText,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusChip(context, palette, statusLabel),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(24),
                    color: palette.badgeBackground.withOpacity(0.6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipient,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.profile.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.border),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.4),
                      1: FlexColumnWidth(2.4),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _japaneseMetaRow(context, palette, l10n.text('invoiceJapaneseProjectLabel'), project),
                      _japaneseMetaRow(context, palette, l10n.text('invoiceJapaneseNumberLabel'), numberText),
                      _japaneseMetaRow(context, palette, l10n.text('invoiceJapaneseIssueLabel'), issueDateText),
                      _japaneseMetaRow(context, palette, l10n.text('invoiceJapaneseDueLabel'), dueDateText),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildJapaneseAmountCard(context, palette, amountText, dueMessage, l10n),
                const SizedBox(height: 20),
                _buildJapaneseDescriptionCard(context, palette, l10n.text('invoiceJapaneseDescriptionLabel'), description),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildJapaneseNotesCard(context, palette, l10n.text('invoiceJapaneseNotes'), notes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _japaneseMetaRow(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return TableRow(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: palette.border, width: 0.6))),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          color: palette.badgeBackground.withOpacity(0.6),
          child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildJapaneseAmountCard(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String amountText,
    String dueMessage,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        color: palette.balanceBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('invoiceJapaneseAmountLabel'),
            style: theme.textTheme.titleMedium?.copyWith(color: palette.accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            amountText,
            style: theme.textTheme.headlineSmall?.copyWith(color: palette.accent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(dueMessage, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
        ],
      ),
    );
  }

  Widget _buildJapaneseDescriptionCard(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildJapaneseNotesCard(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.badgeBackground.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.muted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: palette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String text,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: palette.badgeBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(color: palette.headerText),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String label,
  ) {
    final theme = Theme.of(context);
    final color = _statusColor(theme, palette);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: palette.headerText,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, InvoiceTemplateSpec palette) {
    switch (_status) {
      case InvoiceStatus.draft:
        return palette.headerText.withOpacity(0.85);
      case InvoiceStatus.sent:
        return palette.accent;
      case InvoiceStatus.paid:
        return theme.colorScheme.tertiary;
      case InvoiceStatus.overdue:
        return theme.colorScheme.error;
    }
  }

  Widget _buildLogoPreview(InvoiceTemplateSpec palette) {
    final logoUrl = widget.profile.logoUrl.trim();
    if (logoUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        logoUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _logoFallback(palette),
      ),
    );
  }

  Widget _logoFallback(InvoiceTemplateSpec palette) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.badgeBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white70),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required InvoiceTemplateSpec palette,
    required String title,
    required List<Widget> children,
    double? width,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTable(
    BuildContext context,
    InvoiceTemplateSpec palette,
    NumberFormat currencyFormatter,
    double amountValue,
    String project,
    String description,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final amountText = currencyFormatter.format(amountValue);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.border),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.badgeBackground.withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.text('invoiceSummaryDescription'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.text('invoiceSummaryPrice'),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelLarge?.copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.text('invoiceSummaryQty'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    l10n.text('invoiceSummaryAmount'),
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelLarge?.copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(amountText, textAlign: TextAlign.right, style: theme.textTheme.bodyMedium),
                    ),
                    const Expanded(
                      flex: 1,
                      child: Text('1', textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        amountText,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: palette.border),
                const SizedBox(height: 12),
                _buildSummaryTotalRow(
                  context,
                  l10n.text('invoiceSummarySubtotal'),
                  amountText,
                  palette,
                ),
                const SizedBox(height: 8),
                _buildSummaryTotalRow(
                  context,
                  l10n.text('invoiceSummaryTotal'),
                  amountText,
                  palette,
                  emphasized: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTotalRow(
    BuildContext context,
    String label,
    String value,
    InvoiceTemplateSpec palette, {
    bool emphasized = false,
  }) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String amountText,
    String dueMessage,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: palette.balanceBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('invoiceBalanceDueLabel'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.headerText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueMessage,
                  style: theme.textTheme.bodySmall?.copyWith(color: palette.headerText.withOpacity(0.8)),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text('invoiceBalanceFooter'),
                  style: theme.textTheme.bodySmall?.copyWith(color: palette.headerText.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: palette.headerText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(
    BuildContext context,
    InvoiceTemplateSpec palette,
    String notes,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.text('invoiceNotesTitle'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(notes, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    InvoiceTemplateSpec palette,
    bool isNarrow,
    NumberFormat currencyFormatter,
    double amountValue,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final amountText = currencyFormatter.format(amountValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formCard(
          context,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.text('invoiceMetaTitle'), style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _buildOutlinedField(
                controller: _numberController,
                label: l10n.text('invoiceNumberLabel'),
                onChanged: (value) => _updateInvoice(number: value.trim()),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: isNarrow ? double.infinity : 220,
                    child: _buildDateField(
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
                  ),
                  SizedBox(
                    width: isNarrow ? double.infinity : 220,
                    child: _buildDateField(
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
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _formCard(
          context,
          Column(
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
        const SizedBox(height: 20),
        _formCard(
          context,
          Column(
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
        const SizedBox(height: 20),
        _formCard(
          context,
          Column(
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: palette.badgeBackground.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.text('invoiceBalanceDueLabel'),
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(amountText, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formCard(BuildContext context, Widget child) {
    final theme = Theme.of(context);
    final borderColor = _surfaceStrokeColor(theme);
    final shadowColor = _surfaceShadowColor(theme);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
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
    );
  }

  String _dueMessage(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = _dueDate.difference(today).inDays;
    if (difference > 0) {
      return l10n.textWithReplacement('invoiceDueInDays', {'days': difference.toString()});
    }
    if (difference == 0) {
      return l10n.text('invoiceDueToday');
    }
    return l10n.textWithReplacement('invoiceOverdueInDays', {'days': difference.abs().toString()});
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime value,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: _surfaceStrokeColor(theme)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(context.l10n.dateFormat.format(value), style: theme.textTheme.titleMedium),
          ],
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
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }

  Color _surfaceStrokeColor(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final overlay = theme.colorScheme.outlineVariant.withOpacity(isDark ? 0.55 : 0.35);
    return Color.alphaBlend(overlay, theme.colorScheme.surface);
  }

  Color _surfaceShadowColor(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Colors.black.withOpacity(isDark ? 0.35 : 0.08);
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
