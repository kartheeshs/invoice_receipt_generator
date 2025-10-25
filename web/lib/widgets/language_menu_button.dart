import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({
    super.key,
    required this.currentLocale,
    required this.onSelected,
    this.isBusy = false,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.showChevron = true,
  });

  final Locale currentLocale;
  final Future<void> Function(Locale locale) onSelected;
  final bool isBusy;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveForeground = foregroundColor ?? theme.colorScheme.onSurface;
    final effectiveBackground = backgroundColor ?? Colors.transparent;
    final effectiveBorder = borderColor ?? effectiveForeground.withOpacity(0.25);
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: effectiveForeground,
      fontWeight: FontWeight.w600,
    );

    return PopupMenuButton<Locale>(
      tooltip: context.l10n.text('languageSwitchTooltip'),
      enabled: !isBusy,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 12),
      elevation: 6,
      onSelected: (locale) => onSelected(locale),
      itemBuilder: (context) => AppLocalizations.supportedLocales.map((locale) {
        final selected = locale.languageCode == currentLocale.languageCode;
        return PopupMenuItem<Locale>(
          value: locale,
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                _labelForLocale(context, locale),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }).toList(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isBusy ? 0.6 : 1,
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: effectiveBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_outlined, size: 18, color: effectiveForeground),
              const SizedBox(width: 8),
              Text(_labelForLocale(context, currentLocale), style: labelStyle),
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 18, color: effectiveForeground),
              ],
              if (isBusy) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveForeground),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _labelForLocale(BuildContext context, Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return context.l10n.text('languageJapanese');
      default:
        return context.l10n.text('languageEnglish');
    }
  }
}
