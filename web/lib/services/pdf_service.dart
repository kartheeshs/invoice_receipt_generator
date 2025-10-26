// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' show PdfGoogleFonts;

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_template_spec.dart';
import '../models/user_profile.dart';

class PdfService {
  _PdfFontBundle? _fontBundle;

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
    final fonts = await _ensureFonts();

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
        theme: fonts.theme,
        build: (context) {
          final maxWidth = context.page.pageFormat.availableWidth;
          return [
            pw.DefaultTextStyle.merge(
              style: pw.TextStyle(fontFallback: fonts.fallback),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: content
                    .map((widget) => pw.SizedBox(width: maxWidth, child: widget))
                    .toList(),
              ),
            ),
          ];
        },
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
    final palette = _PdfPalette(
      accent: _pdfColor(spec.accentColor),
      headerText: _pdfColor(spec.headerTextColor),
      border: _pdfColor(spec.borderColor),
      badge: _pdfColor(spec.badgeBackgroundColor),
      muted: _pdfColor(spec.mutedColor),
      balanceBackground: _pdfColor(spec.balanceBackgroundColor),
      surface: _pdfColor(spec.surfaceColor),
      tagline: _pdfColor(spec.taglineColor),
      tableHeader: _pdfColor(spec.tableHeaderColor),
      tableHeaderText: _pdfColor(spec.tableHeaderTextColor),
      highlight: spec.highlightColor != null ? _pdfColor(spec.highlightColor!) : null,
      headerGradient: spec.headerGradientColors.map(_pdfColor).toList(),
      canvasBackground: spec.canvasBackgroundColor != null ? _pdfColor(spec.canvasBackgroundColor!) : null,
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
    final subtotal = lineItems.fold<double>(0, (value, item) => value + item.total);
    final amountText = format.format(subtotal);
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
    final tagline = _bindingValueFromDocument(invoice, InvoiceFieldBinding.companyTagline,
        fallback: profile.tagline);
    final bankDetails = _bindingValueFromDocument(invoice, InvoiceFieldBinding.bankDetails);
    final clientCompany = _bindingValueFromDocument(invoice, InvoiceFieldBinding.clientCompany, fallback: client);
    final clientAddress = _bindingValueFromDocument(invoice, InvoiceFieldBinding.clientAddress);
    final companyAddress = profile.address.isNotEmpty
        ? profile.address
        : _bindingValueFromDocument(invoice, InvoiceFieldBinding.companyAddress);
    final companyPhone = profile.phone.isNotEmpty
        ? profile.phone
        : _bindingValueFromDocument(invoice, InvoiceFieldBinding.companyPhone);
    final companyTaxId = profile.taxId.isNotEmpty
        ? profile.taxId
        : _bindingValueFromDocument(invoice, InvoiceFieldBinding.companyTaxId);
    final invoiceTitle = _bindingValueFromDocument(
      invoice,
      InvoiceFieldBinding.invoiceTitle,
      fallback: l10n.text('invoicePreviewTitle'),
    );
    final invoiceNumber = _bindingValueFromDocument(
      invoice,
      InvoiceFieldBinding.invoiceNumber,
      fallback: invoice.number,
    );

    final args = _PdfBuildArgs(
      invoice: invoice,
      profile: profile,
      format: format,
      dateFormat: dateFormat,
      spec: spec,
      l10n: l10n,
      lineItems: lineItems,
      subtotal: subtotal,
      amountText: amountText,
      dueMessage: dueMessage,
      statusLabel: statusLabel,
      companyName: companyName,
      projectName: project,
      clientName: client,
      clientCompany: clientCompany,
      clientAddress: clientAddress,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
      companyTaxId: companyTaxId,
      description: description,
      notesText: notesText,
      termsText: termsText,
      bankDetails: bankDetails,
      adHeadline: adHeadline,
      adBody: adBody,
      adCta: adCta,
      tagline: tagline,
      invoiceTitle: invoiceTitle,
      invoiceNumber: invoiceNumber,
    );

    switch (invoice.template) {
      case InvoiceTemplate.waveBlue:
        return _buildWaveBluePdf(args, palette);
      case InvoiceTemplate.corporateSlate:
        return _buildCorporateSlatePdf(args, palette);
      case InvoiceTemplate.outlineLedger:
        return _buildOutlineLedgerPdf(args, palette);
      case InvoiceTemplate.monochromeAccent:
        return _buildMonochromeAccentPdf(args, palette);
      case InvoiceTemplate.emeraldStripe:
        return _buildEmeraldStripePdf(args, palette);
      case InvoiceTemplate.serviceSummary:
        return _buildServiceSummaryPdf(args, palette);
      case InvoiceTemplate.japaneseBusiness:
        return const <pw.Widget>[];
    }
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
    required PdfColor badge,
    required AppLocalizations l10n,
    List<String>? columnLabels,
    PdfColor? background,
  }) {
    final labels = columnLabels != null && columnLabels.length == 4
        ? columnLabels
        : [
            l10n.text('invoiceSummaryDescription'),
            l10n.text('invoiceSummaryPrice'),
            l10n.text('invoiceSummaryQty'),
            l10n.text('invoiceSummaryAmount'),
          ];
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(22),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              color: badge,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(22)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(labels[0],
                      style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Text(labels[1],
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Text(labels[2],
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(color: accent, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Expanded(
                  child: pw.Text(labels[3],
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

  String _bindingValueFromDocument(
    Invoice invoice,
    InvoiceFieldBinding binding, {
    String fallback = '',
  }) {
    for (final section in invoice.document.sections) {
      for (final element in section.elements) {
        final value = element.value.trim();
        if (element.binding == binding && value.isNotEmpty) {
          return value;
        }
      }
    }
    return fallback;
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

  List<pw.Widget> _buildWaveBluePdf(_PdfBuildArgs args, _PdfPalette palette) {
    final headerGradient = pw.LinearGradient(
      colors: palette.headerGradient,
      begin: _pdfAlignment(args.spec.gradientBegin),
      end: _pdfAlignment(args.spec.gradientEnd),
    );
    final headerChips = <pw.Widget>[];
    if (args.profile.address.isNotEmpty) {
      headerChips.add(_pdfChip(args.profile.address, palette.headerText, palette.badge));
    }
    if (args.profile.phone.isNotEmpty) {
      headerChips.add(_pdfChip(args.profile.phone, palette.headerText, palette.badge));
    }
    if (args.profile.email.isNotEmpty) {
      headerChips.add(_pdfChip(args.profile.email, palette.headerText, palette.badge));
    }

    return [
      pw.Container(
        decoration: pw.BoxDecoration(
          gradient: headerGradient,
          borderRadius: pw.BorderRadius.circular(24),
          border: pw.Border.all(color: palette.border, width: 1),
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
                        args.companyName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: palette.headerText,
                        ),
                      ),
                      if (args.tagline.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 6),
                          child: pw.Text(
                            args.tagline,
                            style: pw.TextStyle(color: palette.tagline, fontSize: 12),
                          ),
                        ),
                      if (headerChips.isNotEmpty) ...[
                        pw.SizedBox(height: 18),
                        pw.Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: headerChips,
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _pdfLogoPlaceholder(args.companyName, palette.accent, palette.badge),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      args.invoiceTitle.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: palette.headerText,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _pdfBadge(args.invoiceNumber, palette.accent, palette.badge),
                    pw.SizedBox(height: 12),
                    _pdfStatusBadge(args.statusLabel, palette.accent, palette.badge),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _pdfInfoBadge(
                  args.l10n.text('invoiceIssuedLabel'),
                  args.dateFormat.format(args.invoice.issueDate),
                  palette.accent,
                  palette.badge,
                ),
                _pdfInfoBadge(
                  args.l10n.text('invoiceDueLabel'),
                  args.dateFormat.format(args.invoice.dueDate),
                  palette.accent,
                  palette.badge,
                ),
                _pdfInfoBadge(
                  args.l10n.text('invoiceTimelineLabel'),
                  args.dueMessage,
                  palette.accent,
                  palette.badge,
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 24),
      pw.Container(
        decoration: pw.BoxDecoration(
          color: palette.surface,
          borderRadius: pw.BorderRadius.circular(20),
          border: pw.Border.all(color: palette.border, width: 1),
        ),
        padding: const pw.EdgeInsets.all(20),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _pdfInfoBlock(
                title: args.l10n.text('companyDetailsTitle'),
                body: [
                  args.profile.displayName,
                  if (args.companyTaxId.isNotEmpty)
                    args.l10n.text('taxIdLabel') + ': ${args.companyTaxId}',
                  if (args.profile.email.isNotEmpty) args.profile.email,
                  if (args.companyPhone.isNotEmpty) args.companyPhone,
                  if (args.companyAddress.isNotEmpty) args.companyAddress,
                ],
                muted: palette.muted,
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _pdfInfoBlock(
                title: args.l10n.text('clientDetailsTitle'),
                body: [
                  args.clientCompany,
                  if (args.clientAddress.isNotEmpty) args.clientAddress,
                  if (args.projectName.isNotEmpty)
                    args.l10n.text('projectLabel') + ': ${args.projectName}',
                ],
                muted: palette.muted,
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _pdfInfoBlock(
                title: args.l10n.text('invoiceMetaTitle'),
                body: [
                  '${args.l10n.text('invoiceIssuedLabel')}: ${args.dateFormat.format(args.invoice.issueDate)}',
                  '${args.l10n.text('invoiceDueLabel')}: ${args.dateFormat.format(args.invoice.dueDate)}',
                  '${args.l10n.text('statusLabel')}: ${args.statusLabel}',
                ],
                muted: palette.muted,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 24),
      _pdfSummaryTable(
        items: args.lineItems,
        format: args.format,
        accent: palette.accent,
        border: palette.border,
        muted: palette.muted,
        badge: palette.badge,
        l10n: args.l10n,
        columnLabels: args.spec.lineItemColumns,
      ),
      pw.SizedBox(height: 24),
      _pdfBalanceCard(
        amountText: args.amountText,
        dueMessage: args.dueMessage,
        balanceBackground: palette.balanceBackground,
        headerText: palette.headerText,
        headerTextValue: args.spec.headerTextColor,
        l10n: args.l10n,
      ),
      ..._buildOptionalSections(
        args,
        palette: palette,
      ),
    ];
  }

  List<pw.Widget> _buildCorporateSlatePdf(_PdfBuildArgs args, _PdfPalette palette) {
    final header = pw.Container(
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: pw.BorderRadius.circular(24),
        border: pw.Border.all(color: _pdfColorWithOpacity(args.spec.borderColor, 0.6), width: 1),
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
                      args.companyName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: palette.accent,
                      ),
                    ),
                    if (args.companyAddress.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 6),
                        child: pw.Text(args.companyAddress, style: pw.TextStyle(color: palette.muted, fontSize: 11)),
                      ),
                    if (args.companyPhone.isNotEmpty || args.profile.email.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: pw.Text(
                          [args.companyPhone, args.profile.email].where((value) => value.isNotEmpty).join(' • '),
                          style: pw.TextStyle(color: palette.muted, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    args.invoiceTitle,
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: palette.accent),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${args.l10n.text('invoiceNumberLabel')}: ${args.invoiceNumber}',
                    style: pw.TextStyle(color: palette.muted, fontSize: 11),
                  ),
                  pw.Text(
                    '${args.l10n.text('invoiceIssuedLabel')}: ${args.dateFormat.format(args.invoice.issueDate)}',
                    style: pw.TextStyle(color: palette.muted, fontSize: 11),
                  ),
                  pw.Text(
                    '${args.l10n.text('invoiceDueLabel')}: ${args.dateFormat.format(args.invoice.dueDate)}',
                    style: pw.TextStyle(color: palette.muted, fontSize: 11),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: _pdfStatusBadge(args.statusLabel, palette.accent, palette.badge),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _pdfInfoBlock(
                  title: args.l10n.text('billToLabel'),
                  body: [
                    args.clientCompany,
                    if (args.clientAddress.isNotEmpty) args.clientAddress,
                    if (args.clientName.isNotEmpty)
                      args.l10n.text('contactLabel') + ': ${args.clientName}',
                  ],
                  muted: palette.muted,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _pdfInfoBlock(
                  title: args.l10n.text('projectLabel'),
                  body: [args.projectName, if (args.description.isNotEmpty) args.description],
                  muted: palette.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final table = _pdfLedgerTable(
      args,
      palette: palette,
      headerFill: palette.tableHeader,
      headerText: palette.tableHeaderText,
      showStriped: false,
    );

    final totals = pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _pdfSummaryTotalRow(args.l10n.text('invoiceSummarySubtotal'), args.format.format(args.subtotal)),
          pw.SizedBox(height: 4),
          _pdfSummaryTotalRow(
            args.l10n.text('invoiceSummaryTotal'),
            args.amountText,
            emphasized: true,
          ),
        ],
      ),
    );

    return [
      header,
      pw.SizedBox(height: 24),
      table,
      totals,
      ..._buildOptionalSections(
        args,
        palette: palette,
      ),
    ];
  }

  List<pw.Widget> _buildOutlineLedgerPdf(_PdfBuildArgs args, _PdfPalette palette) {
    final header = pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: palette.border, width: 1.2),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  args.companyName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: palette.accent),
                ),
                if (args.companyAddress.isNotEmpty)
                  pw.Text(args.companyAddress, style: pw.TextStyle(color: palette.muted, fontSize: 10)),
                if (args.profile.email.isNotEmpty || args.companyPhone.isNotEmpty)
                  pw.Text(
                    [args.profile.email, args.companyPhone].where((value) => value.isNotEmpty).join(' / '),
                    style: pw.TextStyle(color: palette.muted, fontSize: 10),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(args.invoiceTitle, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('${args.l10n.text('invoiceNumberLabel')}: ${args.invoiceNumber}',
                  style: pw.TextStyle(color: palette.muted, fontSize: 10)),
              pw.Text('${args.l10n.text('invoiceIssuedLabel')}: ${args.dateFormat.format(args.invoice.issueDate)}',
                  style: pw.TextStyle(color: palette.muted, fontSize: 10)),
              pw.Text('${args.l10n.text('invoiceDueLabel')}: ${args.dateFormat.format(args.invoice.dueDate)}',
                  style: pw.TextStyle(color: palette.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );

    final billing = pw.Container(
      margin: const pw.EdgeInsets.only(top: 18),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: palette.border, width: 1.2),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      padding: const pw.EdgeInsets.all(18),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('billToLabel'),
              body: [
                args.clientCompany,
                if (args.clientName.isNotEmpty)
                  args.l10n.text('contactLabel') + ': ${args.clientName}',
                if (args.clientAddress.isNotEmpty) args.clientAddress,
              ],
              muted: palette.muted,
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('projectLabel'),
              body: [args.projectName, if (args.description.isNotEmpty) args.description],
              muted: palette.muted,
            ),
          ),
        ],
      ),
    );

    final table = _pdfLedgerTable(
      args,
      palette: palette,
      headerFill: palette.surface,
      headerText: palette.accent,
      showStriped: true,
    );

    final footer = pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: palette.border, width: 1.2),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(args.l10n.text('paymentDetailsTitle'),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (args.bankDetails.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(args.bankDetails, style: pw.TextStyle(color: palette.muted, fontSize: 10)),
                  ),
                if (args.termsText.isEmpty && args.bankDetails.isEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(args.l10n.text('invoiceThankYou'),
                        style: pw.TextStyle(color: palette.muted, fontSize: 10)),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _pdfSummaryTotalRow(args.l10n.text('invoiceSummarySubtotal'), args.format.format(args.subtotal)),
              pw.SizedBox(height: 6),
              _pdfSummaryTotalRow(
                args.l10n.text('invoiceSummaryTotal'),
                args.amountText,
                emphasized: true,
              ),
            ],
          ),
        ],
      ),
    );

    return [
      header,
      billing,
      pw.SizedBox(height: 18),
      table,
      footer,
      ..._buildOptionalSections(
        args,
        palette: palette,
        borderOverride: palette.border,
        surfaceOverride: palette.surface,
      ),
    ];
  }

  List<pw.Widget> _buildMonochromeAccentPdf(_PdfBuildArgs args, _PdfPalette palette) {
    final header = pw.Container(
      decoration: pw.BoxDecoration(
        color: palette.accent,
        borderRadius: pw.BorderRadius.circular(26),
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
                  args.companyName,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
                if (args.tagline.isNotEmpty)
                  pw.Text(args.tagline, style: pw.TextStyle(color: _pdfColorWithOpacity(0xFFFFFFFF, 0.9), fontSize: 12)),
                pw.SizedBox(height: 16),
                pw.Text(
                  args.invoiceTitle.toUpperCase(),
                  style: pw.TextStyle(color: _pdfColorWithOpacity(0xFFFFFFFF, 0.9), fontSize: 14, letterSpacing: 2),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  args.invoiceNumber,
                  style: pw.TextStyle(color: _pdfColorWithOpacity(0xFFFFFFFF, 0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _pdfLogoPlaceholder(args.companyName, palette.accent, PdfColors.white),
              pw.SizedBox(height: 12),
              _pdfStatusBadge(args.statusLabel, PdfColors.white, _pdfColorWithOpacity(0xFFFFFFFF, 0.2)),
            ],
          ),
        ],
      ),
    );

    final infoRow = pw.Container(
      margin: const pw.EdgeInsets.only(top: 24),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: palette.border, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('billToLabel'),
              body: [args.clientCompany, if (args.clientAddress.isNotEmpty) args.clientAddress],
              muted: palette.muted,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('invoiceMetaTitle'),
              body: [
                '${args.l10n.text('invoiceIssuedLabel')}: ${args.dateFormat.format(args.invoice.issueDate)}',
                '${args.l10n.text('invoiceDueLabel')}: ${args.dateFormat.format(args.invoice.dueDate)}',
                args.dueMessage,
              ],
              muted: palette.muted,
            ),
          ),
        ],
      ),
    );

    final table = _pdfLedgerTable(
      args,
      palette: palette,
      headerFill: palette.tableHeader,
      headerText: palette.tableHeaderText,
      showStriped: true,
      rowBackground: palette.canvasBackground,
    );

    final totals = pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: palette.border, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(args.l10n.text('invoiceThankYou'),
                    style: pw.TextStyle(color: palette.muted, fontSize: 10)),
                if (args.bankDetails.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(args.bankDetails, style: pw.TextStyle(color: palette.muted, fontSize: 10)),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _pdfSummaryTotalRow(args.l10n.text('invoiceSummarySubtotal'), args.format.format(args.subtotal)),
              pw.SizedBox(height: 4),
              _pdfSummaryTotalRow(
                args.l10n.text('invoiceSummaryTotal'),
                args.amountText,
                emphasized: true,
              ),
            ],
          ),
        ],
      ),
    );

    return [
      header,
      infoRow,
      pw.SizedBox(height: 16),
      table,
      totals,
      ..._buildOptionalSections(
        args,
        palette: palette,
        borderOverride: palette.border,
        surfaceOverride: palette.surface,
      ),
    ];
  }

  List<pw.Widget> _buildEmeraldStripePdf(_PdfBuildArgs args, _PdfPalette palette) {
    final headerGradient = pw.LinearGradient(
      colors: palette.headerGradient,
      begin: _pdfAlignment(args.spec.gradientBegin),
      end: _pdfAlignment(args.spec.gradientEnd),
    );

    final header = pw.Container(
      decoration: pw.BoxDecoration(
        gradient: headerGradient,
        borderRadius: pw.BorderRadius.circular(26),
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
                      args.companyName,
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 22),
                    ),
                    if (args.tagline.isNotEmpty)
                      pw.Text(args.tagline, style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                    pw.SizedBox(height: 16),
                    _pdfInfoBadge(
                      args.l10n.text('invoiceNumberLabel'),
                      args.invoiceNumber,
                      PdfColors.white,
                      _pdfColorWithOpacity(0xFFFFFFFF, 0.2),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _pdfStatusBadge(args.statusLabel, PdfColors.white, _pdfColorWithOpacity(0xFFFFFFFF, 0.2)),
                  pw.SizedBox(height: 12),
                  _pdfInfoBadge(
                    args.l10n.text('invoiceDueLabel'),
                    args.dateFormat.format(args.invoice.dueDate),
                    PdfColors.white,
                    _pdfColorWithOpacity(0xFFFFFFFF, 0.2),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            args.l10n.text('invoiceSummaryTotal'),
            style: pw.TextStyle(color: _pdfColorWithOpacity(0xFFFFFFFF, 0.8), fontSize: 10),
          ),
          pw.Text(
            args.amountText,
            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 24),
          ),
        ],
      ),
    );

    final project = pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: palette.border, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('projectLabel'),
              body: [args.projectName, if (args.description.isNotEmpty) args.description],
              muted: palette.muted,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('billToLabel'),
              body: [args.clientCompany, if (args.clientAddress.isNotEmpty) args.clientAddress],
              muted: palette.muted,
            ),
          ),
        ],
      ),
    );

    final table = _pdfSummaryTable(
      items: args.lineItems,
      format: args.format,
      accent: palette.accent,
      border: palette.border,
      muted: palette.muted,
      badge: palette.badge,
      l10n: args.l10n,
      columnLabels: args.spec.lineItemColumns,
      background: palette.surface,
    );

    return [
      header,
      project,
      pw.SizedBox(height: 20),
      table,
      ..._buildOptionalSections(
        args,
        palette: palette,
      ),
    ];
  }

  List<pw.Widget> _buildServiceSummaryPdf(_PdfBuildArgs args, _PdfPalette palette) {
    final headerGradient = pw.LinearGradient(
      colors: palette.headerGradient,
      begin: _pdfAlignment(args.spec.gradientBegin),
      end: _pdfAlignment(args.spec.gradientEnd),
    );
    final header = pw.Container(
      decoration: pw.BoxDecoration(
        gradient: headerGradient,
        borderRadius: pw.BorderRadius.circular(24),
      ),
      padding: const pw.EdgeInsets.all(26),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(args.companyName,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                if (args.profile.email.isNotEmpty)
                pw.Text(args.profile.email,
                    style: pw.TextStyle(color: _pdfColorWithOpacity(0xFFFFFFFF, 0.9), fontSize: 11)),
                if (args.companyPhone.isNotEmpty)
                  pw.Text(args.companyPhone,
                      style: pw.TextStyle(color: _pdfColorWithOpacity(0xFFFFFFFF, 0.9), fontSize: 11)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _pdfStatusBadge(args.statusLabel, PdfColors.white, _pdfColorWithOpacity(0xFFFFFFFF, 0.2)),
              pw.SizedBox(height: 12),
              pw.Text(args.amountText,
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                args.dueMessage,
                style: pw.TextStyle(color: _pdfColorWithOpacity(0xFFFFFFFF, 0.9), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );

    final clientCard = pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: palette.surface,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: palette.border, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('billToLabel'),
              body: [args.clientCompany, if (args.clientAddress.isNotEmpty) args.clientAddress],
              muted: palette.muted,
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: _pdfInfoBlock(
              title: args.l10n.text('projectLabel'),
              body: [args.projectName, if (args.description.isNotEmpty) args.description],
              muted: palette.muted,
            ),
          ),
        ],
      ),
    );

    final table = _pdfSummaryTable(
      items: args.lineItems,
      format: args.format,
      accent: palette.accent,
      border: palette.border,
      muted: palette.muted,
      badge: palette.badge,
      l10n: args.l10n,
      columnLabels: args.spec.lineItemColumns,
    );

    final totals = pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _pdfSummaryTotalRow(args.l10n.text('invoiceSummarySubtotal'), args.format.format(args.subtotal)),
          pw.SizedBox(height: 4),
          _pdfSummaryTotalRow(
            args.l10n.text('invoiceSummaryTotal'),
            args.amountText,
            emphasized: true,
          ),
        ],
      ),
    );

    return [
      header,
      clientCard,
      pw.SizedBox(height: 20),
      table,
      totals,
      ..._buildOptionalSections(
        args,
        palette: palette,
      ),
    ];
  }

  List<pw.Widget> _buildOptionalSections(
    _PdfBuildArgs args, {
    required _PdfPalette palette,
    PdfColor? borderOverride,
    PdfColor? surfaceOverride,
  }) {
    final widgets = <pw.Widget>[];
    final border = borderOverride ?? palette.border;
    final surface = surfaceOverride ?? palette.surface;

    if (args.notesText.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: 18))
        ..add(_pdfNotesSection(args.notesText, border, surface, args.l10n));
    }
    if (args.termsText.isNotEmpty || args.bankDetails.isNotEmpty) {
      final combined = [args.termsText, args.bankDetails].where((value) => value.trim().isNotEmpty).join('\n\n');
      widgets
        ..add(pw.SizedBox(height: 18))
        ..add(_pdfTermsSection(combined, border, surface, args.l10n));
    }
    if (args.adHeadline.isNotEmpty || args.adBody.isNotEmpty || args.adCta.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: 18))
        ..add(
          _pdfAdSection(
            headline: args.adHeadline,
            body: args.adBody,
            cta: args.adCta,
            accent: palette.accent,
            badge: palette.badge,
            border: border,
          ),
        );
    }
    return widgets;
  }

  pw.Widget _pdfLedgerTable(
    _PdfBuildArgs args, {
    required _PdfPalette palette,
    required PdfColor headerFill,
    required PdfColor headerText,
    bool showStriped = false,
    PdfColor? rowBackground,
  }) {
    final headers = args.spec.lineItemColumns;
    final stripeColor = rowBackground ??
        _pdfColorWithOpacity(
          args.spec.highlightColor ?? args.spec.badgeBackgroundColor,
          0.08,
        );
    const columnWidths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(4),
      1: pw.FlexColumnWidth(2),
      2: pw.FlexColumnWidth(2),
      3: pw.FlexColumnWidth(2),
    };
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: palette.border, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              color: headerFill,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(20)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: pw.Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  children: [
                    _pdfLedgerHeaderCell(headers[0], headerText, pw.TextAlign.left),
                    _pdfLedgerHeaderCell(headers[1], headerText, pw.TextAlign.center),
                    _pdfLedgerHeaderCell(headers[2], headerText, pw.TextAlign.center),
                    _pdfLedgerHeaderCell(headers[3], headerText, pw.TextAlign.right),
                  ],
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: pw.Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                for (var index = 0; index < args.lineItems.length; index++)
                  pw.TableRow(
                    decoration:
                        showStriped && index.isOdd ? pw.BoxDecoration(color: stripeColor) : null,
                    children: [
                      _pdfLedgerDescriptionCell(args, index, palette.muted),
                      _pdfLedgerValueCell(
                        args.format.format(args.lineItems[index].unitPrice),
                        pw.TextAlign.center,
                      ),
                      _pdfLedgerValueCell(
                        _formatQuantity(args.lineItems[index].quantity),
                        pw.TextAlign.center,
                      ),
                      _pdfLedgerValueCell(
                        args.format.format(args.lineItems[index].total),
                        pw.TextAlign.right,
                        emphasized: true,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfLedgerHeaderCell(String text, PdfColor color, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 11),
      ),
    );
  }

  pw.Widget _pdfLedgerDescriptionCell(_PdfBuildArgs args, int index, PdfColor muted) {
    final item = args.lineItems[index];
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.description,
            style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          if (item.notes?.isNotEmpty == true)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                item.notes!,
                style: pw.TextStyle(color: muted, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfLedgerValueCell(
    String value,
    pw.TextAlign align, {
    bool emphasized = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
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

  Future<_PdfFontBundle> _ensureFonts() async {
    final cached = _fontBundle;
    if (cached != null) {
      return cached;
    }

    final bundle = _PdfFontBundle(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
      italic: await PdfGoogleFonts.robotoItalic(),
      boldItalic: await PdfGoogleFonts.robotoBoldItalic(),
      fallback: <pw.Font>[
        await PdfGoogleFonts.notoSansRegular(),
        await PdfGoogleFonts.notoSansJPRegular(),
      ],
    );
    _fontBundle = bundle;
    return bundle;
  }

  PdfColor _pdfColor(int value) => PdfColor.fromInt(value);

  pw.Alignment _pdfAlignment(Alignment alignment) => pw.Alignment(alignment.x, alignment.y);
}

class _PdfFontBundle {
  _PdfFontBundle({
    required this.base,
    required this.bold,
    required this.italic,
    required this.boldItalic,
    required this.fallback,
  });

  final pw.Font base;
  final pw.Font bold;
  final pw.Font italic;
  final pw.Font boldItalic;
  final List<pw.Font> fallback;

  pw.ThemeData get theme => pw.ThemeData.withFont(
        base: base,
        bold: bold,
        italic: italic,
        boldItalic: boldItalic,
        fallback: fallback,
      );
}

class _PdfPalette {
  const _PdfPalette({
    required this.accent,
    required this.headerText,
    required this.border,
    required this.badge,
    required this.muted,
    required this.balanceBackground,
    required this.surface,
    required this.tagline,
    required this.tableHeader,
    required this.tableHeaderText,
    required this.headerGradient,
    this.highlight,
    this.canvasBackground,
  });

  final PdfColor accent;
  final PdfColor headerText;
  final PdfColor border;
  final PdfColor badge;
  final PdfColor muted;
  final PdfColor balanceBackground;
  final PdfColor surface;
  final PdfColor tagline;
  final PdfColor tableHeader;
  final PdfColor tableHeaderText;
  final List<PdfColor> headerGradient;
  final PdfColor? highlight;
  final PdfColor? canvasBackground;
}

class _PdfBuildArgs {
  const _PdfBuildArgs({
    required this.invoice,
    required this.profile,
    required this.format,
    required this.dateFormat,
    required this.spec,
    required this.l10n,
    required this.lineItems,
    required this.subtotal,
    required this.amountText,
    required this.dueMessage,
    required this.statusLabel,
    required this.companyName,
    required this.projectName,
    required this.clientName,
    required this.clientCompany,
    required this.clientAddress,
    required this.companyAddress,
    required this.companyPhone,
    required this.companyTaxId,
    required this.description,
    required this.notesText,
    required this.termsText,
    required this.bankDetails,
    required this.adHeadline,
    required this.adBody,
    required this.adCta,
    required this.tagline,
    required this.invoiceTitle,
    required this.invoiceNumber,
  });

  final Invoice invoice;
  final UserProfile profile;
  final NumberFormat format;
  final DateFormat dateFormat;
  final InvoiceTemplateSpec spec;
  final AppLocalizations l10n;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final String amountText;
  final String dueMessage;
  final String statusLabel;
  final String companyName;
  final String projectName;
  final String clientName;
  final String clientCompany;
  final String clientAddress;
  final String companyAddress;
  final String companyPhone;
  final String companyTaxId;
  final String description;
  final String notesText;
  final String termsText;
  final String bankDetails;
  final String adHeadline;
  final String adBody;
  final String adCta;
  final String tagline;
  final String invoiceTitle;
  final String invoiceNumber;
}
