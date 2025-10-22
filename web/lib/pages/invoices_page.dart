
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
    required this.onRequestSignIn,
  });

  final VoidCallback onCreateInvoice;
  final ValueChanged<Invoice> onEditInvoice;
  final ValueChanged<Invoice> onDeleteInvoice;
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
    final currency = l10n.currencyFormat(appState.profile.currencyCode, appState.profile.currencySymbol);
    final query = _searchController.text.trim().toLowerCase();
    final isGuest = appState.isGuest;
    final selectedInvoice = appState.selectedInvoice;
    final formatAmount = (double value) => currency.format(value);

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
              child: isGuest
                  ? _buildGuestContent(context, selectedInvoice, formatAmount)
                  : invoices.isEmpty
                      ? Center(child: Text(l10n.text('invoicesEmptyTitle')))
                      : ListView.separated(
                      itemCount: invoices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        final templateLabel = l10n.invoiceTemplateLabel(invoice.template);
                        final subtitleParts = <String>[];
                        if (invoice.projectName.isNotEmpty) {
                          subtitleParts.add(invoice.projectName);
                        }
                        subtitleParts.add(templateLabel);
                        subtitleParts.add(l10n.dateFormat.format(invoice.dueDate));
                        final subtitleText = subtitleParts.join(' • ');
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
                                onSelected: (action) async {
                                  switch (action) {
                                    case _InvoiceAction.edit:
                                      widget.onEditInvoice(invoice);
                                      break;
                                    case _InvoiceAction.download:
                                      await widget.onDownloadInvoice(invoice);
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

  Widget _buildGuestContent(
    BuildContext context,
    Invoice? invoice,
    String Function(double) formatAmount,
  ) {
    final l10n = context.l10n;
    if (invoice == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.text('guestInvoicesLockedBody'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => widget.onRequestSignIn(),
                child: Text(l10n.text('signInButton')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: widget.onCreateInvoice,
                child: Text(l10n.text('createInvoiceAction')),
              ),
            ],
          ),
        ),
      );
    }

    final templateLabel = l10n.invoiceTemplateLabel(invoice.template);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.text('guestCurrentInvoiceTitle'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.text('guestCurrentInvoiceBody')),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.description),
              title: Text(invoice.clientName.isEmpty ? invoice.number : invoice.clientName),
              subtitle: Text('${templateLabel} • ${l10n.dateFormat.format(invoice.dueDate)}'),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(formatAmount(invoice.amount)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.invoiceStatusLabel(invoice.status),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              FilledButton(
                onPressed: () => widget.onRequestSignIn(),
                child: Text(l10n.text('signInButton')),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => widget.onEditInvoice(invoice),
                child: Text(l10n.text('editInvoice')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _InvoiceAction { edit, download, delete }
