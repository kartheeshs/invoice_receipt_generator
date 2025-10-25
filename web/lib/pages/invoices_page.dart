import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';
import '../widgets/invoice_editor.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({
    super.key,
    required this.onDownloadInvoice,
    required this.onRequestSignIn,
  });

  final Future<void> Function(Invoice) onDownloadInvoice;
  final Future<void> Function() onRequestSignIn;

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final _searchController = TextEditingController();
  InvoiceStatus? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = l10n.currencyFormat(appState.profile.currencyCode, appState.profile.currencySymbol);
    final query = _searchController.text.trim().toLowerCase();
    final selectedInvoice = appState.selectedInvoice;
    final filteredInvoices = appState.invoices.where((invoice) {
      final matchesQuery = query.isEmpty ||
          invoice.clientName.toLowerCase().contains(query) ||
          invoice.projectName.toLowerCase().contains(query) ||
          invoice.number.toLowerCase().contains(query);
      final matchesStatus = _filterStatus == null || invoice.status == _filterStatus;
      return matchesQuery && matchesStatus;
    }).toList();
    final isGuest = appState.isGuest;
    Widget content;
    if (selectedInvoice == null) {
      content = KeyedSubtree(
        key: const ValueKey('invoice-library'),
        child: _buildLibraryView(
          context: context,
          appState: appState,
          invoices: filteredInvoices,
          currency: currency,
          isGuest: isGuest,
        ),
      );
    } else {
      content = KeyedSubtree(
        key: ValueKey('workspace-${selectedInvoice.id}'),
        child: _buildWorkspaceView(
          context: context,
          appState: appState,
          invoice: selectedInvoice,
          isGuest: isGuest,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.45),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: content,
      ),
    );
  }

  Widget _buildLibraryView({
    required BuildContext context,
    required AppState appState,
    required List<Invoice> invoices,
    required NumberFormat currency,
    required bool isGuest,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

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
                  Text(
                    l10n.text('invoicesTab'),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.text('invoiceEditorSubtitle'), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => _startNewInvoice(appState),
              icon: const Icon(Icons.add),
              label: Text(l10n.text('newInvoice')),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _LibraryHero(),
        const SizedBox(height: 24),
        Expanded(
          child: _InvoiceSidebar(
            searchController: _searchController,
            onSearchChanged: () => setState(() {}),
            filterStatus: _filterStatus,
            onFilterChanged: (status) => setState(() => _filterStatus = status),
            invoices: invoices,
            selectedInvoice: null,
            currencyFormatter: currency,
            onSelectInvoice: (invoice) => _selectInvoice(appState, invoice),
            onDeleteInvoice: (invoice) => _deleteInvoice(appState, invoice),
            onDownloadInvoice: widget.onDownloadInvoice,
            onRequestSignIn: widget.onRequestSignIn,
            isGuest: isGuest,
            hasDraft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceView({
    required BuildContext context,
    required AppState appState,
    required Invoice invoice,
    required bool isGuest,
  }) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isNewDraft = !appState.invoices.any((item) => item.id == invoice.id);
    final historyPanel = _InvoiceHistoryPanel(
      invoice: invoice,
      isPremium: appState.isPremium,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => _closeEditor(appState),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.clientName.isEmpty ? invoice.number : invoice.clientName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        l10n.invoiceStatusLabel(invoice.status),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.dateFormat.format(invoice.dueDate),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isNewDraft)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(l10n.text('draftUnsavedLabel'), style: theme.textTheme.labelMedium),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showHistoryRail = constraints.maxWidth > 1260;
                    final editor = InvoiceEditor(
                      key: ValueKey(invoice.id),
                      invoice: invoice,
                      profile: appState.profile,
                      availableTemplates: appState.availableTemplates,
                      isNewDraft: isNewDraft,
                      isGuest: isGuest,
                      onSave: (updated) async => _saveInvoice(appState, updated),
                      onDelete: isNewDraft ? null : (updated) async => _deleteInvoice(appState, updated),
                      onDownload: (updated) async => widget.onDownloadInvoice(updated),
                      onClose: () => _closeEditor(appState),
                      onRequestSignIn: widget.onRequestSignIn,
                    );

                    if (showHistoryRail) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: editor),
                          const SizedBox(width: 28),
                          SizedBox(width: 320, child: historyPanel),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        Expanded(child: editor),
                        const SizedBox(height: 24),
                        historyPanel,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startNewInvoice(AppState appState) {
    final invoice = appState.prepareInvoice();
    appState.selectInvoice(invoice);
  }

  void _selectInvoice(AppState appState, Invoice invoice) {
    appState.selectInvoice(invoice);
  }

  Future<void> _saveInvoice(AppState appState, Invoice invoice) async {
    appState.saveInvoice(invoice);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.text('invoiceSaved'))));
  }

  Future<void> _deleteInvoice(AppState appState, Invoice invoice) async {
    appState.deleteInvoice(invoice.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.text('invoiceDeleted'))));
  }

  void _closeEditor(AppState appState) {
    appState.selectInvoice(null);
  }
}

class _InvoiceSidebar extends StatelessWidget {
  const _InvoiceSidebar({
    required this.searchController,
    required this.onSearchChanged,
    required this.filterStatus,
    required this.onFilterChanged,
    required this.invoices,
    required this.selectedInvoice,
    required this.currencyFormatter,
    required this.onSelectInvoice,
    required this.onDeleteInvoice,
    required this.onDownloadInvoice,
    required this.onRequestSignIn,
    required this.isGuest,
    required this.hasDraft,
  });

  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final InvoiceStatus? filterStatus;
  final ValueChanged<InvoiceStatus?> onFilterChanged;
  final List<Invoice> invoices;
  final Invoice? selectedInvoice;
  final NumberFormat currencyFormatter;
  final ValueChanged<Invoice> onSelectInvoice;
  final Future<void> Function(Invoice) onDeleteInvoice;
  final Future<void> Function(Invoice) onDownloadInvoice;
  final Future<void> Function() onRequestSignIn;
  final bool isGuest;
  final bool hasDraft;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.text('searchInvoices'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onChanged: (_) => onSearchChanged(),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.text('filterAll')),
                    selected: filterStatus == null,
                    onSelected: (_) => onFilterChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ...InvoiceStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(l10n.invoiceStatusLabel(status)),
                        selected: filterStatus == status,
                        onSelected: (_) => onFilterChanged(status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (hasDraft && selectedInvoice != null)
              _DraftSummaryTile(
                invoice: selectedInvoice!,
                currencyFormatter: currencyFormatter,
                onTap: () => onSelectInvoice(selectedInvoice!),
                isGuest: isGuest,
              ),
            if (hasDraft) const SizedBox(height: 16),
            if (isGuest)
              Expanded(
                child: _GuestHistoryState(
                  onRequestSignIn: onRequestSignIn,
                  selectedInvoice: selectedInvoice,
                  currencyFormatter: currencyFormatter,
                  l10n: l10n,
                ),
              )
            else if (invoices.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 40),
                      const SizedBox(height: 12),
                      Text(l10n.text('invoicesEmptyTitle'), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        l10n.text('invoicesEmptyBody'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final isSelected = selectedInvoice?.id == invoice.id;
                    final subtitleParts = <String>[];
                    if (invoice.projectName.isNotEmpty) {
                      subtitleParts.add(invoice.projectName);
                    }
                    subtitleParts.add(l10n.invoiceTemplateLabel(invoice.template));
                    subtitleParts.add(l10n.dateFormat.format(invoice.dueDate));
                    final subtitleText = subtitleParts.join(' • ');
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.description_outlined),
                      ),
                      title: Text(invoice.clientName.isEmpty ? invoice.number : invoice.clientName),
                      subtitle: Text(subtitleText),
                      onTap: () => onSelectInvoice(invoice),
                      trailing: PopupMenuButton<_InvoiceAction>(
                        onSelected: (action) async {
                          switch (action) {
                            case _InvoiceAction.open:
                              onSelectInvoice(invoice);
                              break;
                            case _InvoiceAction.download:
                              await onDownloadInvoice(invoice);
                              break;
                            case _InvoiceAction.delete:
                              await onDeleteInvoice(invoice);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _InvoiceAction.open,
                            child: Text(l10n.text('editInvoice')),
                          ),
                          PopupMenuItem(
                            value: _InvoiceAction.download,
                            child: Text(l10n.text('downloadPdf')),
                          ),
                          PopupMenuItem(
                            value: _InvoiceAction.delete,
                            child: Text(l10n.text('deleteButton')),
                          ),
                        ],
                      ),
                      subtitleTextStyle: theme.textTheme.bodySmall,
                      dense: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DraftSummaryTile extends StatelessWidget {
  const _DraftSummaryTile({
    required this.invoice,
    required this.currencyFormatter,
    required this.onTap,
    required this.isGuest,
  });

  final Invoice invoice;
  final NumberFormat currencyFormatter;
  final VoidCallback onTap;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: const Icon(Icons.pending_actions_outlined),
      title: Text(l10n.text('draftUnsavedLabel')),
      subtitle: Text(l10n.text('draftUnsavedBody')),
      trailing: Text(currencyFormatter.format(invoice.amount)),
      onTap: onTap,
    );
  }
}

class _GuestHistoryState extends StatelessWidget {
  const _GuestHistoryState({
    required this.onRequestSignIn,
    required this.selectedInvoice,
    required this.currencyFormatter,
    required this.l10n,
  });

  final Future<void> Function() onRequestSignIn;
  final Invoice? selectedInvoice;
  final NumberFormat currencyFormatter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.text('guestInvoicesLockedTitle'), style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(l10n.text('guestInvoicesLockedBody')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => onRequestSignIn(),
                  child: Text(l10n.text('signInButton')),
                ),
              ],
            ),
          ),
          if (selectedInvoice != null) ...[
            const SizedBox(height: 24),
            Text(l10n.text('guestCurrentInvoiceTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(selectedInvoice!.clientName.isEmpty
                    ? selectedInvoice!.number
                    : selectedInvoice!.clientName),
                subtitle: Text(l10n.dateFormat.format(selectedInvoice!.dueDate)),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(currencyFormatter.format(selectedInvoice!.amount)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.invoiceStatusLabel(selectedInvoice!.status)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceHistoryPanel extends StatelessWidget {
  const _InvoiceHistoryPanel({
    required this.invoice,
    required this.isPremium,
  });

  final Invoice invoice;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final revisions = invoice.revisions;
    final dateFormat = DateFormat.yMMMd(l10n.locale.toLanguageTag());
    final timeFormat = DateFormat.Hm(l10n.locale.toLanguageTag());

    final subtitle = l10n
        .text('invoiceHistorySubtitle')
        .replaceAll('{count}', revisions.length.toString());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('invoiceHistoryTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (!isPremium)
              _HistoryMessage(text: l10n.text('invoiceHistoryPremiumHint'))
            else if (revisions.isEmpty)
              _HistoryMessage(text: l10n.text('invoiceHistoryEmpty'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: revisions.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final revision = revisions[index];
                  return _HistoryEntry(
                    revision: revision,
                    dateFormat: dateFormat,
                    timeFormat: timeFormat,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
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

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium),
    );
  }
}

class _LibraryHero extends StatelessWidget {
  const _LibraryHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final gradientColors = [
      theme.colorScheme.primaryContainer.withOpacity(0.65),
      theme.colorScheme.secondaryContainer.withOpacity(0.55),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('invoiceEditorEmptyTitle'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.text('landingWorkflowStepDesign'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            height: 120,
            width: 180,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.surfaceVariant),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_awesome_mosaic, size: 48, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

enum _InvoiceAction { open, download, delete }
