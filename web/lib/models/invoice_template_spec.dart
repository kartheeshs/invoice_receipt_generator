import 'package:flutter/material.dart';

import 'invoice.dart';

class InvoiceTemplateSpec {
  const InvoiceTemplateSpec({
    required this.labelKey,
    required this.blurbKey,
    required this.headerGradientColors,
    required this.gradientBegin,
    required this.gradientEnd,
    required this.accentColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.mutedColor,
    required this.headerTextColor,
    required this.balanceBackgroundColor,
    required this.badgeBackgroundColor,
    required this.taglineColor,
    this.headerLayout = 'standard',
    this.infoLayout = 'split',
    this.lineItemStyle = 'card',
    this.totalsStyle = 'badge',
    this.showThankYou = false,
    this.showPaymentDetails = false,
    this.lineItemColumns = const ['Description', 'Qty', 'Rate', 'Total'],
    this.tableHeaderColor = 0xFFE2E8F0,
    this.tableHeaderTextColor = 0xFF0F172A,
    this.canvasBackgroundColor,
    this.highlightColor,
    this.isJapanese = false,
  });

  final String labelKey;
  final String blurbKey;
  final List<int> headerGradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final int accentColor;
  final int surfaceColor;
  final int borderColor;
  final int mutedColor;
  final int headerTextColor;
  final int balanceBackgroundColor;
  final int badgeBackgroundColor;
  final int taglineColor;
  final String headerLayout;
  final String infoLayout;
  final String lineItemStyle;
  final String totalsStyle;
  final bool showThankYou;
  final bool showPaymentDetails;
  final List<String> lineItemColumns;
  final int tableHeaderColor;
  final int tableHeaderTextColor;
  final int? canvasBackgroundColor;
  final int? highlightColor;
  final bool isJapanese;

  LinearGradient get headerGradient => LinearGradient(
        colors: headerGradientColors.map((value) => Color(value)).toList(),
        begin: gradientBegin,
        end: gradientEnd,
      );

  Color get accent => Color(accentColor);
  Color get surface => Color(surfaceColor);
  Color get border => Color(borderColor);
  Color get muted => Color(mutedColor);
  Color get headerText => Color(headerTextColor);
  Color get balanceBackground => Color(balanceBackgroundColor);
  Color get badgeBackground => Color(badgeBackgroundColor);
  Color get tagline => Color(taglineColor);
  Color get tableHeader => Color(tableHeaderColor);
  Color get tableHeaderText => Color(tableHeaderTextColor);
  Color? get canvasBackground =>
      canvasBackgroundColor != null ? Color(canvasBackgroundColor!) : null;
  Color? get highlight => highlightColor != null ? Color(highlightColor!) : null;
}

InvoiceTemplateSpec invoiceTemplateSpec(InvoiceTemplate template) {
  switch (template) {
    case InvoiceTemplate.waveBlue:
      return const InvoiceTemplateSpec(
        labelKey: 'templateWaveBlue',
        blurbKey: 'templateWaveBlueBlurb',
        headerGradientColors: [0xFF0B2E6B, 0xFF1D4ED8],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: 0xFF1D4ED8,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFFE2E8F0,
        mutedColor: 0xFF475569,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFFF1F5FF,
        badgeBackgroundColor: 0xFFEFF6FF,
        taglineColor: 0xFFBFDBFE,
        headerLayout: 'wave',
        infoLayout: 'dualCard',
        lineItemStyle: 'striped',
        totalsStyle: 'badge',
        showThankYou: true,
        showPaymentDetails: true,
        lineItemColumns: ['Description', 'Qty', 'Rate', 'Amount'],
        tableHeaderColor: 0xFF1D4ED8,
        tableHeaderTextColor: 0xFFFFFFFF,
        highlightColor: 0xFF2563EB,
      );
    case InvoiceTemplate.corporateSlate:
      return const InvoiceTemplateSpec(
        labelKey: 'templateCorporateSlate',
        blurbKey: 'templateCorporateSlateBlurb',
        headerGradientColors: [0xFFF8FAFC, 0xFFF8FAFC],
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        accentColor: 0xFF1F2937,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFFE5E7EB,
        mutedColor: 0xFF64748B,
        headerTextColor: 0xFF0F172A,
        balanceBackgroundColor: 0xFFF1F5F9,
        badgeBackgroundColor: 0xFFE2E8F0,
        taglineColor: 0xFF94A3B8,
        headerLayout: 'slate',
        infoLayout: 'twoUp',
        lineItemStyle: 'outlined',
        totalsStyle: 'table',
        showPaymentDetails: true,
        lineItemColumns: ['Description', 'Qty', 'Unit', 'Total'],
        tableHeaderColor: 0xFF1F2937,
        tableHeaderTextColor: 0xFFFFFFFF,
        canvasBackgroundColor: 0xFFF8FAFC,
      );
    case InvoiceTemplate.outlineLedger:
      return const InvoiceTemplateSpec(
        labelKey: 'templateOutlineLedger',
        blurbKey: 'templateOutlineLedgerBlurb',
        headerGradientColors: [0xFFFFFFFF, 0xFFFFFFFF],
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        accentColor: 0xFF111827,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFF1F2937,
        mutedColor: 0xFF111827,
        headerTextColor: 0xFF0F172A,
        balanceBackgroundColor: 0xFFFFFFFF,
        badgeBackgroundColor: 0xFFFFFFFF,
        taglineColor: 0xFF1F2937,
        headerLayout: 'outline',
        infoLayout: 'stacked',
        lineItemStyle: 'ledger',
        totalsStyle: 'underline',
        showPaymentDetails: true,
        lineItemColumns: ['Description', 'Quantity', 'Cost', 'Amount'],
        tableHeaderColor: 0xFFFFFFFF,
        tableHeaderTextColor: 0xFF111827,
        highlightColor: 0xFF111827,
      );
    case InvoiceTemplate.monochromeAccent:
      return const InvoiceTemplateSpec(
        labelKey: 'templateMonochromeAccent',
        blurbKey: 'templateMonochromeAccentBlurb',
        headerGradientColors: [0xFF111827, 0xFF111827],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: 0xFF111827,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFF111827,
        mutedColor: 0xFF4B5563,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFFF3F4F6,
        badgeBackgroundColor: 0xFF111827,
        taglineColor: 0xFF9CA3AF,
        headerLayout: 'monochrome',
        infoLayout: 'splitTall',
        lineItemStyle: 'separated',
        totalsStyle: 'sidePanel',
        showPaymentDetails: true,
        lineItemColumns: ['Description', 'Qty', 'Unit Price', 'Amount'],
        tableHeaderColor: 0xFF111827,
        tableHeaderTextColor: 0xFFFFFFFF,
        highlightColor: 0xFF111827,
      );
    case InvoiceTemplate.emeraldStripe:
      return const InvoiceTemplateSpec(
        labelKey: 'templateEmeraldStripe',
        blurbKey: 'templateEmeraldStripeBlurb',
        headerGradientColors: [0xFF047857, 0xFF0D9488],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: 0xFF047857,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFFD1FAE5,
        mutedColor: 0xFF047857,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFFEFFDF6,
        badgeBackgroundColor: 0xFFDCFCE7,
        taglineColor: 0xFFC4F1DE,
        headerLayout: 'emerald',
        infoLayout: 'pillSplit',
        lineItemStyle: 'stripedLight',
        totalsStyle: 'badge',
        showThankYou: true,
        showPaymentDetails: true,
        lineItemColumns: ['Item', 'Qty', 'Rate', 'Amount'],
        tableHeaderColor: 0xFF047857,
        tableHeaderTextColor: 0xFFFFFFFF,
        highlightColor: 0xFF10B981,
      );
    case InvoiceTemplate.serviceSummary:
      return const InvoiceTemplateSpec(
        labelKey: 'templateServiceSummary',
        blurbKey: 'templateServiceSummaryBlurb',
        headerGradientColors: [0xFF1F4B99, 0xFF2563EB],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: 0xFF1F4B99,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFFE0E7FF,
        mutedColor: 0xFF475569,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFFF1F5FF,
        badgeBackgroundColor: 0xFFE0F2FE,
        taglineColor: 0xFFC7D2FE,
        headerLayout: 'service',
        infoLayout: 'cardGrid',
        lineItemStyle: 'tableHeader',
        totalsStyle: 'stacked',
        showPaymentDetails: true,
        lineItemColumns: ['Product / Service', 'Qty', 'Unit Cost', 'Total'],
        tableHeaderColor: 0xFF2563EB,
        tableHeaderTextColor: 0xFFFFFFFF,
        highlightColor: 0xFF38BDF8,
      );
    case InvoiceTemplate.japaneseBusiness:
      return const InvoiceTemplateSpec(
        labelKey: 'templateJapaneseBusiness',
        blurbKey: 'templateJapaneseBusinessBlurb',
        headerGradientColors: [0xFF7F1D1D, 0xFFE11D48],
        gradientBegin: Alignment.centerLeft,
        gradientEnd: Alignment.centerRight,
        accentColor: 0xFFB91C1C,
        surfaceColor: 0xFFFFFBF5,
        borderColor: 0xFFE4D8CA,
        mutedColor: 0xFF7A6A58,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFFFFF0E5,
        badgeBackgroundColor: 0xFFFFE5D0,
        taglineColor: 0xFFFFD7C2,
        headerLayout: 'japanese',
        infoLayout: 'japanese',
        lineItemStyle: 'japanese',
        totalsStyle: 'japanese',
        showPaymentDetails: true,
        lineItemColumns: ['明細', '数量', '単価', '金額'],
        tableHeaderColor: 0xFF7F1D1D,
        tableHeaderTextColor: 0xFFFFFFFF,
        isJapanese: true,
      );
  }
}
