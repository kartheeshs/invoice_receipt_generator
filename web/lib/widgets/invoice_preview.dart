import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';
import 'invoice_status_chip.dart';

class InvoicePreview extends StatelessWidget {
  const InvoicePreview({super.key, required this.invoice, required this.currency});

  final Invoice invoice;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
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
                        '請求書 ${invoice.number.isEmpty ? '（番号未設定）' : invoice.number}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '請求先: ${invoice.clientName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '案件名: ${invoice.projectName}',
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
                _PreviewInfo(label: '発行日', value: _formatDate(invoice.issueDate)),
                _PreviewInfo(label: '支払期限', value: _formatDate(invoice.dueDate)),
                _PreviewInfo(label: '請求金額', value: currency.format(invoice.total)),
                _PreviewInfo(label: '税率', value: '${(invoice.taxRate * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 20),
            _ItemsTable(invoice: invoice, currency: currency),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _TotalRow(label: '小計', value: currency.format(invoice.subtotal)),
                  _TotalRow(label: '消費税', value: currency.format(invoice.tax)),
                  const Divider(height: 24),
                  _TotalRow(
                    label: '合計',
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
                  label: const Text('PDFをダウンロード'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('リマインドを送る'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('yyyy/MM/dd');
    return formatter.format(date);
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
  const _ItemsTable({required this.invoice, required this.currency});

  final Invoice invoice;
  final NumberFormat currency;

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
              children: const [
                Expanded(flex: 4, child: Text('品目')),
                Expanded(flex: 2, child: Text('数量')),
                Expanded(flex: 2, child: Text('単価')),
                Expanded(flex: 2, child: Text('金額')),
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
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: style),
        ],
      ),
    );
  }
}
