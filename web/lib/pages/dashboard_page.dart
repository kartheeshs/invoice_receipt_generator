import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../services/crisp_subscription_service.dart';
import '../state/app_state.dart';
import '../widgets/invoice_status_chip.dart';
import '../widgets/metric_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onCreateInvoice});

  final VoidCallback onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;
    final invoices = appState.invoices;

    final nextActions = invoices
        .where((invoice) => invoice.status != InvoiceStatus.paid)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final recentInvoices = invoices.take(4).toList();
    final NumberFormat currency = l10n.currencyFormat;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1100;
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dashboardGreeting(appState.ownerName),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.dashboardLead(currency.format(appState.totalBilled)),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (isWide)
                    FilledButton.icon(
                      onPressed: onCreateInvoice,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.dashboardCreateInvoiceButton),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  MetricCard(
                    title: l10n.metricPaidTitle,
                    value: currency.format(appState.totalBilled),
                    subtitle: l10n.metricPaidSubtitle(
                      appState.invoices.where((invoice) => invoice.status == InvoiceStatus.paid).length,
                    ),
                    icon: Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  MetricCard(
                    title: l10n.metricOutstandingTitle,
                    value: currency.format(appState.outstandingAmount),
                    subtitle: l10n.metricOutstandingSubtitle(appState.invoicesDueThisWeek),
                    icon: Icons.pending_actions_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  MetricCard(
                    title: l10n.metricOverdueTitle,
                    value: currency.format(appState.overdueAmount),
                    subtitle: l10n.metricOverdueSubtitle(appState.sendReminderEmails),
                    icon: Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  MetricCard(
                    title: l10n.metricDraftTitle,
                    value: currency.format(appState.draftTotal),
                    subtitle: l10n.metricDraftSubtitle(appState.autoNumberingEnabled),
                    icon: Icons.drafts_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, innerConstraints) {
                  final showTwoColumns = innerConstraints.maxWidth > 1000;
                  if (showTwoColumns) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNextStepsCard(context, nextActions, currency, l10n)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildDownloadsCard(context, appState, l10n)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildNextStepsCard(context, nextActions, currency, l10n),
                      const SizedBox(height: 24),
                      _buildDownloadsCard(context, appState, l10n),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                l10n.dashboardRecentInvoicesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentInvoices.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final invoice = recentInvoices[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          invoice.status.icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text('${invoice.clientName} / ${invoice.projectName}'),
                      subtitle: Text(
                        l10n.dashboardRecentInvoiceSubtitle(
                          l10n.formatDate(invoice.issueDate),
                          currency.format(invoice.total),
                        ),
                      ),
                      trailing: InvoiceStatusChip(status: invoice.status),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNextStepsCard(
    BuildContext context,
    List<Invoice> nextActions,
    NumberFormat currency,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.dashboardFollowUpTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nextActions.isEmpty)
              Text(l10n.dashboardNoPending)
            else
              ...nextActions.take(3).map(
                (invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 10, right: 12),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6750A4),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dashboardFollowUpLine(
                                invoice.clientName,
                                currency.format(invoice.total),
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.dashboardFollowUpSubtitle(
                                l10n.formatDate(invoice.dueDate),
                                l10n.invoiceStatusLabel(invoice.status),
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: onCreateInvoice,
              icon: const Icon(Icons.add),
              label: Text(l10n.dashboardNewInvoiceCta),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsCard(BuildContext context, AppState appState, AppLocalizations l10n) {
    final used = appState.monthlyDownloadsUsed;
    final limit = appState.monthlyDownloadLimit;
    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0, 1).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.dashboardDownloadsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: appState.isPremium ? 1 : ratio,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: const Color(0xFFE5DEFF),
            ),
            const SizedBox(height: 12),
            Text(
              appState.isPremium
                  ? l10n.dashboardDownloadsUnlimited
                  : l10n.dashboardDownloadsUsage(used, limit),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!appState.isPremium)
              FilledButton.icon(
                onPressed: () => _startCrispCheckout(context),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(l10n.upgradeToPremiumCta),
              )
            else
              OutlinedButton(
                onPressed: () => context.read<AppState>().downgradeToFreePlan(),
                child: Text(l10n.downgradeToFreeCta),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCrispCheckout(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final appState = context.read<AppState>();

    try {
      await CrispSubscriptionService().startCheckout(email: appState.email);
      appState.markAsPremium(provider: 'crisp', planName: l10n.crispPlanName);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.crispCheckoutLaunched),
        ),
      );
    } on CrispConfigurationException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.crispMissingConfig(error.message)),
        ),
      );
    } on CrispCheckoutException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.crispCheckoutError(error.message)),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.crispCheckoutError(error.toString())),
        ),
      );
    }
  }
}
