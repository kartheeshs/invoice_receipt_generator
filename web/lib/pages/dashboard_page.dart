import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../state/app_state.dart';
import '../widgets/invoice_status_chip.dart';
import '../widgets/metric_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onCreateInvoice});

  final VoidCallback onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final invoices = appState.invoices;

    final nextActions = invoices
        .where((invoice) => invoice.status != InvoiceStatus.paid)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final recentInvoices = invoices.take(4).toList();
    final currency = NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0);

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
                          'おかえりなさい、${appState.ownerName}さん',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '今月は${currency.format(appState.totalBilled)}の入金が確認できています。未回収分のフォローアップを行いましょう。',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  if (isWide)
                    FilledButton.icon(
                      onPressed: onCreateInvoice,
                      icon: const Icon(Icons.add),
                      label: const Text('請求書を作成'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  MetricCard(
                    title: '入金済み',
                    value: currency.format(appState.totalBilled),
                    subtitle: '過去30日で${appState.invoices.where((invoice) => invoice.status == InvoiceStatus.paid).length}件',
                    icon: Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  MetricCard(
                    title: '未入金',
                    value: currency.format(appState.outstandingAmount),
                    subtitle: '今後7日以内の期限: ${appState.invoicesDueThisWeek}件',
                    icon: Icons.pending_actions_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  MetricCard(
                    title: '期限切れ',
                    value: currency.format(appState.overdueAmount),
                    subtitle: 'リマインドメール設定: ${appState.sendReminderEmails ? 'ON' : 'OFF'}',
                    icon: Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  MetricCard(
                    title: '下書き',
                    value: currency.format(appState.draftTotal),
                    subtitle: '自動採番: ${appState.autoNumberingEnabled ? '有効' : '無効'}',
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
                        Expanded(child: _buildNextStepsCard(context, nextActions, currency)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildDownloadsCard(context, appState)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildNextStepsCard(context, nextActions, currency),
                      const SizedBox(height: 24),
                      _buildDownloadsCard(context, appState),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                '最近の請求書',
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
                      subtitle: Text('発行日: ${_formatDate(invoice.issueDate)} • 金額: ${currency.format(invoice.total)}'),
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
                  'フォローアップ推奨',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nextActions.isEmpty)
              const Text('対応が必要な請求書はありません。')
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
                              '${invoice.clientName} への請求（${currency.format(invoice.total)}）',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '支払期限: ${_formatDate(invoice.dueDate)} • ステータス: ${invoice.status.label}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
              label: const Text('新しい請求書を作成'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsCard(BuildContext context, AppState appState) {
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
                  'PDF ダウンロード上限',
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
                  ? 'プレミアムプランのため上限はありません。'
                  : '今月は${limit}件中${used}件ダウンロード済みです。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (!appState.isPremium)
              FilledButton.icon(
                onPressed: () => context.read<AppState>().markAsPremium(),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('プレミアムにアップグレード'),
              )
            else
              OutlinedButton(
                onPressed: () => context.read<AppState>().downgradeToFreePlan(),
                child: const Text('フリープランにダウングレード'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('yyyy/MM/dd');
    return formatter.format(date);
  }
}
