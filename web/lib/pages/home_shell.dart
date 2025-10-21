import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
    final l10n = context.l10n;
    final isWide = MediaQuery.of(context).size.width >= 1024;
    final destinations = [
      _NavigationDestination(
        label: l10n.dashboardNav,
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
      ),
      _NavigationDestination(
        label: l10n.invoicesNav,
        icon: Icons.description_outlined,
        selectedIcon: Icons.description,
      ),
      _NavigationDestination(
        label: l10n.settingsNav,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
    ];

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (!appState.isPremium)
            FilledButton.icon(
              onPressed: () => _showUpgradeDialog(context),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(l10n.upgradeToPremiumButton),
            )
          else
            FilledButton.icon(
              onPressed: () => context.read<AppState>().downgradeToFreePlan(),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.premiumActiveLabel),
            ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: l10n.notificationsTooltip,
            onPressed: () => _showNotifications(context),
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: l10n.accountMenuTooltip,
            onSelected: (value) {
              if (value == 'sign-out') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => [
              if (user?.email != null)
                PopupMenuItem<String>(
                  enabled: false,
                  value: 'email',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user!.email!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'sign-out',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.signOut),
                ),
              ),
            ],
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(_userInitial(user)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        l10n.menuTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              label: Text(l10n.newInvoiceAction),
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
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(invoice == null ? l10n.invoiceCreatedSnack : l10n.invoiceUpdatedSnack),
        ),
      );
    }
  }

  Future<void> _confirmDeleteInvoice(BuildContext context, Invoice invoice) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteInvoiceTitle),
        content: Text(l10n.deleteInvoiceMessage(invoice.clientName, invoice.number)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      context.read<AppState>().deleteInvoice(invoice.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.invoiceDeletedSnack),
        ),
      );
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.upgradeDialogTitle),
        content: Text(l10n.upgradeDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.closeAction),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AppState>().markAsPremium();
            },
            icon: const Icon(Icons.workspace_premium_outlined),
            label: Text(l10n.upgradeDialogCta),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.campaign_outlined),
              title: Text(l10n.notificationTaxUpdateTitle),
              subtitle: const Text('2024/05/20'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.campaign_outlined),
              title: Text(l10n.notificationPremiumUpdateTitle),
              subtitle: const Text('2024/05/12'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.closeAction),
          ),
        ],
      ),
    );
  }

  String _userInitial(User? user) {
    final displayName = user?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName.trim().substring(0, 1).toUpperCase();
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      return email.trim().substring(0, 1).toUpperCase();
    }
    return 'A';
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
