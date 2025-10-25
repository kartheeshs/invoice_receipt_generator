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
}

InvoiceTemplateSpec invoiceTemplateSpec(InvoiceTemplate template) {
  switch (template) {
    case InvoiceTemplate.classic:
      return const InvoiceTemplateSpec(
        labelKey: 'templateClassic',
        blurbKey: 'templateClassicBlurb',
        headerGradientColors: [0xFF0F172A, 0xFF1D4ED8],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: 0xFF1D4ED8,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFFE2E8F0,
        mutedColor: 0xFF64748B,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFF0F172A,
        badgeBackgroundColor: 0xFFEFF4FF,
        taglineColor: 0xFFCBD5F5,
      );
    case InvoiceTemplate.modern:
      return const InvoiceTemplateSpec(
        labelKey: 'templateModern',
        blurbKey: 'templateModernBlurb',
        headerGradientColors: [0xFF0F766E, 0xFF2563EB],
        gradientBegin: Alignment.topCenter,
        gradientEnd: Alignment.bottomCenter,
        accentColor: 0xFF0F766E,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFFD1FAE5,
        mutedColor: 0xFF0F766E,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFFDCFCE7,
        badgeBackgroundColor: 0xFFE0F2FE,
        taglineColor: 0xFFCCFBF1,
      );
    case InvoiceTemplate.minimal:
      return const InvoiceTemplateSpec(
        labelKey: 'templateMinimal',
        blurbKey: 'templateMinimalBlurb',
        headerGradientColors: [0xFF111827, 0xFF374151],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: 0xFF111827,
        surfaceColor: 0xFFFAFAFA,
        borderColor: 0xFFE5E7EB,
        mutedColor: 0xFF6B7280,
        headerTextColor: 0xFFF9FAFB,
        balanceBackgroundColor: 0xFF111827,
        badgeBackgroundColor: 0xFFF3F4F6,
        taglineColor: 0xFFD1D5DB,
      );
    case InvoiceTemplate.executive:
      return const InvoiceTemplateSpec(
        labelKey: 'templateExecutive',
        blurbKey: 'templateExecutiveBlurb',
        headerGradientColors: [0xFF581C87, 0xFFDC2626],
        gradientBegin: Alignment.topLeft,
        gradientEnd: Alignment.bottomRight,
        accentColor: 0xFFB91C1C,
        surfaceColor: 0xFFFFFFFF,
        borderColor: 0xFFE7E3EE,
        mutedColor: 0xFF7C7C7C,
        headerTextColor: 0xFFFFFFFF,
        balanceBackgroundColor: 0xFF2D0A3C,
        badgeBackgroundColor: 0xFFFDE8F3,
        taglineColor: 0xFFF3D1E1,
      );
    case InvoiceTemplate.japanese:
      return const InvoiceTemplateSpec(
        labelKey: 'templateJapanese',
        blurbKey: 'templateJapaneseBlurb',
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
        isJapanese: true,
      );
  }
}
