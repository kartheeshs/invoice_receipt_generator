import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import 'invoice_status_chip.dart';

class InvoicePreview extends StatelessWidget {
  const InvoicePreview({super.key, required this.invoice, required this.currency});

  final Invoice invoice;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
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
                      Text(
                        l10n.invoiceTitle(invoice.number),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.previewClient(invoice.clientName),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        l10n.previewProject(invoice.projectName),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                InvoiceStatusChip(status: invoice.status),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _PreviewInfo(label: l10n.issueDateLabel, value: l10n.formatDate(invoice.issueDate)),
                _PreviewInfo(label: l10n.dueDateLabel, value: l10n.formatDate(invoice.dueDate)),
                _PreviewInfo(label: l10n.previewAmountLabel, value: currency.format(invoice.total)),
                _PreviewInfo(label: l10n.previewTaxRateLabel, value: '${(invoice.taxRate * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 20),
            _ItemsTable(invoice: invoice, currency: currency, l10n: l10n),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TotalRow(label: l10n.summarySubtotal, value: currency.format(invoice.subtotal)),
                  _TotalRow(label: l10n.summaryTax, value: currency.format(invoice.tax)),
                  const Divider(height: 24),
                  _TotalRow(
                    label: l10n.summaryTotal,
                    value: currency.format(invoice.total),
                    isEmphasized: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (invoice.notes.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(invoice.notes),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.downloadPdf),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mail_outline),
                  label: Text(l10n.sendReminder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewInfo extends StatelessWidget {
  const _PreviewInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.invoice, required this.currency, required this.l10n});

  final Invoice invoice;
  final NumberFormat currency;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF9F7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(flex: 4, child: Text(l10n.itemsHeaderDescription)),
                Expanded(flex: 2, child: Text(l10n.itemsHeaderQuantity)),
                Expanded(flex: 2, child: Text(l10n.itemsHeaderUnitPrice)),
                Expanded(flex: 2, child: Text(l10n.itemsHeaderAmount)),
              ],
            ),
            const Divider(height: 24),
            ...invoice.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(item.description, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(item.quantity.toString()),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(currency.format(item.unitPrice)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(currency.format(item.amount)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.isEmphasized = false});

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final style = isEmphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}
