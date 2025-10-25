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
    final isNewDraft =
        selectedInvoice != null && !appState.invoices.any((invoice) => invoice.id == selectedInvoice.id);

    return Padding(
      padding: const EdgeInsets.all(24),
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
                    Text(l10n.text('invoicesTab'), style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(l10n.text('invoiceEditorSubtitle')),
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showVertical = constraints.maxWidth < 1180;
                final sidebar = SizedBox(
                  width: showVertical ? double.infinity : 340,
                  child: _InvoiceSidebar(
                    searchController: _searchController,
                    onSearchChanged: () => setState(() {}),
                    filterStatus: _filterStatus,
                    onFilterChanged: (status) => setState(() => _filterStatus = status),
                    invoices: filteredInvoices,
                    selectedInvoice: selectedInvoice,
                    currencyFormatter: currency,
                    onSelectInvoice: (invoice) => _selectInvoice(appState, invoice),
                    onDeleteInvoice: (invoice) => _deleteInvoice(appState, invoice),
                    onDownloadInvoice: widget.onDownloadInvoice,
                    onRequestSignIn: widget.onRequestSignIn,
                    isGuest: isGuest,
                    hasDraft: isNewDraft,
                  ),
                );

                final editor = Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: selectedInvoice == null
                          ? _EmptyEditorState(onCreateInvoice: () => _startNewInvoice(appState))
                          : InvoiceEditor(
                              key: ValueKey(selectedInvoice.id),
                              invoice: selectedInvoice,
                              profile: appState.profile,
                              availableTemplates: appState.availableTemplates,
                              isNewDraft: isNewDraft,
                              isGuest: isGuest,
                              onSave: (invoice) async => _saveInvoice(appState, invoice),
                              onDelete: isNewDraft ? null : (invoice) async => _deleteInvoice(appState, invoice),
                              onDownload: (invoice) async => widget.onDownloadInvoice(invoice),
                              onClose: () => _closeEditor(appState),
                              onRequestSignIn: widget.onRequestSignIn,
                            ),
                    ),
                  ),
                );

                if (showVertical) {
                  return Column(
                    children: [
                      sidebar,
                      const SizedBox(height: 24),
                      editor,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sidebar,
                    const SizedBox(width: 24),
                    editor,
                  ],
                );
              },
            ),
          ),
        ],
      ),
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
    return Column(
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
    );
  }
}

class _EmptyEditorState extends StatelessWidget {
  const _EmptyEditorState({required this.onCreateInvoice});

  final VoidCallback onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.design_services_outlined, size: 48),
          const SizedBox(height: 16),
          Text(l10n.text('invoiceEditorEmptyTitle'), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          SizedBox(
            width: 420,
            child: Text(
              l10n.text('invoiceEditorEmptyBody'),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateInvoice,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.text('createInvoiceAction')),
          ),
        ],
      ),
    );
  }
}

enum _InvoiceAction { open, download, delete }
