import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_template_spec.dart';
import '../models/user_profile.dart';

enum InvoiceEditorMode { edit, preview }

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
  late Invoice _workingInvoice;
  late InvoiceEditorMode _mode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyInvoice(widget.invoice, resetMode: true);
  }

  @override
  void didUpdateWidget(covariant InvoiceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice.id != widget.invoice.id) {
      _applyInvoice(widget.invoice, resetMode: true);
    } else if (oldWidget.isNewDraft != widget.isNewDraft && widget.isNewDraft) {
      _mode = InvoiceEditorMode.edit;
    }
  }

  void _applyInvoice(Invoice invoice, {required bool resetMode}) {
    _workingInvoice = invoice;
    if (resetMode) {
      _mode = widget.isNewDraft ? InvoiceEditorMode.edit : InvoiceEditorMode.preview;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = invoiceTemplateSpec(_workingInvoice.template);
    final isPreview = _mode == InvoiceEditorMode.preview;
    final currencyFormat = NumberFormat.currency(
      name: _workingInvoice.currencyCode,
      symbol: _workingInvoice.currencySymbol,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1080;

        Widget templateShelf;
        if (isWide) {
          templateShelf = _buildTemplateSidebar(theme, l10n);
        } else {
          templateShelf = _buildTemplateCarousel(theme, l10n);
        }

        final canvasStack = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(theme, l10n, isPreview),
            const SizedBox(height: 16),
            _buildInvoiceCanvas(context, palette, currencyFormat, isPreview),
          ],
        );

        final bodyChildren = <Widget>[
          _buildHeading(theme, l10n, isPreview),
          const SizedBox(height: 16),
        ];

        if (isWide) {
          bodyChildren.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: templateShelf),
                const SizedBox(width: 32),
                Expanded(child: canvasStack),
              ],
            ),
          );
        } else {
          bodyChildren
            ..add(templateShelf)
            ..add(const SizedBox(height: 24))
            ..add(canvasStack);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bodyChildren,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(theme, l10n, isPreview),
          ],
        );
      },
    );
  }

  Widget _buildHeading(ThemeData theme, AppLocalizations l10n, bool isPreview) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.text('invoiceFormTitle'), style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                isPreview ? l10n.text('invoicePreviewHint') : l10n.text('invoiceEditorSubtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
        if (widget.isNewDraft)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(l10n.text('draftUnsavedLabel'), style: theme.textTheme.labelMedium),
          ),
      ],
    );
  }

  Widget _buildTemplateCarousel(ThemeData theme, AppLocalizations l10n) {
    final cards = InvoiceTemplate.values
        .map((template) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(width: 240, child: _buildTemplateCard(template, theme, l10n)),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('templateFieldLabel'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: cards),
        ),
      ],
    );
  }

  Widget _buildTemplateSidebar(ThemeData theme, AppLocalizations l10n) {
    final cards = InvoiceTemplate.values
        .map((template) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTemplateCard(template, theme, l10n),
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('templateFieldLabel'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }

  Widget _buildTemplateCard(InvoiceTemplate template, ThemeData theme, AppLocalizations l10n) {
    final available = widget.availableTemplates;
    final spec = invoiceTemplateSpec(template);
    final selected = template == _workingInvoice.template;
    final enabled = available.contains(template);
    final label = l10n.text(template.labelKey);
    final blurb = l10n.text(template.blurbKey);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: !enabled
            ? null
            : () {
                setState(() {
                  _workingInvoice = _workingInvoice.copyWith(
                    template: template,
                    document: InvoiceDocument.defaults(template),
                  );
                });
              },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: _TemplatePreview(spec: spec),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text(blurb, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, AppLocalizations l10n, bool isPreview) {
    return Row(
      children: [
        SegmentedButton<InvoiceEditorMode>(
          segments: [
            ButtonSegment(
              value: InvoiceEditorMode.edit,
              icon: const Icon(Icons.design_services_outlined),
              label: Text(l10n.text('invoiceModeEdit')),
            ),
            ButtonSegment(
              value: InvoiceEditorMode.preview,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.text('invoiceModePreview')),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (value) {
            setState(() {
              _mode = value.first;
            });
          },
        ),
        const Spacer(),
        if (!isPreview)
          PopupMenuButton<InvoiceSectionType>(
            tooltip: l10n.text('invoiceAddSection'),
            onSelected: (type) => _addSection(type),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: InvoiceSectionType.notes,
                child: Text(l10n.text('invoiceAddNotesSection')),
              ),
              PopupMenuItem(
                value: InvoiceSectionType.terms,
                child: Text(l10n.text('invoiceAddTermsSection')),
              ),
              PopupMenuItem(
                value: InvoiceSectionType.advertisement,
                child: Text(l10n.text('invoiceAddAdSection')),
              ),
              PopupMenuItem(
                value: InvoiceSectionType.custom,
                child: Text(l10n.text('invoiceAddCustomSection')),
              ),
            ],
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add),
              label: Text(l10n.text('invoiceAddSection')),
            ),
          ),
      ],
    );
  }

  Widget _buildInvoiceCanvas(
    BuildContext context,
    InvoiceTemplateSpec palette,
    NumberFormat currencyFormat,
    bool isPreview,
  ) {
    return _buildGlobalCanvas(
      context,
      palette,
      currencyFormat,
      isPreview,
      showBilingualTitle: _workingInvoice.template.isJapanese,
    );
  }

  Widget _buildGlobalCanvas(
    BuildContext context,
    InvoiceTemplateSpec palette,
    NumberFormat currencyFormat,
    bool isPreview, {
    bool showBilingualTitle = false,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = _workingInvoice.document.sections;
    final headerSection = sections.firstWhere(
      (section) => section.type == InvoiceSectionType.header,
      orElse: () => InvoiceSection(
        id: 'header',
        type: InvoiceSectionType.header,
        elements: const [],
      ),
    );
    final otherSections = sections.where((section) => section != headerSection).toList();
    final total = _workingInvoice.lineItems.fold<double>(0, (sum, item) => sum + item.total);
    final dueMessage = _dueMessage(l10n, _workingInvoice.dueDate);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlobalHeaderSection(
            section: headerSection,
            palette: palette,
            invoice: _workingInvoice,
            profile: widget.profile,
            isPreview: isPreview,
            onChanged: _updateSection,
            onStatusChanged: _setStatus,
            onDueDateChanged: (date) => _setDate(binding: InvoiceFieldBinding.dueDate, date: date),
            onIssueDateChanged: (date) => _setDate(binding: InvoiceFieldBinding.issueDate, date: date),
            onLogoRequested: _changeLogo,
            showBilingualTitle: showBilingualTitle,
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoColumns(
                  invoice: _workingInvoice,
                  section: otherSections.firstWhere(
                    (section) => section.type == InvoiceSectionType.billing,
                    orElse: () => InvoiceSection(
                      id: 'billing',
                      type: InvoiceSectionType.billing,
                      elements: const [],
                    ),
                  ),
                  palette: palette,
                  isPreview: isPreview,
                  onChanged: _updateSection,
                  onDueDateChanged: (date) => _setDate(binding: InvoiceFieldBinding.dueDate, date: date),
                ),
                const SizedBox(height: 24),
                LineItemsEditor(
                  items: _workingInvoice.lineItems,
                  readOnly: isPreview,
                  currencyFormat: currencyFormat,
                  onChanged: _updateLineItem,
                  onAdd: _addLineItem,
                  onRemove: _removeLineItem,
                ),
                const SizedBox(height: 24),
                _TotalsCard(
                  totalText: currencyFormat.format(total),
                  dueMessage: dueMessage,
                  palette: palette,
                ),
                const SizedBox(height: 24),
                for (final section in otherSections)
                  if (section.type != InvoiceSectionType.billing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _SectionCard(
                        section: section,
                        palette: palette,
                        isPreview: isPreview,
                        l10n: l10n,
                        onChanged: _updateSection,
                        onRemove: section.isRemovable ? () => _removeSection(section.id) : null,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, AppLocalizations l10n, bool isPreview) {
    final canDelete = widget.onDelete != null && !widget.isNewDraft;

    FilledButton iconSaveButton() => FilledButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await widget.onSave(_workingInvoice.recalculateTotals());
                  } finally {
                    if (mounted) {
                      setState(() => _saving = false);
                    }
                  }
                },
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? l10n.text('savingLabel') : l10n.text('saveButton')),
        );

    FilledButton iconDownloadButton() => FilledButton.icon(
          onPressed: widget.isGuest
              ? () async {
                  await widget.onRequestSignIn();
                }
              : () async {
                  await widget.onDownload(_workingInvoice.recalculateTotals());
                },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(widget.isGuest ? l10n.text('downloadRequiresAccount') : l10n.text('downloadPdf')),
        );

    OutlinedButton deleteButton() => OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.text('deleteInvoiceTitle')),
                    content: Text(l10n.text('deleteInvoiceBody')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.text('notNow')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.text('deleteButton')),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (confirmed && widget.onDelete != null) {
              await widget.onDelete!(_workingInvoice);
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.text('deleteButton')),
        );

    final closeButton = TextButton(
      onPressed: widget.onClose,
      child: Text(l10n.text('closeButton')),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  iconSaveButton(),
                  iconDownloadButton(),
                  if (canDelete) deleteButton(),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: closeButton,
              ),
            ],
          );
        }

        final children = <Widget>[
          iconSaveButton(),
          const SizedBox(width: 12),
          iconDownloadButton(),
          if (canDelete) ...[
            const SizedBox(width: 12),
            deleteButton(),
          ],
          const Spacer(),
          closeButton,
        ];

        return Row(children: children);
      },
    );
  }

  void _updateSection(InvoiceSection updated) {
    setState(() {
      _workingInvoice = _workingInvoice.updateDocument(
        _workingInvoice.document.replaceSection(updated),
      );
      for (final element in updated.elements) {
        _workingInvoice = _applyBinding(_workingInvoice, element.binding, element.value);
      }
    });
  }

  void _setStatus(InvoiceStatus status) {
    setState(() {
      _workingInvoice = _workingInvoice.copyWith(status: status);
    });
  }

  void _setDate({required InvoiceFieldBinding binding, required DateTime date}) {
    setState(() {
      switch (binding) {
        case InvoiceFieldBinding.dueDate:
          _workingInvoice = _workingInvoice.copyWith(dueDate: date);
          break;
        case InvoiceFieldBinding.issueDate:
          _workingInvoice = _workingInvoice.copyWith(issueDate: date);
          break;
        default:
          break;
      }
    });
  }

  void _changeLogo() async {
    final controller = TextEditingController(text: _workingInvoice.logoUrl ?? widget.profile.logoUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.text('invoiceLogoDialogTitle')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.text('invoiceLogoDialogHint'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.text('cancelButton')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.text('applyButton')),
          ),
        ],
      ),
    );
    if (url != null) {
      setState(() {
        _workingInvoice = _workingInvoice.copyWith(logoUrl: url.isEmpty ? null : url);
      });
    }
  }

  void _addSection(InvoiceSectionType type) {
    if (type == InvoiceSectionType.advertisement &&
        _workingInvoice.document.sections.any((section) => section.type == InvoiceSectionType.advertisement)) {
      return;
    }
    final addition = InvoiceDocument.templateForAddition(type);
    setState(() {
      _workingInvoice = _workingInvoice.updateDocument(
        _workingInvoice.document.insertSection(addition),
      );
    });
  }

  void _removeSection(String sectionId) {
    setState(() {
      _workingInvoice = _workingInvoice.updateDocument(
        _workingInvoice.document.removeSection(sectionId),
      );
    });
  }

  void _addLineItem() {
    setState(() {
      final items = [..._workingInvoice.lineItems, InvoiceLineItem.empty()];
      _workingInvoice = _workingInvoice.updateLineItems(items);
    });
  }

  void _removeLineItem(String id) {
    setState(() {
      final items = _workingInvoice.lineItems.where((item) => item.id != id).toList();
      if (items.isEmpty) {
        items.add(InvoiceLineItem.empty());
      }
      _workingInvoice = _workingInvoice.updateLineItems(items);
    });
  }

  void _updateLineItem(String id, InvoiceLineItem updated) {
    setState(() {
      final items = _workingInvoice.lineItems.map((item) => item.id == id ? updated : item).toList();
      _workingInvoice = _workingInvoice.updateLineItems(items);
    });
  }

  Invoice _applyBinding(Invoice invoice, InvoiceFieldBinding binding, String value) {
    switch (binding) {
      case InvoiceFieldBinding.clientName:
        return invoice.copyWith(clientName: value);
      case InvoiceFieldBinding.projectName:
        return invoice.copyWith(projectName: value);
      case InvoiceFieldBinding.invoiceNumber:
        return invoice.copyWith(number: value);
      case InvoiceFieldBinding.notes:
        return invoice.copyWith(notes: value);
      case InvoiceFieldBinding.logoUrl:
        return invoice.copyWith(logoUrl: value);
      default:
        return invoice;
    }
  }
}

class _GlobalHeaderSection extends StatelessWidget {
  const _GlobalHeaderSection({
    required this.section,
    required this.palette,
    required this.invoice,
    required this.profile,
    required this.isPreview,
    required this.onChanged,
    required this.onStatusChanged,
    required this.onDueDateChanged,
    required this.onIssueDateChanged,
    required this.onLogoRequested,
    this.showBilingualTitle = false,
  });

  final InvoiceSection section;
  final InvoiceTemplateSpec palette;
  final Invoice invoice;
  final UserProfile profile;
  final bool isPreview;
  final ValueChanged<InvoiceSection> onChanged;
  final ValueChanged<InvoiceStatus> onStatusChanged;
  final ValueChanged<DateTime> onDueDateChanged;
  final ValueChanged<DateTime> onIssueDateChanged;
  final VoidCallback onLogoRequested;
  final bool showBilingualTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final titleElement = section.elements.firstWhere(
      (element) => element.binding == InvoiceFieldBinding.invoiceTitle,
      orElse: () => InvoiceElement(
        id: 'title',
        kind: InvoiceElementKind.text,
        binding: InvoiceFieldBinding.invoiceTitle,
        value: l10n.text('invoicePreviewTitle'),
      ),
    );
    final numberElement = section.elements.firstWhere(
      (element) => element.binding == InvoiceFieldBinding.invoiceNumber,
      orElse: () => InvoiceElement(
        id: 'number',
        kind: InvoiceElementKind.text,
        binding: InvoiceFieldBinding.invoiceNumber,
        value: invoice.number,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        gradient: palette.headerGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      profile.companyName.isEmpty ? profile.displayName : profile.companyName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: palette.headerText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (profile.tagline.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          profile.tagline,
                          style: theme.textTheme.bodyMedium?.copyWith(color: palette.tagline),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _HeaderInfoChip(
                          label: l10n.text('invoiceIssuedLabel'),
                          value: DateFormat.yMMMMd(l10n.locale.toLanguageTag()).format(invoice.issueDate),
                          onTap: isPreview
                              ? null
                              : () async {
                                  final date = await _pickDate(
                                    context,
                                    initial: invoice.issueDate,
                                  );
                                  if (date != null) {
                                    onIssueDateChanged(date);
                                  }
                                },
                        ),
                        const SizedBox(width: 12),
                        _HeaderInfoChip(
                          label: l10n.text('invoiceDueLabel'),
                          value: DateFormat.yMMMMd(l10n.locale.toLanguageTag()).format(invoice.dueDate),
                          onTap: isPreview
                              ? null
                              : () async {
                                  final date = await _pickDate(
                                    context,
                                    initial: invoice.dueDate,
                                  );
                                  if (date != null) {
                                    onDueDateChanged(date);
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _LogoPreview(
                    url: invoice.logoUrl?.isNotEmpty == true ? invoice.logoUrl! : profile.logoUrl,
                    onTap: isPreview ? null : onLogoRequested,
                  ),
                  const SizedBox(height: 12),
                  _InvoiceStatusSelector(
                    status: invoice.status,
                    isPreview: isPreview,
                    onChanged: onStatusChanged,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            showBilingualTitle ? l10n.text('invoiceJapaneseTitle') : l10n.text('invoicePreviewTitle'),
            style: theme.textTheme.titleMedium?.copyWith(color: palette.headerText, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          InlineEditableText(
            value: titleElement.value,
            placeholder: l10n.text('invoicePreviewTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(color: palette.headerText, fontWeight: FontWeight.bold),
            enabled: !isPreview,
            onSubmitted: (value) => onChanged(
              section.copyWith(
                elements: section.elements
                    .map((element) => element.id == titleElement.id ? element.copyWith(value: value) : element)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InlineEditableText(
            value: numberElement.value,
            placeholder: invoice.number,
            style: theme.textTheme.titleMedium?.copyWith(color: palette.tagline),
            enabled: !isPreview,
            onSubmitted: (value) => onChanged(
              section.copyWith(
                elements: section.elements
                    .map((element) => element.id == numberElement.id ? element.copyWith(value: value) : element)
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<DateTime?> _pickDate(BuildContext context, {required DateTime initial}) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
  }
}

class _InfoColumns extends StatelessWidget {
  const _InfoColumns({
    required this.invoice,
    required this.section,
    required this.palette,
    required this.isPreview,
    required this.onChanged,
    required this.onDueDateChanged,
  });

  final Invoice invoice;
  final InvoiceSection section;
  final InvoiceTemplateSpec palette;
  final bool isPreview;
  final ValueChanged<InvoiceSection> onChanged;
  final ValueChanged<DateTime> onDueDateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final clientElement = section.elements.firstWhere(
      (element) => element.binding == InvoiceFieldBinding.clientName,
      orElse: () => InvoiceElement(
        id: 'client',
        kind: InvoiceElementKind.text,
        binding: InvoiceFieldBinding.clientName,
        value: invoice.clientName,
      ),
    );
    final addressElement = section.elements.firstWhere(
      (element) => element.binding == InvoiceFieldBinding.clientAddress,
      orElse: () => InvoiceElement(
        id: 'client-address',
        kind: InvoiceElementKind.multiline,
        binding: InvoiceFieldBinding.clientAddress,
        value: '',
      ),
    );
    final projectElement = section.elements.firstWhere(
      (element) => element.binding == InvoiceFieldBinding.projectName,
      orElse: () => InvoiceElement(
        id: 'project',
        kind: InvoiceElementKind.text,
        binding: InvoiceFieldBinding.projectName,
        value: invoice.projectName,
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SectionCard(
            section: section.copyWith(
              elements: [clientElement, addressElement],
            ),
            palette: palette,
            isPreview: isPreview,
            l10n: l10n,
            onChanged: onChanged,
            titleOverride: l10n.text('clientDetailsTitle'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SectionCard(
            section: section.copyWith(elements: [projectElement]),
            palette: palette,
            isPreview: isPreview,
            l10n: l10n,
            onChanged: onChanged,
            titleOverride: l10n.text('projectLabel'),
          ),
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totalText,
    required this.dueMessage,
    required this.palette,
  });

  final String totalText;
  final String dueMessage;
  final InvoiceTemplateSpec palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
                  context.l10n.text('invoiceBalanceDueLabel'),
                  style: theme.textTheme.titleMedium?.copyWith(color: palette.accent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  dueMessage,
                  style: theme.textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          Text(
            totalText,
            style: theme.textTheme.headlineSmall?.copyWith(color: palette.accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.palette,
    required this.isPreview,
    required this.l10n,
    required this.onChanged,
    this.titleOverride,
    this.onRemove,
  });

  final InvoiceSection section;
  final InvoiceTemplateSpec palette;
  final bool isPreview;
  final AppLocalizations l10n;
  final ValueChanged<InvoiceSection> onChanged;
  final String? titleOverride;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titleOverride ?? _sectionTitle(section.type, l10n),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  tooltip: l10n.text('removeSectionTooltip'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final element in section.elements)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InlineEditableText(
                value: element.value,
                placeholder: element.placeholder,
                style: theme.textTheme.bodyMedium,
                enabled: !isPreview,
                multiline: element.kind == InvoiceElementKind.multiline,
                onSubmitted: (value) => onChanged(
                  section.copyWith(
                    elements: section.elements
                        .map((candidate) => candidate.id == element.id ? candidate.copyWith(value: value) : candidate)
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _sectionTitle(InvoiceSectionType type, AppLocalizations l10n) {
    switch (type) {
      case InvoiceSectionType.notes:
        return l10n.text('invoiceNotesTitle');
      case InvoiceSectionType.terms:
        return l10n.text('invoiceTermsTitle');
      case InvoiceSectionType.advertisement:
        return l10n.text('invoiceAdTitle');
      case InvoiceSectionType.custom:
        return l10n.text('invoiceCustomTitle');
      default:
        return l10n.text('invoiceSection');
    }
  }
}

class _HeaderInfoChip extends StatelessWidget {
  const _HeaderInfoChip({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimary)),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}

class _InvoiceStatusSelector extends StatelessWidget {
  const _InvoiceStatusSelector({
    required this.status,
    required this.isPreview,
    required this.onChanged,
  });

  final InvoiceStatus status;
  final bool isPreview;
  final ValueChanged<InvoiceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<InvoiceStatus>(
      enabled: !isPreview,
      tooltip: l10n.text('invoiceStatusLabel'),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final value in InvoiceStatus.values)
          PopupMenuItem(
            value: value,
            child: Text(l10n.invoiceStatusLabel(value)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(l10n.invoiceStatusLabel(status)),
          ],
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.url, this.onTap});

  final String url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
          image: url.isNotEmpty
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
        ),
        alignment: Alignment.center,
        child: url.isEmpty
            ? Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.spec});

  final InvoiceTemplateSpec spec;

  @override
  Widget build(BuildContext context) {
    Widget previewLine(double widthFactor, Color color, {double height = 6}) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: spec.border.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: spec.headerGradient,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  previewLine(0.6, spec.accent.withOpacity(0.7), height: 8),
                  const SizedBox(height: 6),
                  previewLine(0.35, spec.accent.withOpacity(0.35)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(3, (index) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: previewLine(
                                      1,
                                      spec.muted.withOpacity(0.25 + (index * 0.1)),
                                      height: 7,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  previewLine(0.2, spec.accent.withOpacity(0.4), height: 7),
                                ],
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: spec.balanceBackground.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineEditableText extends StatefulWidget {
  const InlineEditableText({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onSubmitted,
    this.enabled = true,
    this.style,
    this.multiline = false,
  });

  final String value;
  final String placeholder;
  final ValueChanged<String> onSubmitted;
  final bool enabled;
  final TextStyle? style;
  final bool multiline;

  @override
  State<InlineEditableText> createState() => _InlineEditableTextState();
}

class _InlineEditableTextState extends State<InlineEditableText> {
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant InlineEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_editing) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return FocusScope(
        child: Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              _submit();
            }
          },
          child: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: widget.multiline ? null : 1,
            textInputAction: widget.multiline ? TextInputAction.newline : TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
      );
    }

    final displayText = widget.value.isEmpty ? widget.placeholder : widget.value;
    final style = widget.value.isEmpty
        ? widget.style?.copyWith(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.outline)
        : widget.style;
    return InkWell(
      onTap: widget.enabled
          ? () {
              setState(() {
                _editing = true;
                _controller.text = widget.value;
              });
            }
          : null,
      child: Text(displayText, style: style),
    );
  }

  void _submit() {
    setState(() {
      _editing = false;
    });
    widget.onSubmitted(_controller.text.trim());
  }
}

class LineItemsEditor extends StatelessWidget {
  const LineItemsEditor({
    super.key,
    required this.items,
    required this.currencyFormat,
    required this.readOnly,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<InvoiceLineItem> items;
  final NumberFormat currencyFormat;
  final bool readOnly;
  final void Function(String id, InvoiceLineItem updated) onChanged;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.text('lineItemsTitle'), style: theme.textTheme.titleMedium),
            if (!readOnly)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(l10n.text('invoiceAddLineItem')),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: InlineEditableText(
                              value: item.description,
                              placeholder: l10n.text('invoiceLineDescriptionPlaceholder'),
                              multiline: true,
                              enabled: !readOnly,
                              onSubmitted: (value) => onChanged(
                                item.id,
                                item.copyWith(description: value.isEmpty ? l10n.text('invoiceLineDescriptionPlaceholder') : value),
                              ),
                            ),
                          ),
                          if (!readOnly)
                            IconButton(
                              onPressed: () => onRemove(item.id),
                              icon: const Icon(Icons.close),
                              tooltip: l10n.text('removeLineItem'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InlineEditableText(
                              value: item.quantity.toString(),
                              placeholder: '1',
                              enabled: !readOnly,
                              onSubmitted: (value) {
                                final qty = double.tryParse(value.replaceAll(',', '.')) ?? item.quantity;
                                onChanged(item.id, item.copyWith(quantity: qty));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InlineEditableText(
                              value: item.unitPrice.toStringAsFixed(2),
                              placeholder: currencyFormat.format(0),
                              enabled: !readOnly,
                              onSubmitted: (value) {
                                final price = double.tryParse(value.replaceAll(',', '.')) ?? item.unitPrice;
                                onChanged(item.id, item.copyWith(unitPrice: price));
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currencyFormat.format(item.total),
                              textAlign: TextAlign.end,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

String _dueMessage(AppLocalizations l10n, DateTime dueDate) {
  final now = DateTime.now();
  if (dueDate.isBefore(now)) {
    return l10n.text('invoiceDueOverdue');
  }
  final diff = dueDate.difference(now).inDays;
  return l10n.text('invoiceDueInDays').replaceAll('{days}', diff.toString());
}
