
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({
    super.key,
    required this.onCreateInvoice,
    required this.onEditInvoice,
    required this.onDeleteInvoice,
    required this.onDownloadInvoice,
  });

  final VoidCallback onCreateInvoice;
  final ValueChanged<Invoice> onEditInvoice;
  final ValueChanged<Invoice> onDeleteInvoice;
  final ValueChanged<Invoice> onDownloadInvoice;

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
    final currency = l10n.currencyFormat(appState.profile.currencyCode, appState.profile.currencySymbol);
    final query = _searchController.text.trim().toLowerCase();

    final invoices = appState.invoices.where((invoice) {
      final matchesQuery = query.isEmpty ||
          invoice.clientName.toLowerCase().contains(query) ||
          invoice.projectName.toLowerCase().contains(query) ||
          invoice.number.toLowerCase().contains(query);
      final matchesStatus = _filterStatus == null || invoice.status == _filterStatus;
      return matchesQuery && matchesStatus;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.text('invoicesTab'), style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(l10n.text('invoicesEmptyBody')),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: widget.onCreateInvoice,
                icon: const Icon(Icons.add),
                label: Text(l10n.text('newInvoice')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.text('searchInvoices'),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.text('filterAll')),
                    selected: _filterStatus == null,
                    onSelected: (_) => setState(() => _filterStatus = null),
                  ),
                  ...InvoiceStatus.values.map(
                    (status) => ChoiceChip(
                      label: Text(l10n.invoiceStatusLabel(status)),
                      selected: _filterStatus == status,
                      onSelected: (_) => setState(() => _filterStatus = status),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: invoices.isEmpty
                  ? Center(child: Text(l10n.text('invoicesEmptyTitle')))
                  : ListView.separated(
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        final subtitleText = invoice.projectName.isEmpty
                            ? l10n.dateFormat.format(invoice.dueDate)
                            : '${invoice.projectName} • ${l10n.dateFormat.format(invoice.dueDate)}';
                        return ListTile(
                          leading: const Icon(Icons.description_outlined),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          title: Text(invoice.clientName.isEmpty ? invoice.number : invoice.clientName),
                          subtitle: Text(subtitleText),
                          onTap: () => widget.onEditInvoice(invoice),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(currency.format(invoice.amount)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      l10n.invoiceStatusLabel(invoice.status),
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              PopupMenuButton<_InvoiceAction>(
                                onSelected: (action) {
                                  switch (action) {
                                    case _InvoiceAction.edit:
                                      widget.onEditInvoice(invoice);
                                      break;
                                    case _InvoiceAction.download:
                                      widget.onDownloadInvoice(invoice);
                                      break;
                                    case _InvoiceAction.delete:
                                      widget.onDeleteInvoice(invoice);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _InvoiceAction.edit,
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
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _InvoiceAction { edit, download, delete }
