
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/metric_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onCreateInvoice,
    required this.onOpenSubscription,
    required this.onRequestSignIn,
  });

  final VoidCallback onCreateInvoice;
  final Future<void> Function() onOpenSubscription;
  final Future<void> Function() onRequestSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currency = l10n.currencyFormat(appState.profile.currencyCode, appState.profile.currencySymbol);
        final planLabel = appState.isPremium ? l10n.text('planStatusPremium') : l10n.text('planStatusFree');
        final planBody = appState.isPremium ? l10n.text('planPremiumBody') : l10n.text('planFreeBody');
        final priceText = l10n.textWithReplacement('planPriceLabelLocalized', {
          'price': currency.format(appState.planPrice),
        });
        final isGuest = appState.isGuest;
        final isLocaleChanging = appState.isLocaleChanging;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGuest) ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.text('guestModeTitle'),
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(l10n.text('guestModeBody')),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => onRequestSignIn(),
                          child: Text(l10n.text('signInButton')),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: 320,
                    child: MetricCard(
                      title: l10n.text('totalInvoices'),
                      value: appState.invoices.length.toString(),
                      subtitle: l10n.text('quickActions'),
                      icon: Icons.receipt_long,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: MetricCard(
                      title: l10n.text('outstanding'),
                      value: currency.format(appState.outstandingTotal),
                      icon: Icons.pending_actions,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: MetricCard(
                      title: l10n.text('paid'),
                      value: currency.format(appState.paidTotal),
                      icon: Icons.payments,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: MetricCard(
                      title: l10n.text('averageInvoice'),
                      value: currency.format(appState.averageInvoice),
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.text('subscriptionTitle'),
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  planLabel,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(planBody),
                                const SizedBox(height: 12),
                                Text('${l10n.text('monthlyPrice')}: $priceText'),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => onOpenSubscription(),
                            icon: const Icon(Icons.workspace_premium),
                            label: Text(appState.isPremium
                                ? l10n.text('manageSubscription')
                                : l10n.text('subscribeCrisp')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.text('planBenefits'), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(l10n.text('planBenefitsBody')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.receipt_long,
                      title: l10n.text('createInvoiceAction'),
                      subtitle: l10n.text('invoicesEmptyBody'),
                      onPressed: onCreateInvoice,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.language,
                      title: l10n.text('languageSectionLabel'),
                      subtitle: l10n.text('languageLabel'),
                      onPressed: isLocaleChanging
                          ? null
                          : () {
                              final target =
                                  appState.locale.languageCode == 'en' ? const Locale('ja') : const Locale('en');
                              context.read<AppState>().setLocale(target);
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(l10n.text('recentInvoices'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (isGuest)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.text('guestInvoicesLockedTitle'),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(l10n.text('guestInvoicesLockedBody')),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => onRequestSignIn(),
                          child: Text(l10n.text('signInButton')),
                        ),
                      ],
                    ),
                  ),
                )
              else if (appState.recentInvoices.isEmpty)
                Text(l10n.text('invoicesEmptyBody'))
              else
                Column(
                  children: appState.recentInvoices
                      .map(
                        (invoice) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          title: Text(invoice.clientName.isEmpty ? invoice.number : invoice.clientName),
                          subtitle: Text('${invoice.projectName} • ${l10n.dateFormat.format(invoice.issueDate)}'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(currency.format(invoice.amount)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.invoiceStatusLabel(invoice.status),
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: isDisabled
              ? theme.colorScheme.surfaceVariant.withOpacity(0.6)
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: isDisabled ? theme.disabledColor : null),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDisabled ? theme.disabledColor : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDisabled ? theme.disabledColor.withOpacity(0.8) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
