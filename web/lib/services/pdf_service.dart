// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import '../models/user_profile.dart';

class PdfService {
  Future<void> downloadInvoice({
    required Invoice invoice,
    required UserProfile profile,
    required Locale locale,
  }) async {
    final format = NumberFormat.currency(
      locale: locale.toLanguageTag(),
      name: invoice.currencyCode,
      symbol: invoice.currencySymbol,
    );
    final dateFormat = DateFormat.yMMMMd(locale.toLanguageTag());

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(profile.companyName,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text(profile.displayName),
                  if (profile.address.isNotEmpty) pw.Text(profile.address),
                  if (profile.phone.isNotEmpty) pw.Text(profile.phone),
                  if (profile.taxId.isNotEmpty) pw.Text('TAX: ${profile.taxId}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Invoice', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.number, style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 12),
                  pw.Text('Issue: ${dateFormat.format(invoice.issueDate)}'),
                  pw.Text('Due: ${dateFormat.format(invoice.dueDate)}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(8)),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bill to', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.clientName.isEmpty ? '-' : invoice.clientName),
                if (invoice.projectName.isNotEmpty)
                  pw.Text(invoice.projectName, style: const pw.TextStyle(color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(invoice.description.isEmpty ? '-' : invoice.description),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(format.format(invoice.amount), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(format.format(invoice.amount)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 32),
            pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.notes),
          ],
          pw.SizedBox(height: 24),
          pw.Text('Status: ${invoice.status.name.toUpperCase()}'),
        ],
      ),
    );

    final bytes = await pdf.save();
    _triggerDownload(bytes, 'invoice-${invoice.number.replaceAll('#', '')}.pdf');
  }

  void _triggerDownload(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
