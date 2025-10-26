
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
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
              _RecentInvoicesSection(
                invoices: appState.recentInvoices,
                l10n: l10n,
                currency: currency,
                isGuest: isGuest,
                onRequestSignIn: onRequestSignIn,
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
        final bool isWide = constraints.maxWidth > 1024;
        final bool isMedium = !isWide && constraints.maxWidth > 720;
        final double tileWidth =
            (constraints.maxWidth - ((columns - 1) * 20)) / columns;
        final double? tileHeight = isWide
            ? 180
            : isMedium
                ? 200
                : null;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: tileHeight,
            childAspectRatio:
                tileHeight == null ? 1.2 : tileWidth / tileHeight,
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

class _RecentInvoicesSection extends StatelessWidget {
  const _RecentInvoicesSection({
    required this.invoices,
    required this.l10n,
    required this.currency,
    required this.isGuest,
    required this.onRequestSignIn,
  });

  final List<Invoice> invoices;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final bool isGuest;
  final Future<void> Function() onRequestSignIn;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (isGuest) {
      children
        ..add(_GuestInvoicesNotice(l10n: l10n, onRequestSignIn: onRequestSignIn))
        ..add(const SizedBox(height: 16));
    }

    children.add(_RecentInvoicesTable(
      invoices: invoices,
      l10n: l10n,
      currency: currency,
      locked: isGuest,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _RecentInvoicesTable extends StatelessWidget {
  const _RecentInvoicesTable({
    required this.invoices,
    required this.l10n,
    required this.currency,
    this.locked = false,
  });

  final List<Invoice> invoices;
  final AppLocalizations l10n;
  final NumberFormat currency;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInvoices = invoices.isNotEmpty;

    Widget content = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecentInvoiceHeader(l10n: l10n),
            const SizedBox(height: 12),
            if (hasInvoices)
              ...[for (var i = 0; i < invoices.length; i++) ...[
                if (i > 0) const Divider(height: 28),
                _RecentInvoiceRow(
                  invoice: invoices[i],
                  l10n: l10n,
                  currency: currency,
                ),
              ]]
            else
              _RecentInvoicesEmptyState(l10n: l10n, locked: locked),
          ],
        ),
      ),
    );

    if (!locked) {
      return content;
    }

    return AnimatedOpacity(
      opacity: 0.85,
      duration: const Duration(milliseconds: 200),
      child: content,
    );
  }
}

class _RecentInvoiceHeader extends StatelessWidget {
  const _RecentInvoiceHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        if (isCompact) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.text('invoiceNumberLabel'), style: labelStyle),
              Text(l10n.text('amountLabel'), style: labelStyle),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 3, child: Text(l10n.text('invoiceNumberLabel'), style: labelStyle)),
            Expanded(flex: 2, child: Text(l10n.text('issueDateLabel'), style: labelStyle)),
            Expanded(flex: 2, child: Text(l10n.text('invoiceStatusLabel'), style: labelStyle)),
            Text(l10n.text('amountLabel'), style: labelStyle),
          ],
        );
      },
    );
  }
}

class _RecentInvoiceRow extends StatelessWidget {
  const _RecentInvoiceRow({
    required this.invoice,
    required this.l10n,
    required this.currency,
  });

  final Invoice invoice;
  final AppLocalizations l10n;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final issuedOn = l10n.dateFormat.format(invoice.issueDate);
    final amountText = currency.format(invoice.amount);
    final statusLabel = l10n.invoiceStatusLabel(invoice.status);
    final statusColor = _statusColor(theme, invoice.status);
    final statusBackground = statusColor.withOpacity(0.12);
    final clientName = invoice.clientName.isNotEmpty
        ? invoice.clientName
        : l10n.text('invoiceDefaultClient');

    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel,
        style: theme.textTheme.labelMedium?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      invoice.number,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(amountText, style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                clientName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  statusChip,
                  const SizedBox(width: 12),
                  Text(
                    issuedOn,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.number,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clientName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                issuedOn,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: statusChip)),
            Text(
              amountText,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(ThemeData theme, InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return theme.colorScheme.outline;
      case InvoiceStatus.sent:
        return theme.colorScheme.primary;
      case InvoiceStatus.paid:
        return theme.colorScheme.secondary;
      case InvoiceStatus.overdue:
        return theme.colorScheme.error;
    }
  }
}

class _RecentInvoicesEmptyState extends StatelessWidget {
  const _RecentInvoicesEmptyState({required this.l10n, required this.locked});

  final AppLocalizations l10n;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = locked ? l10n.text('guestInvoicesLockedTitle') : l10n.text('invoicesEmptyTitle');
    final body = locked ? l10n.text('guestInvoicesLockedBody') : l10n.text('invoicesEmptyBody');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
