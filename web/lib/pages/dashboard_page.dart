
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
                _GuestBanner(onRequestSignIn: onRequestSignIn, l10n: l10n),
                const SizedBox(height: 24),
              ],
              _MetricGrid(
                metrics: [
                  _MetricDatum(l10n.text('totalInvoices'), appState.invoices.length.toString(), Icons.receipt_long),
                  _MetricDatum(l10n.text('outstanding'), currency.format(appState.outstandingTotal), Icons.pending_actions),
                  _MetricDatum(l10n.text('paid'), currency.format(appState.paidTotal), Icons.payments),
                  _MetricDatum(l10n.text('averageInvoice'), currency.format(appState.averageInvoice), Icons.trending_up),
                ],
              ),
              const SizedBox(height: 24),
              _SubscriptionCard(
                planLabel: planLabel,
                planBody: planBody,
                priceText: priceText,
                isPremium: appState.isPremium,
                onOpenSubscription: onOpenSubscription,
              ),
              const SizedBox(height: 24),
              _QuickActionsRow(
                onCreateInvoice: onCreateInvoice,
                onToggleLocale: isLocaleChanging
                    ? null
                    : () {
                        final target =
                            appState.locale.languageCode == 'en' ? const Locale('ja') : const Locale('en');
                        context.read<AppState>().setLocale(target);
                      },
                l10n: l10n,
              ),
              const SizedBox(height: 32),
              Text(l10n.text('recentInvoices'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (isGuest) ...[
                _GuestInvoicesNotice(l10n: l10n, onRequestSignIn: onRequestSignIn),
                const SizedBox(height: 16),
              ],
              ...appState.recentInvoices.map((invoice) => Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(invoice.number),
                      subtitle: Text(l10n.invoiceTemplateLabel(invoice.template)),
                      trailing: Text(
                        currency.format(invoice.amount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )),
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

class _MetricDatum {
  const _MetricDatum(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricDatum> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1024
            ? 4
            : constraints.maxWidth > 720
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: constraints.maxWidth > 1024 ? 2.4 : 1.8,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return MetricCard(
              title: metric.title,
              value: metric.value,
              icon: metric.icon,
            );
          },
        );
      },
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onRequestSignIn, required this.l10n});

  final Future<void> Function() onRequestSignIn;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('guestModeTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.text('guestModeBody')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onRequestSignIn(),
              child: Text(l10n.text('signInButton')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.planLabel,
    required this.planBody,
    required this.priceText,
    required this.isPremium,
    required this.onOpenSubscription,
  });

  final String planLabel;
  final String planBody;
  final String priceText;
  final bool isPremium;
  final Future<void> Function() onOpenSubscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('subscriptionTitle'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(planLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(planBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text('${l10n.text('monthlyPrice')}: $priceText'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onOpenSubscription,
              icon: const Icon(Icons.workspace_premium),
              label: Text(isPremium ? l10n.text('manageSubscription') : l10n.text('subscribeCrisp')),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onCreateInvoice,
    required this.onToggleLocale,
    required this.l10n,
  });

  final VoidCallback onCreateInvoice;
  final VoidCallback? onToggleLocale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.note_add,
                title: l10n.text('createInvoiceAction'),
                subtitle: l10n.text('invoicesEmptyBody'),
                onPressed: onCreateInvoice,
              ),
            ),
            SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.language,
                title: l10n.text('languageSectionLabel'),
                subtitle: l10n.text('languageLabel'),
                onPressed: onToggleLocale,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GuestInvoicesNotice extends StatelessWidget {
  const _GuestInvoicesNotice({required this.l10n, required this.onRequestSignIn});

  final AppLocalizations l10n;
  final Future<void> Function() onRequestSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('guestInvoicesLockedTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.text('guestInvoicesLockedBody')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => onRequestSignIn(),
              child: Text(l10n.text('signInButton')),
            ),
          ],
        ),
      ),
    );
  }
}
