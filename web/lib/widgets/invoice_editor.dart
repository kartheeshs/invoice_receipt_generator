import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_template_spec.dart';
import '../models/user_profile.dart';
import '../utils/logo_picker.dart';

enum InvoiceEditorMode { edit, preview, history }

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
    required this.hasHistoryAccess,
  });

  final Invoice invoice;
  final UserProfile profile;
  final List<InvoiceTemplate> availableTemplates;
  final bool isNewDraft;
  final bool isGuest;
  final bool hasHistoryAccess;
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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = invoiceTemplateSpec(_workingInvoice.template);
    final isPreview = _mode == InvoiceEditorMode.preview;
    final isHistory = _mode == InvoiceEditorMode.history;
    final showEditor = !isHistory;
    final currencyFormat = NumberFormat.currency(
      name: _workingInvoice.currencyCode,
      symbol: _workingInvoice.currencySymbol,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1080;
        Widget? templateShelf;
        if (showEditor) {
          templateShelf = isWide
              ? _buildTemplateSidebar(theme, l10n)
              : _buildTemplateCarousel(theme, l10n);
        }

        final canvasStack = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(theme, l10n),
            const SizedBox(height: 20),
            if (isHistory)
              _buildHistoryTimeline(theme, l10n)
            else ...[
              _buildInvoiceCanvas(context, palette, currencyFormat, isPreview),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: _buildActionButtons(l10n),
              ),
            ],
          ],
        );

        final contentChildren = <Widget>[
          _buildHeading(theme, l10n, _mode),
          const SizedBox(height: 20),
        ];

        if (isWide) {
          if (showEditor && templateShelf != null) {
            contentChildren.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 300, child: templateShelf),
                  const SizedBox(width: 32),
                  Expanded(child: canvasStack),
                ],
              ),
            );
          } else {
            contentChildren.add(canvasStack);
          }
        } else {
          if (showEditor && templateShelf != null) {
            contentChildren.addAll([
              templateShelf,
              const SizedBox(height: 24),
              canvasStack,
            ]);
          } else {
            contentChildren.add(canvasStack);
          }
        }

        contentChildren.add(const SizedBox(height: 48));

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentChildren,
        );

        return Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 48),
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildHeading(
    ThemeData theme,
    AppLocalizations l10n,
    InvoiceEditorMode mode,
  ) {
    String subtitle;
    switch (mode) {
      case InvoiceEditorMode.edit:
        subtitle = l10n.text('invoiceEditorSubtitle');
        break;
      case InvoiceEditorMode.preview:
        subtitle = l10n.text('invoicePreviewHint');
        break;
      case InvoiceEditorMode.history:
        subtitle = l10n.text('invoiceHistoryTitle');
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.text('invoiceFormTitle'), style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
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

  Widget _buildToolbar(ThemeData theme, AppLocalizations l10n) {
    final isPreview = _mode == InvoiceEditorMode.preview;
    final isHistory = _mode == InvoiceEditorMode.history;
    final modePicker = SegmentedButton<InvoiceEditorMode>(
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
        ButtonSegment(
          value: InvoiceEditorMode.history,
          icon: const Icon(Icons.history),
          label: Text(l10n.text('invoiceHistoryTitle')),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (value) {
        setState(() {
          _mode = value.first;
        });
      },
    );

    final addSectionButton = (!isPreview && !isHistory)
        ? PopupMenuButton<InvoiceSectionType>(
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
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        final toolbarControls = <Widget>[
          modePicker,
          if (addSectionButton != null) ...[
            const SizedBox(width: 12),
            addSectionButton,
          ],
        ];

        if (isNarrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: toolbarControls,
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: toolbarControls,
        );
      },
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

  Widget _buildHistoryTimeline(ThemeData theme, AppLocalizations l10n) {
    final revisions = widget.invoice.revisions;
    final subtitle = l10n
        .text('invoiceHistorySubtitle')
        .replaceAll('{count}', revisions.length.toString());
    final dateFormat = DateFormat.yMMMd(l10n.locale.toLanguageTag());
    final timeFormat = DateFormat.Hm(l10n.locale.toLanguageTag());

    Widget body;
    if (!widget.hasHistoryAccess) {
      body = _HistoryTimelineMessage(text: l10n.text('invoiceHistoryPremiumHint'));
    } else if (revisions.isEmpty) {
      body = _HistoryTimelineMessage(text: l10n.text('invoiceHistoryEmpty'));
    } else {
      body = ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: revisions.length,
        separatorBuilder: (_, __) => const Divider(height: 20),
        itemBuilder: (context, index) {
          final revision = revisions[index];
          return _HistoryTimelineEntry(
            revision: revision,
            dateFormat: dateFormat,
            timeFormat: timeFormat,
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.text('invoiceHistoryTitle'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          body,
        ],
      ),
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
    final billingSection = otherSections.firstWhere(
      (section) => section.type == InvoiceSectionType.billing,
      orElse: () => InvoiceSection(
        id: 'billing',
        type: InvoiceSectionType.billing,
        elements: const [],
      ),
    );
    final totalsSection = otherSections.firstWhere(
      (section) => section.type == InvoiceSectionType.totals,
      orElse: () => InvoiceSection(
        id: 'totals',
        type: InvoiceSectionType.totals,
        elements: const [],
      ),
    );
    final filteredSections = otherSections
        .where((section) =>
            section.id != billingSection.id &&
            section.id != totalsSection.id &&
            section.type != InvoiceSectionType.lineItems)
        .toList();

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
                  section: billingSection,
                  palette: palette,
                  isPreview: isPreview,
                  onChanged: _updateSection,
                  onDueDateChanged: (date) =>
                      _setDate(binding: InvoiceFieldBinding.dueDate, date: date),
                  profile: widget.profile,
                ),
                const SizedBox(height: 24),
                LineItemsEditor(
                  items: _workingInvoice.lineItems,
                  readOnly: isPreview,
                  currencyFormat: currencyFormat,
                  palette: palette,
                  onChanged: _updateLineItem,
                  onAdd: _addLineItem,
                  onRemove: _removeLineItem,
                ),
                const SizedBox(height: 24),
                _TotalsCard(
                  totalText: currencyFormat.format(total),
                  dueMessage: dueMessage,
                  palette: palette,
                  metadata: totalsSection.metadata,
                  showThankYou: palette.showThankYou,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
                for (final section in filteredSections)
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

  Widget _buildActionButtons(AppLocalizations l10n) {
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

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        iconSaveButton(),
        iconDownloadButton(),
        if (canDelete) deleteButton(),
        closeButton,
      ],
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
    if (kIsWeb) {
      try {
        final dataUrl = await pickLogoDataUrl();
        if (!mounted || dataUrl == null || dataUrl.isEmpty) {
          return;
        }
        setState(() {
          _workingInvoice = _workingInvoice.copyWith(logoUrl: dataUrl);
        });
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.text('invoiceLogoUploadFailed'))),
        );
      }
      return;
    }

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

class _HistoryTimelineEntry extends StatelessWidget {
  const _HistoryTimelineEntry({
    required this.revision,
    required this.dateFormat,
    required this.timeFormat,
  });

  final InvoiceRevision revision;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = '${dateFormat.format(revision.timestamp)} · ${timeFormat.format(revision.timestamp)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                revision.summary,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$timestamp • ${revision.editor}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _HistoryTimelineMessage extends StatelessWidget {
  const _HistoryTimelineMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
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
    final layout = section.metadata['layout'] as String? ?? palette.headerLayout;

    Widget buildTitleBlock(Color textColor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showBilingualTitle ? l10n.text('invoiceJapaneseTitle') : l10n.text('invoicePreviewTitle'),
            style: theme.textTheme.titleMedium?.copyWith(color: textColor.withOpacity(0.85), letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          InlineEditableText(
            value: titleElement.value,
            placeholder: l10n.text('invoicePreviewTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
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
            style: theme.textTheme.titleMedium?.copyWith(color: textColor.withOpacity(0.7)),
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
      );
    }

    Widget buildDateChips(Color labelColor, Color valueColor) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _HeaderInfoChip(
            label: l10n.text('invoiceIssuedLabel'),
            value: DateFormat.yMMMMd(l10n.locale.toLanguageTag()).format(invoice.issueDate),
            onTap: isPreview
                ? null
                : () async {
                    final date = await _pickDate(context, initial: invoice.issueDate);
                    if (date != null) {
                      onIssueDateChanged(date);
                    }
                  },
          ),
          _HeaderInfoChip(
            label: l10n.text('invoiceDueLabel'),
            value: DateFormat.yMMMMd(l10n.locale.toLanguageTag()).format(invoice.dueDate),
            onTap: isPreview
                ? null
                : () async {
                    final date = await _pickDate(context, initial: invoice.dueDate);
                    if (date != null) {
                      onDueDateChanged(date);
                    }
                  },
          ),
        ],
      );
    }

    Widget buildLogoAndStatus() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _LogoPreview(
            url: invoice.logoUrl?.isNotEmpty == true
                ? invoice.logoUrl
                : (profile.logoUrl.isNotEmpty ? profile.logoUrl : null),
            onTap: isPreview ? null : onLogoRequested,
          ),
          const SizedBox(height: 12),
          _InvoiceStatusSelector(
            status: invoice.status,
            isPreview: isPreview,
            onChanged: onStatusChanged,
          ),
        ],
      );
    }

    Widget buildCompanyBlock({required Color textColor, bool accentTagline = true}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.companyName.isEmpty ? profile.displayName : profile.companyName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (profile.tagline.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                profile.tagline,
                style: theme.textTheme.bodyMedium?.copyWith(color: accentTagline ? palette.tagline : textColor.withOpacity(0.7)),
              ),
            ),
        ],
      );
    }

    Widget waveHeader() {
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
                      buildCompanyBlock(textColor: palette.headerText),
                      const SizedBox(height: 18),
                      buildDateChips(palette.headerText, palette.headerText),
                    ],
                  ),
                ),
                buildLogoAndStatus(),
              ],
            ),
            const SizedBox(height: 20),
            buildTitleBlock(palette.headerText),
          ],
        ),
      );
    }

    Widget emeraldHeader() {
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
                      buildCompanyBlock(textColor: palette.headerText),
                      const SizedBox(height: 16),
                      buildDateChips(palette.headerText, palette.headerText),
                    ],
                  ),
                ),
                buildLogoAndStatus(),
              ],
            ),
            const SizedBox(height: 24),
            buildTitleBlock(palette.headerText),
          ],
        ),
      );
    }

    Widget slateHeader() {
      return Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.border.withOpacity(0.6)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: buildTitleBlock(theme.colorScheme.onSurface)),
                const SizedBox(width: 24),
                buildLogoAndStatus(),
              ],
            ),
            const SizedBox(height: 16),
            buildDateChips(theme.colorScheme.onSurfaceVariant, theme.colorScheme.onSurfaceVariant),
          ],
        ),
      );
    }

    Widget outlineHeader() {
      return Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.border, width: 1.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: buildTitleBlock(theme.colorScheme.onSurface)),
                buildLogoAndStatus(),
              ],
            ),
          ],
        ),
      );
    }

    Widget monochromeHeader() {
      return Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: palette.border.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildCompanyBlock(textColor: palette.headerText, accentTagline: false),
                    const SizedBox(height: 16),
                    buildDateChips(palette.headerText, palette.headerText),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTitleBlock(theme.colorScheme.onSurface),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24, top: 24),
              child: buildLogoAndStatus(),
            ),
          ],
        ),
      );
    }

    Widget spotlightHeader() {
      return Container(
        decoration: BoxDecoration(
          gradient: palette.headerGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 720;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildCompanyBlock(textColor: palette.headerText),
                          const SizedBox(height: 18),
                          buildTitleBlock(palette.headerText),
                        ],
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 28),
                      buildLogoAndStatus(),
                    ],
                  ],
                ),
                if (isCompact) ...[
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft, child: buildLogoAndStatus()),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: palette.headerText.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: buildDateChips(palette.headerText, palette.headerText),
                ),
              ],
            );
          },
        ),
      );
    }

    Widget pillarHeader() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          if (isCompact) {
            return Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: palette.border.withOpacity(0.6)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: palette.headerGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildCompanyBlock(textColor: palette.headerText),
                        const SizedBox(height: 16),
                        buildDateChips(palette.headerText, palette.headerText),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildTitleBlock(theme.colorScheme.onSurface),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerRight, child: buildLogoAndStatus()),
                ],
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: palette.border.withOpacity(0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    gradient: palette.headerGradient,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCompanyBlock(textColor: palette.headerText),
                      const SizedBox(height: 20),
                      buildDateChips(palette.headerText, palette.headerText),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTitleBlock(theme.colorScheme.onSurface),
                        const SizedBox(height: 20),
                        Align(alignment: Alignment.topRight, child: buildLogoAndStatus()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    Widget bannerHeader() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          Widget companyAndDates() {
            final company = buildCompanyBlock(textColor: theme.colorScheme.onSurface);
            final dates = buildDateChips(
              theme.colorScheme.onSurfaceVariant,
              theme.colorScheme.onSurfaceVariant,
            );
            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  company,
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft, child: dates),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: company),
                const SizedBox(width: 24),
                Flexible(child: Align(alignment: Alignment.topRight, child: dates)),
              ],
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: palette.border.withOpacity(0.8)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: palette.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: buildTitleBlock(theme.colorScheme.onSurface)),
                      const SizedBox(width: 24),
                      buildLogoAndStatus(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                companyAndDates(),
              ],
            ),
          );
        },
      );
    }

    Widget serviceHeader() {
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
                Expanded(child: buildCompanyBlock(textColor: palette.headerText)),
                buildLogoAndStatus(),
              ],
            ),
            const SizedBox(height: 16),
            buildTitleBlock(palette.headerText),
            const SizedBox(height: 12),
            buildDateChips(palette.headerText, palette.headerText),
          ],
        ),
      );
    }

    switch (layout) {
      case 'spotlight':
        return spotlightHeader();
      case 'pillar':
        return pillarHeader();
      case 'banner':
        return bannerHeader();
      case 'emerald':
        return emeraldHeader();
      case 'slate':
        return slateHeader();
      case 'outline':
        return outlineHeader();
      case 'monochrome':
        return monochromeHeader();
      case 'service':
        return serviceHeader();
      case 'japanese':
        return waveHeader();
      default:
        return waveHeader();
    }
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
    required this.profile,
  });

  final Invoice invoice;
  final InvoiceSection section;
  final InvoiceTemplateSpec palette;
  final bool isPreview;
  final ValueChanged<InvoiceSection> onChanged;
  final ValueChanged<DateTime> onDueDateChanged;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final layout = section.metadata['layout'] as String? ?? palette.infoLayout;

    InvoiceElement _element({
      required InvoiceFieldBinding binding,
      required InvoiceElementKind kind,
      String? labelKey,
      String? value,
      String placeholder = '',
    }) {
      final existing = section.elements.firstWhere(
        (element) => element.binding == binding,
        orElse: () => InvoiceElement(
          id: 'info-${binding.name}',
          kind: kind,
          binding: binding,
          labelKey: labelKey,
          value: value ?? '',
          placeholder: placeholder,
        ),
      );
      return existing;
    }

    final fallbackCompanyName =
        profile.companyName.isNotEmpty ? profile.companyName : profile.displayName;
    final clientElement = _element(
      binding: InvoiceFieldBinding.clientName,
      kind: InvoiceElementKind.text,
      value: invoice.clientName,
      placeholder: l10n.text('billToLabel'),
    );
    final clientAddress = _element(
      binding: InvoiceFieldBinding.clientAddress,
      kind: InvoiceElementKind.multiline,
    );
    final clientCompany = _element(
      binding: InvoiceFieldBinding.clientCompany,
      kind: InvoiceElementKind.text,
    );
    final projectElement = _element(
      binding: InvoiceFieldBinding.projectName,
      kind: InvoiceElementKind.text,
      value: invoice.projectName,
    );
    final companyName = _element(
      binding: InvoiceFieldBinding.companyName,
      kind: InvoiceElementKind.text,
      value: fallbackCompanyName,
    );
    final companyAddress = _element(
      binding: InvoiceFieldBinding.companyAddress,
      kind: InvoiceElementKind.multiline,
      value: profile.address,
    );
    final dueDate = _element(
      binding: InvoiceFieldBinding.dueDate,
      kind: InvoiceElementKind.date,
    );

    List<InvoiceElement> _updatedElements(InvoiceElement element, String value) {
      final exists = section.elements.any((candidate) => candidate.id == element.id);
      final updated = element.copyWith(value: value);
      if (exists) {
        return section.elements
            .map((candidate) => candidate.id == element.id ? updated : candidate)
            .toList();
      }
      return [...section.elements, updated];
    }

    void updateElement(InvoiceElement element, String value) {
      onChanged(section.copyWith(elements: _updatedElements(element, value)));
    }

    InlineEditableText _editable(
      InvoiceElement element, {
      bool multiline = false,
      TextStyle? style,
    }) {
      return InlineEditableText(
        value: element.value,
        placeholder: element.placeholder,
        style: style ?? theme.textTheme.bodyMedium,
        multiline: multiline,
        enabled: !isPreview,
        onSubmitted: (value) => updateElement(element, value),
      );
    }

    Widget _buildCard(String title, List<Widget> children) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border.withOpacity(0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
    }

    Widget buildDefault() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCard(
              l10n.text('clientDetailsTitle'),
              [
                _editable(clientElement),
                const SizedBox(height: 8),
                _editable(clientAddress, multiline: true),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCard(
              l10n.text('projectLabel'),
              [
                _editable(projectElement),
                const SizedBox(height: 8),
                _editable(dueDate, style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted)),
              ],
            ),
          ),
        ],
      );
    }

    switch (layout) {
      case 'splitCompany':
      case 'dualCard':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCard(
                l10n.text('clientDetailsTitle'),
                [
                  if (clientCompany.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _editable(clientCompany),
                    ),
                  _editable(clientElement),
                  const SizedBox(height: 8),
                  _editable(clientAddress, multiline: true),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCard(
                l10n.text('companyDetailsTitle'),
                [
                  _editable(companyName),
                  const SizedBox(height: 8),
                  _editable(companyAddress, multiline: true),
                  const SizedBox(height: 8),
                  _editable(dueDate, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
                ],
              ),
            ),
          ],
        );
      case 'ledger':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _editable(clientElement),
              const Divider(height: 18),
              _editable(clientAddress, multiline: true),
              const Divider(height: 18),
              _editable(companyName),
              const Divider(height: 18),
              _editable(companyAddress, multiline: true),
            ],
          ),
        );
      case 'spotlightGrid':
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 960.0;
            final columns = availableWidth >= 1080
                ? 3
                : availableWidth >= 720
                    ? 2
                    : 1;
            const spacing = 20.0;
            final rawWidth = columns == 1
                ? availableWidth
                : (availableWidth - spacing * (columns - 1)) / columns;
            final cardWidth = columns == 1
                ? math.min(rawWidth, 420.0)
                : math.max(260.0, rawWidth);

            Widget clientCard() => _buildCard(l10n.text('clientDetailsTitle'), [
                  if (clientCompany.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _editable(clientCompany),
                    ),
                  _editable(clientElement),
                  const SizedBox(height: 8),
                  _editable(clientAddress, multiline: true),
                ]);

            Widget companyCard() => _buildCard(l10n.text('companyDetailsTitle'), [
                  _editable(companyName),
                  const SizedBox(height: 8),
                  _editable(companyAddress, multiline: true),
                ]);

            Widget projectCard() => _buildCard(l10n.text('projectLabel'), [
                  _editable(projectElement),
                  const SizedBox(height: 8),
                  _editable(dueDate, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
                ]);

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(width: cardWidth, child: clientCard()),
                SizedBox(width: cardWidth, child: companyCard()),
                SizedBox(width: cardWidth, child: projectCard()),
              ],
            );
          },
        );
      case 'cardGrid':
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 280,
              child: _buildCard(l10n.text('clientDetailsTitle'), [
                _editable(clientElement),
                const SizedBox(height: 8),
                _editable(clientAddress, multiline: true),
              ]),
            ),
            SizedBox(
              width: 280,
              child: _buildCard(l10n.text('projectLabel'), [
                _editable(projectElement),
                const SizedBox(height: 8),
                _editable(dueDate, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
              ]),
            ),
          ],
        );
      case 'sidebarLedger':
        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = !constraints.hasBoundedWidth || constraints.maxWidth < 760;

            Widget clientCard() => _buildCard(l10n.text('clientDetailsTitle'), [
                  if (clientCompany.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _editable(clientCompany),
                    ),
                  _editable(clientElement),
                  const SizedBox(height: 8),
                  _editable(clientAddress, multiline: true),
                ]);

            Widget companyCard() => _buildCard(l10n.text('companyDetailsTitle'), [
                  _editable(companyName),
                  const SizedBox(height: 8),
                  _editable(companyAddress, multiline: true),
                ]);

            Widget projectCard() => _buildCard(l10n.text('projectLabel'), [
                  _editable(projectElement),
                  const SizedBox(height: 8),
                  _editable(dueDate, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
                ]);

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  clientCard(),
                  const SizedBox(height: 16),
                  companyCard(),
                  const SizedBox(height: 16),
                  projectCard(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: clientCard()),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      companyCard(),
                      const SizedBox(height: 16),
                      projectCard(),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      case 'tallColumns':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.text('clientDetailsTitle'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _editable(clientElement),
                  const SizedBox(height: 8),
                  _editable(clientAddress, multiline: true),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.text('companyDetailsTitle'), style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _editable(companyName),
                  const SizedBox(height: 8),
                  _editable(companyAddress, multiline: true),
                ],
              ),
            ),
          ],
        );
      default:
        return buildDefault();
    }
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totalText,
    required this.dueMessage,
    required this.palette,
    required this.metadata,
    required this.showThankYou,
    required this.l10n,
  });

  final String totalText;
  final String dueMessage;
  final InvoiceTemplateSpec palette;
  final Map<String, dynamic> metadata;
  final bool showThankYou;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = metadata['layout'] as String? ?? palette.totalsStyle;

    switch (layout) {
      case 'summaryPill':
        return Container(
          decoration: BoxDecoration(
            gradient: palette.headerGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(height: 6),
                    Text(
                      dueMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.headerText.withOpacity(0.85),
                      ),
                    ),
                    if (showThankYou)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l10n.text('invoiceThankYou'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.headerText.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  totalText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: palette.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      case 'table':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border.withOpacity(0.8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.text('invoiceBalanceDueLabel'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(dueMessage, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
                  ],
                ),
              ),
              Text(
                totalText,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      case 'underline':
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: palette.border, width: 1.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(dueMessage, style: theme.textTheme.bodyMedium),
              ),
              Text(
                totalText,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      case 'sidePanel':
        return Container(
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.text('invoiceBalanceDueLabel'),
                      style: theme.textTheme.titleMedium?.copyWith(color: palette.headerText),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dueMessage,
                      style: theme.textTheme.bodySmall?.copyWith(color: palette.tagline),
                    ),
                    if (showThankYou)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          l10n.text('invoiceThankYou'),
                          style: theme.textTheme.bodyMedium?.copyWith(color: palette.headerText, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                totalText,
                style: theme.textTheme.headlineMedium?.copyWith(color: palette.headerText, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      case 'stacked':
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.balanceBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.text('invoiceBalanceDueLabel'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: palette.accent)),
              const SizedBox(height: 8),
              Text(totalText, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: palette.accent)),
              const SizedBox(height: 10),
              Text(dueMessage, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
              if (showThankYou)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.text('invoiceThankYou'),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: palette.muted),
                  ),
                ),
            ],
          ),
        );
      case 'japaneseTotals':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: palette.balanceBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(dueMessage, style: theme.textTheme.bodySmall?.copyWith(color: palette.muted)),
              const SizedBox(height: 6),
              Text(totalText, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );
      default:
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
                      l10n.text('invoiceBalanceDueLabel'),
                      style: theme.textTheme.titleMedium?.copyWith(color: palette.accent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dueMessage,
                      style: theme.textTheme.bodySmall?.copyWith(color: palette.muted),
                    ),
                    if (showThankYou)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          l10n.text('invoiceThankYou'),
                          style: theme.textTheme.bodyMedium?.copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                        ),
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
    final layout = section.metadata['layout'] as String?;
    Color background = palette.surface;
    BorderRadius radius = BorderRadius.circular(20);
    Border border = Border.all(color: palette.border);
    List<BoxShadow>? shadows;
    String title = titleOverride ?? _sectionTitle(section.type, l10n);

    switch (layout) {
      case 'thankYou':
        background = palette.highlight?.withOpacity(0.12) ?? palette.accent.withOpacity(0.08);
        border = Border.all(color: palette.accent.withOpacity(0.5));
        title = l10n.text('invoiceThankYou');
        break;
      case 'notesBox':
        border = Border.all(color: palette.border.withOpacity(0.7));
        background = palette.surface;
        radius = BorderRadius.circular(16);
        break;
      case 'remarks':
        background = palette.surface;
        border = Border.all(color: palette.border.withOpacity(0.5));
        break;
      default:
        shadows = [
          BoxShadow(
            color: palette.accent.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: border,
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
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
  const _LogoPreview({this.url, this.onTap});

  final String? url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLogo = url != null && url!.isNotEmpty;

    ImageProvider? provider;
    if (hasLogo) {
      try {
        if (url!.startsWith('data:')) {
          final data = Uri.parse(url!).data;
          if (data != null) {
            provider = MemoryImage(data.contentAsBytes());
          }
        } else {
          provider = NetworkImage(url!);
        }
      } catch (_) {
        provider = null;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
          image: provider != null
              ? DecorationImage(image: provider, fit: BoxFit.cover)
              : null,
        ),
        alignment: Alignment.center,
        child: !hasLogo || provider == null
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final width = (maxWidth.isFinite ? maxWidth : 120.0) * widthFactor;

          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
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
    required this.palette,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final List<InvoiceLineItem> items;
  final NumberFormat currencyFormat;
  final bool readOnly;
  final InvoiceTemplateSpec palette;
  final void Function(String id, InvoiceLineItem updated) onChanged;
  final VoidCallback onAdd;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final columns = palette.lineItemColumns;
    final style = palette.lineItemStyle;
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
        _LineItemHeader(columns: columns, palette: palette),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var index = 0; index < items.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LineItemRow(
                  item: items[index],
                  palette: palette,
                  theme: theme,
                  l10n: l10n,
                  currencyFormat: currencyFormat,
                  readOnly: readOnly,
                  style: style,
                  index: index,
                  onChanged: onChanged,
                  onRemove: onRemove,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LineItemHeader extends StatelessWidget {
  const _LineItemHeader({required this.columns, required this.palette});

  final List<String> columns;
  final InvoiceTemplateSpec palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = columns.length >= 4
        ? columns
        : <String>['Description', 'Qty', 'Rate', 'Amount'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: palette.tableHeader,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              labels[0],
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.tableHeaderText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              labels[1],
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.tableHeaderText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              labels[2],
              style: theme.textTheme.labelLarge?.copyWith(
                color: palette.tableHeaderText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                labels[3],
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.tableHeaderText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.item,
    required this.palette,
    required this.theme,
    required this.l10n,
    required this.currencyFormat,
    required this.readOnly,
    required this.style,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final InvoiceLineItem item;
  final InvoiceTemplateSpec palette;
  final ThemeData theme;
  final AppLocalizations l10n;
  final NumberFormat currencyFormat;
  final bool readOnly;
  final String style;
  final int index;
  final void Function(String id, InvoiceLineItem updated) onChanged;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final decoration = _decoration();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: InlineEditableText(
                  value: item.description,
                  placeholder: l10n.text('invoiceLineDescriptionPlaceholder'),
                  multiline: true,
                  enabled: !readOnly,
                  onSubmitted: (value) => onChanged(
                    item.id,
                    item.copyWith(
                      description: value.isEmpty
                          ? l10n.text('invoiceLineDescriptionPlaceholder')
                          : value,
                    ),
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
                flex: 2,
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
                flex: 2,
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
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    currencyFormat.format(item.total),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _decoration() {
    final baseColor = palette.canvasBackground ?? palette.surface;
    Color background;
    BorderRadius radius = BorderRadius.circular(16);
    Border? border;
    List<BoxShadow>? shadows;

    switch (style) {
      case 'striped':
        background = index.isEven
            ? baseColor
            : palette.tableHeader.withOpacity(0.08);
        shadows = [
          BoxShadow(
            color: palette.accent.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];
        break;
      case 'stripedLight':
        background = index.isEven
            ? baseColor
            : palette.highlight?.withOpacity(0.08) ?? palette.accent.withOpacity(0.08);
        border = Border.all(color: palette.border.withOpacity(0.5));
        break;
      case 'ledger':
        background = baseColor;
        border = Border.all(color: palette.border, width: 1.2);
        radius = BorderRadius.circular(8);
        break;
      case 'outlined':
        background = baseColor;
        border = Border.all(color: palette.border.withOpacity(0.8));
        radius = BorderRadius.circular(14);
        break;
      case 'separated':
        background = baseColor;
        border = Border(bottom: BorderSide(color: palette.border.withOpacity(0.6), width: 1));
        radius = BorderRadius.circular(0);
        break;
      case 'tableHeader':
        background = index.isEven
            ? baseColor
            : palette.tableHeader.withOpacity(0.06);
        border = Border.all(color: palette.border.withOpacity(0.6));
        break;
      case 'japanese':
        background = baseColor;
        border = Border.all(color: palette.border.withOpacity(0.8));
        radius = BorderRadius.circular(12);
        break;
      default:
        background = baseColor;
    }

    return BoxDecoration(
      color: background,
      borderRadius: radius,
      border: border,
      boxShadow: shadows,
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
