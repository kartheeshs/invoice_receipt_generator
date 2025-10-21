import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ワークスペース設定', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '請求書テンプレートや課金ステータスの管理を行います。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1000;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _BusinessCard(appState: appState)),
                    const SizedBox(width: 24),
                    Expanded(child: _PlanCard(appState: appState)),
                  ],
                );
              }
              return Column(
                children: [
                  _BusinessCard(appState: appState),
                  const SizedBox(height: 24),
                  _PlanCard(appState: appState),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _PreferencesCard(appState: appState),
          const SizedBox(height: 24),
          _SupportCard(appState: appState),
        ],
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.apartment, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('事業者情報', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: '事業者名', value: appState.businessName),
            _InfoRow(label: '担当者', value: appState.ownerName),
            _InfoRow(label: '所在地', value: appState.address),
            _InfoRow(label: '郵便番号', value: appState.postalCode),
            _InfoRow(label: 'メールアドレス', value: appState.email),
            _InfoRow(label: '電話番号', value: appState.phoneNumber),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined),
              label: const Text('プロフィールを編集'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text('プラン', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  appState.isPremium ? Icons.star : Icons.lock_open,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              title: Text(appState.isPremium ? 'プレミアムプラン（¥500/月）' : '無料プラン'),
              subtitle: Text(
                appState.isPremium
                    ? 'PDFダウンロード無制限 / カスタムブランド / 優先サポート'
                    : '月3件までPDFダウンロード / 基本テンプレート',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: appState.isPremium
                        ? () => context.read<AppState>().downgradeToFreePlan()
                        : () => context.read<AppState>().markAsPremium(),
                    child: Text(appState.isPremium ? 'フリープランに戻す' : 'プレミアムにアップグレード'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Stripe 決済は有効化済みです。請求書テンプレートに表示される課金情報は自動で更新されます。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('請求書テンプレート', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('請求書番号を自動採番する'),
              subtitle: const Text('「INV-YYYYMM-001」の形式で連番を採番します。'),
              value: appState.autoNumberingEnabled,
              onChanged: (value) => context.read<AppState>().updateAutoNumbering(value),
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('支払期限メールを自動送信'),
              subtitle: const Text('期限切れの請求書に対して、1日後にリマインドメールを送信します。'),
              value: appState.sendReminderEmails,
              onChanged: (value) => context.read<AppState>().updateReminderEmails(value),
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('日付を和暦表示にする'),
              subtitle: const Text('請求書上の日付を令和表記に変更します。'),
              value: appState.showJapaneseEra,
              onChanged: (value) => context.read<AppState>().updateJapaneseEraDisplay(value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '標準税率',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                DropdownButton<double>(
                  value: appState.defaultTaxRate,
                  items: const [
                    DropdownMenuItem(value: 0.08, child: Text('8%')), 
                    DropdownMenuItem(value: 0.1, child: Text('10%')), 
                    DropdownMenuItem(value: 0.2, child: Text('20%')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<AppState>().updateDefaultTaxRate(value);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text('サポートとリソース', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.library_books_outlined),
              title: const Text('ヘルプセンター'),
              subtitle: const Text('FAQや使い方ガイドを確認できます。'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: const Text('サポートへ問い合わせ'),
              subtitle: Text(appState.email),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.forum_outlined),
              title: const Text('コミュニティ'),
              subtitle: const Text('Slackで他のユーザーと情報交換しましょう。'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
