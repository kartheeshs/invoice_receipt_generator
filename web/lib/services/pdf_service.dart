// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_template_spec.dart';
import '../models/user_profile.dart';

class PdfService {
  Future<void> downloadInvoice({
    required Invoice invoice,
    required UserProfile profile,
    required Locale locale,
  }) async {
    final l10n = AppLocalizations(locale);
    final format = NumberFormat.currency(
      locale: locale.toLanguageTag(),
      name: invoice.currencyCode,
      symbol: invoice.currencySymbol,
    );
    final dateFormat = DateFormat.yMMMMd(locale.toLanguageTag());
    final spec = invoiceTemplateSpec(invoice.template);

    final pdf = pw.Document();

    final content = spec.isJapanese
        ? _buildJapanesePdf(
            invoice: invoice,
            profile: profile,
            format: format,
            dateFormat: dateFormat,
            spec: spec,
            l10n: l10n,
          )
        : _buildGlobalPdf(
            invoice: invoice,
            profile: profile,
            format: format,
            dateFormat: dateFormat,
            spec: spec,
            l10n: l10n,
          );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => content,
      ),
    );

    final bytes = await pdf.save();
    _triggerDownload(bytes, 'invoice-${invoice.number.replaceAll('#', '')}.pdf');
  }

  List<pw.Widget> _buildGlobalPdf({
    required Invoice invoice,
    required UserProfile profile,
    required NumberFormat format,
    required DateFormat dateFormat,
    required InvoiceTemplateSpec spec,
    required AppLocalizations l10n,
  }) {
    final accentValue = spec.accentColor;
    final headerTextValue = spec.headerTextColor;
    final borderValue = spec.borderColor;
    final badgeValue = spec.badgeBackgroundColor;
    final mutedValue = spec.mutedColor;
    final balanceBackgroundValue = spec.balanceBackgroundColor;
    final surfaceValue = spec.surfaceColor;

    final accent = _pdfColor(accentValue);
    final headerText = _pdfColor(headerTextValue);
    final border = _pdfColor(borderValue);
    final badge = _pdfColor(badgeValue);
    final muted = _pdfColor(mutedValue);
    final balanceBackground = _pdfColor(balanceBackgroundValue);
    final surface = _pdfColor(surfaceValue);
    final headerGradient = pw.LinearGradient(
      colors: spec.headerGradientColors.map(_pdfColor).toList(),
      begin: _pdfAlignment(spec.gradientBegin),
      end: _pdfAlignment(spec.gradientEnd),
    );

    final project = invoice.projectName.isEmpty
        ? l10n.text('invoiceDefaultProject')
        : invoice.projectName;
    final description = invoice.description.isEmpty
        ? l10n.text('invoiceDefaultDescription')
        : invoice.description;
    final client = invoice.clientName.isEmpty
        ? l10n.text('invoiceDefaultClient')
        : invoice.clientName;
    final lineItems = invoice.lineItems.isNotEmpty
        ? invoice.lineItems
        : [
            InvoiceLineItem(
              id: '${invoice.id}-single',
              description: description,
              quantity: 1,
              unitPrice: invoice.amount,
            ),
          ];
    final totalAmount = lineItems.fold<double>(0, (value, item) => value + item.total);
    final amountText = format.format(totalAmount);
    final dueMessage = _dueMessage(l10n, invoice.dueDate);
    final statusLabel = l10n.invoiceStatusLabel(invoice.status);
    final companyName = profile.companyName.isEmpty ? profile.displayName : profile.companyName;
    final notesText = _composeSectionText(
      invoice,
      {InvoiceSectionType.notes, InvoiceSectionType.custom},
      fallback: invoice.notes,
    );
    final termsText = _composeSectionText(invoice, {InvoiceSectionType.terms});
    final advertisementSection = _findSection(invoice, InvoiceSectionType.advertisement);
    final adHeadline = advertisementSection != null
        ? _sectionBindingValue(advertisementSection, InvoiceFieldBinding.advertisementHeadline)
        : '';
    final adBody = advertisementSection != null
        ? _sectionBindingValue(advertisementSection, InvoiceFieldBinding.advertisementBody)
        : '';
    final adCta = advertisementSection != null
        ? _sectionBindingValue(advertisementSection, InvoiceFieldBinding.advertisementCta)
        : '';

    return [
      pw.Container(
        decoration: pw.BoxDecoration(
          gradient: headerGradient,
          borderRadius: pw.BorderRadius.circular(24),
          border: pw.Border.all(color: border, width: 1),
        ),
        padding: const pw.EdgeInsets.all(28),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: headerText,
                        ),
                      ),
                      if (profile.tagline.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 6),
                          child: pw.Text(
                            profile.tagline,
                            style: pw.TextStyle(color: _pdfColor(spec.taglineColor), fontSize: 12),
                          ),
                        ),
                      pw.SizedBox(height: 18),
                      pw.Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (profile.address.isNotEmpty)
                            _pdfChip(profile.address, headerText, badge),
                          if (profile.phone.isNotEmpty)
                            _pdfChip(profile.phone, headerText, badge),
                          if (profile.email.isNotEmpty)
                            _pdfChip(profile.email, headerText, badge),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _pdfLogoPlaceholder(companyName, accent, badge),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      l10n.text('invoicePreviewTitle').toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: headerText,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _pdfBadge(invoice.number, accent, badge),
                    pw.SizedBox(height: 12),
                    _pdfStatusBadge(statusLabel, accent, badge),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _pdfInfoBadge(l10n.text('invoiceIssuedLabel'), dateFormat.format(invoice.issueDate), accent, badge),
                _pdfInfoBadge(l10n.text('invoiceDueLabel'), dateFormat.format(invoice.dueDate), accent, badge),
                _pdfInfoBadge(l10n.text('invoiceTimelineLabel'), dueMessage, accent, badge),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 24),
      pw.Container(
        decoration: pw.BoxDecoration(
          color: surface,
          borderRadius: pw.BorderRadius.circular(20),
          border: pw.Border.all(color: border, width: 1),
        ),
        padding: const pw.EdgeInsets.all(20),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _pdfInfoBlock(
                title: l10n.text('companyDetailsTitle'),
                body: [
                  profile.displayName,
                  if (profile.taxId.isNotEmpty) 'TAX: ${profile.taxId}',
                  if (profile.email.isNotEmpty) profile.email,
                ],
                muted: muted,
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _pdfInfoBlock(
                title: l10n.text('clientDetailsTitle'),
                body: [client, project],
                muted: muted,
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _pdfInfoBlock(
                title: l10n.text('invoiceMetaTitle'),
                body: [
                  '${l10n.text('invoiceIssuedLabel')}: ${dateFormat.format(invoice.issueDate)}',
                  '${l10n.text('invoiceDueLabel')}: ${dateFormat.format(invoice.dueDate)}',
                  '${l10n.text('statusLabel')}: $statusLabel',
                ],
                muted: muted,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 24),
      _pdfSummaryTable(
        items: lineItems,
        format: format,
        accent: accent,
        border: border,
        muted: muted,
        badgeValue: badgeValue,
        l10n: l10n,
      ),
      pw.SizedBox(height: 24),
      _pdfBalanceCard(
        amountText: amountText,
        dueMessage: dueMessage,
        balanceBackground: balanceBackground,
        headerText: headerText,
        headerTextValue: headerTextValue,
        l10n: l10n,
      ),
      if (notesText.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _pdfNotesSection(notesText, border, surface, l10n),
      ],
      if (termsText.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _pdfTermsSection(termsText, border, surface, l10n),
      ],
      if (adHeadline.isNotEmpty || adBody.isNotEmpty || adCta.isNotEmpty) ...[
        pw.SizedBox(height: 20),
        _pdfAdSection(
          headline: adHeadline,
          body: adBody,
          cta: adCta,
          accent: accent,
          badge: badge,
          border: border,
        ),
      ],
    ];
  }

  List<pw.Widget> _buildJapanesePdf({
    required Invoice invoice,
    required UserProfile profile,
    required NumberFormat format,
    required DateFormat dateFormat,
    required InvoiceTemplateSpec spec,
    required AppLocalizations l10n,
  }) {
    final accentValue = spec.accentColor;
    final headerTextValue = spec.headerTextColor;
    final borderValue = spec.borderColor;
    final badgeValue = spec.badgeBackgroundColor;
    final mutedValue = spec.mutedColor;
    final balanceBackgroundValue = spec.balanceBackgroundColor;
    final surfaceValue = spec.surfaceColor;

    final accent = _pdfColor(accentValue);
    final headerText = _pdfColor(headerTextValue);
    final border = _pdfColor(borderValue);
    final badge = _pdfColor(badgeValue);
    final muted = _pdfColor(mutedValue);
    final balanceBackground = _pdfColor(balanceBackgroundValue);
    final surface = _pdfColor(surfaceValue);
    final headerGradient = pw.LinearGradient(
      colors: spec.headerGradientColors.map(_pdfColor).toList(),
      begin: _pdfAlignment(spec.gradientBegin),
      end: _pdfAlignment(spec.gradientEnd),
    );

    final project = invoice.projectName.isEmpty
        ? l10n.text('invoiceDefaultProject')
        : invoice.projectName;
    final description = invoice.description.isEmpty
        ? l10n.text('invoiceDefaultDescription')
        : invoice.description;
    final clientBase = invoice.clientName.isEmpty
        ? l10n.text('invoiceDefaultClient')
        : invoice.clientName;
    final suffix = l10n.text('invoiceJapaneseBillTo');
    final recipient = clientBase.endsWith(suffix) ? clientBase : '$clientBase$suffix';
    final lineItems = invoice.lineItems.isNotEmpty
        ? invoice.lineItems
        : [
            InvoiceLineItem(
              id: '${invoice.id}-single',
              description: description,
              quantity: 1,
              unitPrice: invoice.amount,
            ),
          ];
    final subtotal = lineItems.fold<double>(0, (value, item) => value + item.total);
    final notesText = _composeSectionText(
      invoice,
      {InvoiceSectionType.notes, InvoiceSectionType.custom},
      fallback: invoice.notes,
    );
    final termsText = _composeSectionText(invoice, {InvoiceSectionType.terms});
    final advertisementSection = _findSection(invoice, InvoiceSectionType.advertisement);
    final adHeadline = advertisementSection != null
        ? _sectionBindingValue(advertisementSection, InvoiceFieldBinding.advertisementHeadline)
        : '';
    final adBody = advertisementSection != null
        ? _sectionBindingValue(advertisementSection, InvoiceFieldBinding.advertisementBody)
        : '';
    final adCta = advertisementSection != null
        ? _sectionBindingValue(advertisementSection, InvoiceFieldBinding.advertisementCta)
        : '';
    final amountText = format.format(subtotal);
    final dueMessage = _dueMessage(l10n, invoice.dueDate);
    final statusLabel = l10n.invoiceStatusLabel(invoice.status);
    final companyName = profile.companyName.isEmpty ? profile.displayName : profile.companyName;

    return [
      pw.Container(
        decoration: pw.BoxDecoration(
          gradient: headerGradient,
          borderRadius: pw.BorderRadius.circular(24),
          border: pw.Border.all(color: border, width: 1),
        ),
        padding: const pw.EdgeInsets.all(28),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: headerText,
                    ),
                  ),
                  if (profile.tagline.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Text(
                        profile.tagline,
                        style: pw.TextStyle(color: _pdfColor(spec.taglineColor), fontSize: 12),
                      ),
                    ),
                  pw.SizedBox(height: 18),
                  pw.Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (profile.address.isNotEmpty)
                        _pdfChip(profile.address, headerText, badge),
                      if (profile.phone.isNotEmpty)
                        _pdfChip(profile.phone, headerText, badge),
                    ],
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _pdfLogoPlaceholder(companyName, accent, badge),
                pw.SizedBox(height: 12),
                pw.Text(
                  l10n.text('invoiceJapaneseTitle'),
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: headerText,
                    letterSpacing: 6,
                  ),
                ),
                pw.SizedBox(height: 12),
                _pdfStatusBadge(statusLabel, accent, badge),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 24),
      pw.Container(
        decoration: pw.BoxDecoration(
          color: surface,
          borderRadius: pw.BorderRadius.circular(20),
          border: pw.Border.all(color: border, width: 1),
        ),
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: _pdfColorWithOpacity(badgeValue, 0.6),
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(recipient, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(profile.displayName, style: pw.TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(1.4),
                1: pw.FlexColumnWidth(2.4),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              border: pw.TableBorder.all(color: border, width: 0.8),
              children: [
            _pdfJapaneseMetaRow(
              l10n.text('invoiceJapaneseProjectLabel'),
              project,
              badgeValue,
              muted,
            ),
            _pdfJapaneseMetaRow(
              l10n.text('invoiceJapaneseNumberLabel'),
              invoice.number,
              badgeValue,
              muted,
            ),
            _pdfJapaneseMetaRow(
              l10n.text('invoiceJapaneseIssueLabel'),
              dateFormat.format(invoice.issueDate),
              badgeValue,
              muted,
            ),
            _pdfJapaneseMetaRow(
              l10n.text('invoiceJapaneseDueLabel'),
              dateFormat.format(invoice.dueDate),
              badgeValue,
              muted,
            ),
              ],
            ),
            pw.SizedBox(height: 18),
            _pdfJapaneseItemsTable(lineItems, format, border, muted, l10n),
            pw.SizedBox(height: 18),
            _pdfJapaneseAmountCard(l10n, amountText, dueMessage, accent, balanceBackground, muted),
            pw.SizedBox(height: 18),
            _pdfJapaneseSection(l10n.text('invoiceJapaneseDescriptionLabel'), description, border, surface),
            if (notesText.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _pdfJapaneseSection(l10n.text('invoiceJapaneseNotes'), notesText, border, surface),
            ],
            if (termsText.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _pdfJapaneseSection(l10n.text('invoiceJapaneseTerms'), termsText, border, surface),
            ],
            if (adHeadline.isNotEmpty || adBody.isNotEmpty || adCta.isNotEmpty) ...[
              pw.SizedBox(height: 18),
              _pdfJapaneseAdSection(
                headline: adHeadline,
                body: adBody,
                cta: adCta,
                accent: accent,
                border: border,
                badge: badge,
                muted: muted,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  pw.TableRow _pdfJapaneseMetaRow(
    String label,
    String value,
    int badgeValue,
    PdfColor muted,
  ) {
    final rowBackground = _pdfColorWithOpacity(badgeValue, 0.35);
    final labelBackground = _pdfColorWithOpacity(badgeValue, 0.55);
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: rowBackground),
      children: [
        pw.Container(
          color: labelBackground,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          color: PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: pw.Text(value, style: pw.TextStyle(color: muted)),
        ),
      ],
    );
  }

  pw.Widget _pdfJapaneseAmountCard(
    AppLocalizations l10n,
    String amountText,
    String dueMessage,
    PdfColor accent,
    PdfColor background,
    PdfColor muted,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l10n.text('invoiceJapaneseAmountLabel'),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Text(amountText, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.SizedBox(height: 6),
          pw.Text(dueMessage, style: pw.TextStyle(color: muted, fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _pdfJapaneseSection(String title, String value, PdfColor border, PdfColor surface) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: surface,
        borderRadius: pw.BorderRadius.circular(18),
        border: pw.Border.all(color: border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _pdfJapaneseItemsTable(
    List<InvoiceLineItem> items,
    NumberFormat format,
    PdfColor border,
    PdfColor muted,
    AppLocalizations l10n,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: border, width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.8),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(l10n.text('invoiceSummaryDescription'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(l10n.text('invoiceSummaryPrice'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(l10n.text('invoiceSummaryQty'),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(l10n.text('invoiceSummaryAmount'),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        for (final item in items)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.description),
                    if (item.notes?.isNotEmpty == true)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(item.notes!, style: pw.TextStyle(color: muted, fontSize: 10)),
                      ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Text(format.format(item.unitPrice), textAlign: pw.TextAlign.right),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Text(_formatQuantity(item.quantity), textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Text(format.format(item.total),
                    textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _pdfJapaneseAdSection({
    required String headline,
    required String body,
    required String cta,
    required PdfColor accent,
    required PdfColor border,
    required PdfColor badge,
    required PdfColor muted,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: border, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(headline, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent, fontSize: 13)),
          if (body.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(body, style: pw.TextStyle(color: muted, fontSize: 10)),
          ],
          if (cta.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: badge,
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Text(cta, style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryTable({
    required List<InvoiceLineItem> items,
    required NumberFormat format,
    required PdfColor accent,
    required PdfColor border,
    required PdfColor muted,
    required int badgeValue,
    required AppLocalizations l10n,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(22),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _pdfColorWithOpacity(badgeValue, 0.6),
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(22)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(l10n.text('invoiceSummaryDescription'),
                      style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Text(l10n.text('invoiceSummaryPrice'),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Text(l10n.text('invoiceSummaryQty'),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Text(l10n.text('invoiceSummaryAmount'),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final item in items) ...[
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.description, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            if (item.notes?.isNotEmpty == true) ...[
                              pw.SizedBox(height: 4),
                              pw.Text(item.notes!, style: pw.TextStyle(color: muted, fontSize: 10)),
                            ],
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(format.format(item.unitPrice),
                            textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 11)),
                      ),
                      pw.Expanded(
                        child: pw.Text(_formatQuantity(item.quantity),
                            textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 11)),
                      ),
                      pw.Expanded(
                        child: pw.Text(format.format(item.total),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  if (item != items.last) pw.SizedBox(height: 12),
                ],
                pw.Divider(color: border, height: 1),
                pw.SizedBox(height: 10),
                _pdfSummaryTotalRow(l10n.text('invoiceSummarySubtotal'), format.format(subtotal)),
                pw.SizedBox(height: 6),
                _pdfSummaryTotalRow(l10n.text('invoiceSummaryTotal'), format.format(subtotal), emphasized: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSummaryTotalRow(String label, String value, {bool emphasized = false}) {
    final style = pw.TextStyle(
      fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: emphasized ? 14 : 12,
    );
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text(value, style: style),
      ],
    );
  }

  pw.Widget _pdfBalanceCard({
    required String amountText,
    required String dueMessage,
    required PdfColor balanceBackground,
    required PdfColor headerText,
    required int headerTextValue,
    required AppLocalizations l10n,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: pw.BoxDecoration(
        color: balanceBackground,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(l10n.text('invoiceBalanceDueLabel'),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: headerText, fontSize: 14)),
                pw.SizedBox(height: 4),
                pw.Text(dueMessage, style: pw.TextStyle(color: headerText, fontSize: 10)),
                pw.SizedBox(height: 4),
                pw.Text(
                  l10n.text('invoiceBalanceFooter'),
                  style: pw.TextStyle(
                    color: _pdfColorWithOpacity(headerTextValue, 0.8),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(amountText,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: headerText)),
        ],
      ),
    );
  }

  pw.Widget _pdfNotesSection(String notes, PdfColor border, PdfColor surface, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: surface,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l10n.text('invoiceNotesTitle'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _pdfTermsSection(String terms, PdfColor border, PdfColor surface, AppLocalizations l10n) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: surface,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(l10n.text('invoiceTermsTitle'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(terms, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _pdfAdSection({
    required String headline,
    required String body,
    required String cta,
    required PdfColor accent,
    required PdfColor badge,
    required PdfColor border,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(headline, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: accent, fontSize: 14)),
          if (body.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(body, style: const pw.TextStyle(fontSize: 11)),
          ],
          if (cta.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: pw.BoxDecoration(
                color: badge,
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Text(cta, style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    final formatted = quantity.toStringAsFixed(2);
    return formatted
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'[.]$'), '');
  }

  String _composeSectionText(
    Invoice invoice,
    Set<InvoiceSectionType> types, {
    String fallback = '',
  }) {
    final values = <String>[];
    if (fallback.trim().isNotEmpty) {
      values.add(fallback.trim());
    }
    for (final section in invoice.document.sections) {
      if (!types.contains(section.type)) continue;
      for (final element in section.elements) {
        final value = element.value.trim();
        if (value.isNotEmpty) {
          values.add(value);
        }
      }
    }
    return values.join('\n\n');
  }

  InvoiceSection? _findSection(Invoice invoice, InvoiceSectionType type) {
    for (final section in invoice.document.sections) {
      if (section.type == type) {
        return section;
      }
    }
    return null;
  }

  String _sectionBindingValue(InvoiceSection section, InvoiceFieldBinding binding) {
    for (final element in section.elements) {
      if (element.binding == binding) {
        return element.value;
      }
    }
    return '';
  }

  pw.Widget _pdfInfoBlock({
    required String title,
    required List<String> body,
    required PdfColor muted,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        for (final line in body)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(line, style: pw.TextStyle(color: muted, fontSize: 11)),
          ),
      ],
    );
  }

  pw.Widget _pdfInfoBadge(String label, String value, PdfColor accent, PdfColor badge) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: badge,
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(color: accent, fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _pdfChip(String text, PdfColor headerText, PdfColor badge) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: badge,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Text(text, style: pw.TextStyle(color: headerText, fontSize: 10)),
    );
  }

  pw.Widget _pdfBadge(String value, PdfColor accent, PdfColor badge) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        color: badge,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Text(value, style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _pdfStatusBadge(String label, PdfColor accent, PdfColor badge) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: pw.BoxDecoration(
        color: badge,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Text(label.toUpperCase(), style: pw.TextStyle(color: accent, fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _pdfLogoPlaceholder(String companyName, PdfColor accent, PdfColor badge) {
    final words = companyName.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    String text;
    if (words.isEmpty) {
      text = 'LOGO';
    } else if (words.length == 1) {
      text = words.first.substring(0, math.min(2, words.first.length)).toUpperCase();
    } else {
      text = (words[0][0] + words[1][0]).toUpperCase();
    }
    return pw.Container(
      width: 64,
      height: 64,
      decoration: pw.BoxDecoration(
        color: badge,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
    );
  }

  String _dueMessage(AppLocalizations l10n, DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = dueDate.difference(today).inDays;
    if (difference > 0) {
      return l10n.textWithReplacement('invoiceDueInDays', {'days': difference.toString()});
    }
    if (difference == 0) {
      return l10n.text('invoiceDueToday');
    }
    return l10n.textWithReplacement('invoiceOverdueInDays', {'days': difference.abs().toString()});
  }

  PdfColor _pdfColorWithOpacity(int value, double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    final alpha = (clamped * 255).round();
    final rgb = value & 0x00FFFFFF;
    return PdfColor.fromInt((alpha << 24) | rgb);
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

  PdfColor _pdfColor(int value) => PdfColor.fromInt(value);

  pw.Alignment _pdfAlignment(Alignment alignment) => pw.Alignment(alignment.x, alignment.y);
}
