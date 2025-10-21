import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/invoice.dart';
import '../state/app_state.dart';
import '../widgets/invoice_form_dialog.dart';
import 'dashboard_page.dart';
import 'invoices_page.dart';
import 'settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final destinations = [
      _NavigationDestination(
        label: 'ダッシュボード',
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
      ),
      _NavigationDestination(
        label: '請求書',
        icon: Icons.description_outlined,
        selectedIcon: Icons.description,
      ),
      _NavigationDestination(
        label: '設定',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('和式請求書ジェネレーター'),
        actions: [
          if (!appState.isPremium)
            FilledButton.icon(
              onPressed: () => _showUpgradeDialog(context),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('プレミアムへアップグレード'),
            )
          else
            FilledButton.icon(
              onPressed: () => context.read<AppState>().downgradeToFreePlan(),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('プレミアム適用中'),
            ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: '通知',
            onPressed: () => _showNotifications(context),
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: const Text('山'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isWide ? null : Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'メニュー',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(),
              for (var i = 0; i < destinations.length; i++)
                ListTile(
                  leading: Icon(i == _selectedIndex
                      ? destinations[i].selectedIcon
                      : destinations[i].icon),
                  title: Text(destinations[i].label),
                  selected: i == _selectedIndex,
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) => setState(() => _selectedIndex = value),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _openInvoiceForm(context),
              icon: const Icon(Icons.add),
              label: const Text('新しい請求書'),
            )
          : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) => setState(() => _selectedIndex = value),
                  extended: true,
                  minExtendedWidth: 200,
                  labelType: NavigationRailLabelType.none,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  key: ValueKey(_selectedIndex),
                  padding: const EdgeInsets.all(24),
                  child: _buildPage(appState),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(AppState appState) {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(
          onCreateInvoice: () => _openInvoiceForm(context),
        );
      case 1:
        return InvoicesPage(
          onCreateInvoice: () => _openInvoiceForm(context),
          onEditInvoice: (invoice) => _openInvoiceForm(context, invoice: invoice),
          onDeleteInvoice: (invoice) => _confirmDeleteInvoice(context, invoice),
        );
      case 2:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _openInvoiceForm(BuildContext context, {Invoice? invoice}) async {
    final appState = context.read<AppState>();
    final invoiceId = invoice?.id ?? appState.createInvoiceId();
    final generatedNumber = invoice?.number ?? appState.generateInvoiceNumber();

    final result = await showDialog<Invoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InvoiceFormDialog(
        invoiceId: invoiceId,
        initialInvoice: invoice,
        initialNumber: generatedNumber,
        autoNumberingEnabled: appState.autoNumberingEnabled,
        defaultTaxRate: invoice?.taxRate ?? appState.defaultTaxRate,
      ),
    );

    if (result != null) {
      appState.saveInvoice(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(invoice == null ? '請求書を作成しました。' : '請求書を更新しました。'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteInvoice(BuildContext context, Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('請求書の削除'),
        content: Text('${invoice.clientName}向けの請求書（${invoice.number}）を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      context.read<AppState>().deleteInvoice(invoice.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('請求書を削除しました。'),
        ),
      );
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアムプラン'),
        content: const Text('月額¥500でPDFダウンロード無制限・ブランドロゴ設定などの機能が利用できます。アップグレードしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AppState>().markAsPremium();
            },
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('アップグレード'),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最新のお知らせ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.campaign_outlined),
              title: Text('請求書テンプレートに「軽減税率」項目を追加しました。'),
              subtitle: Text('2024/05/20'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.campaign_outlined),
              title: Text('Stripe 決済がプレミアムプランでも利用可能になりました。'),
              subtitle: Text('2024/05/12'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _NavigationDestination {
  const _NavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
