import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';
import '../widgets/invoice_preview.dart';
import '../widgets/invoice_status_chip.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({
    super.key,
    required this.onCreateInvoice,
    required this.onEditInvoice,
    required this.onDeleteInvoice,
  });

  final VoidCallback onCreateInvoice;
  final ValueChanged<Invoice> onEditInvoice;
  final ValueChanged<Invoice> onDeleteInvoice;

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final _searchController = TextEditingController();
  InvoiceStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;
    final invoices = appState.invoices;
    final query = _searchController.text.trim().toLowerCase();

    final filteredInvoices = invoices.where((invoice) {
      final matchesQuery = query.isEmpty ||
          invoice.clientName.toLowerCase().contains(query) ||
          invoice.projectName.toLowerCase().contains(query) ||
          invoice.number.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == null || invoice.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    Invoice? selectedInvoice = appState.selectedInvoice;
    if (selectedInvoice != null &&
        !filteredInvoices.any((invoice) => invoice.id == selectedInvoice.id)) {
      selectedInvoice = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppState>().selectInvoice(null);
      });
    }
    if (selectedInvoice == null && filteredInvoices.isNotEmpty) {
      final firstInvoice = filteredInvoices.first;
      selectedInvoice = firstInvoice;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppState>().selectInvoice(firstInvoice);
      });
    }

    final NumberFormat currency = l10n.currencyFormat;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1080;
        final content = _InvoicesContent(
          invoices: filteredInvoices,
          selectedInvoice: selectedInvoice,
          onSelectInvoice: (invoice) => context.read<AppState>().selectInvoice(invoice),
          onCreateInvoice: widget.onCreateInvoice,
          onEditInvoice: widget.onEditInvoice,
          onDeleteInvoice: widget.onDeleteInvoice,
          currency: currency,
          l10n: l10n,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                          Text(l10n.invoicesHeaderTitle,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text(
                            l10n.invoicesHeaderSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    if (isWide)
                      FilledButton.icon(
                        onPressed: widget.onCreateInvoice,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.newInvoiceShort),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.invoicesSearchHint,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.filterAll),
                          selected: _statusFilter == null,
                          onSelected: (_) => setState(() => _statusFilter = null),
                        ),
                        ...InvoiceStatus.values.map(
                          (status) => ChoiceChip(
                            label: Text(l10n.invoiceStatusLabel(status)),
                            selected: _statusFilter == status,
                            onSelected: (_) => setState(() => _statusFilter = status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!isWide) ...[
                  content,
                  const SizedBox(height: 24),
                  if (selectedInvoice != null)
                    InvoicePreview(invoice: selectedInvoice, currency: currency),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: content),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 2,
                        child: selectedInvoice != null
                            ? InvoicePreview(invoice: selectedInvoice, currency: currency)
                            : _EmptyPreview(onCreateInvoice: widget.onCreateInvoice, l10n: l10n),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InvoicesContent extends StatelessWidget {
  const _InvoicesContent({
    required this.invoices,
    required this.selectedInvoice,
    required this.onSelectInvoice,
    required this.onCreateInvoice,
    required this.onEditInvoice,
    required this.onDeleteInvoice,
    required this.currency,
    required this.l10n,
  });

  final List<Invoice> invoices;
  final Invoice? selectedInvoice;
  final ValueChanged<Invoice?> onSelectInvoice;
  final VoidCallback onCreateInvoice;
  final ValueChanged<Invoice> onEditInvoice;
  final ValueChanged<Invoice> onDeleteInvoice;
  final NumberFormat currency;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 48, color: Colors.black26),
                const SizedBox(height: 12),
                Text(l10n.noInvoicesFound),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: onCreateInvoice,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createFirstInvoice),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invoices.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            final isSelected = selectedInvoice?.id == invoice.id;

            return InkWell(
              onTap: () => onSelectInvoice(invoice),
              child: Container(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.clientName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.projectName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l10n.issueDateLabel}: ${l10n.formatDate(invoice.issueDate)}'),
                          const SizedBox(height: 2),
                          Text('${l10n.dueDateLabel}: ${l10n.formatDate(invoice.dueDate)}'),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        currency.format(invoice.total),
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InvoiceStatusChip(status: invoice.status, compact: true),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      tooltip: l10n.invoiceActionsTooltip,
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEditInvoice(invoice);
                            break;
                          case 'delete':
                            onDeleteInvoice(invoice);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(l10n.edit),
                            dense: true,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: Text(l10n.delete),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.onCreateInvoice, required this.l10n});

  final VoidCallback onCreateInvoice;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.selectInvoiceEmptyState,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onCreateInvoice,
                icon: const Icon(Icons.add),
                label: Text(l10n.createInvoiceAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
