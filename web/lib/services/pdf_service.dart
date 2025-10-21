import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';

class InvoicePdfService {
  InvoicePdfService(this.l10n);

  final AppLocalizations l10n;

  Future<Uint8List> buildInvoice({
    required Invoice invoice,
    required AppState appState,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        ),
        build: (context) => [
          _buildHeader(invoice, appState),
          pw.SizedBox(height: 24),
          _buildDetailsTable(invoice),
          pw.SizedBox(height: 24),
          _buildItemsTable(invoice),
          pw.SizedBox(height: 16),
          _buildSummary(invoice),
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildNotes(invoice.notes),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(Invoice invoice, AppState state) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                l10n.invoiceTitle(invoice.number),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(l10n.previewClient(invoice.clientName)),
              pw.Text(l10n.previewProject(invoice.projectName)),
            ],
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.deepPurple, width: 1.2),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(state.businessName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(state.ownerName),
              pw.Text(state.address),
              pw.Text('〒${state.postalCode}'),
              pw.Text(state.email),
              if (state.phoneNumber.isNotEmpty) pw.Text(state.phoneNumber),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailsTable(Invoice invoice) {
    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(120),
        1: pw.FlexColumnWidth(),
      },
      children: [
        _detailRow(l10n.issueDateLabel, l10n.formatDate(invoice.issueDate)),
        _detailRow(l10n.dueDateLabel, l10n.formatDate(invoice.dueDate)),
        _detailRow(l10n.previewTaxRateLabel, '${(invoice.taxRate * 100).toStringAsFixed(0)}%'),
        _detailRow(l10n.statusLabel, l10n.invoiceStatusLabel(invoice.status)),
      ],
    );
  }

  pw.TableRow _detailRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(label, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Text(value),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEDE7F6)),
          children: [
            _cell(l10n.itemsHeaderDescription, isHeader: true),
            _cell(l10n.itemsHeaderQuantity, isHeader: true),
            _cell(l10n.itemsHeaderUnitPrice, isHeader: true),
            _cell(l10n.itemsHeaderAmount, isHeader: true),
          ],
        ),
        ...invoice.items.map(
          (item) => pw.TableRow(
            children: [
              _cell(item.description),
              _cell(item.quantity.toString()),
              _cell(l10n.currencyFormat.format(item.unitPrice)),
              _cell(l10n.currencyFormat.format(item.amount)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummary(Invoice invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.deepPurple, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _summaryRow(l10n.summarySubtotal, l10n.currencyFormat.format(invoice.subtotal)),
            _summaryRow(l10n.summaryTax, l10n.currencyFormat.format(invoice.tax)),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Divider(color: PdfColors.grey400, height: 1),
            ),
            _summaryRow(
              l10n.summaryTotal,
              l10n.currencyFormat.format(invoice.total),
              isEmphasized: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF4F0FF),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(notes),
    );
  }

  pw.Widget _cell(String value, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool isEmphasized = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isEmphasized ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
