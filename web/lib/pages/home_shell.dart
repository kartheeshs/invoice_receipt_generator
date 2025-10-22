
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';
import '../widgets/invoice_form_dialog.dart';
import '../widgets/profile_form_dialog.dart';
import 'dashboard_page.dart';
import 'invoices_page.dart';
import 'settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final pages = [
      DashboardPage(
        onCreateInvoice: _createInvoice,
        onOpenSubscription: appState.openSubscription,
      ),
      InvoicesPage(
        onCreateInvoice: _createInvoice,
        onEditInvoice: _editInvoice,
        onDeleteInvoice: (invoice) {
          context.read<AppState>().deleteInvoice(invoice.id);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.text('invoiceDeleted'))));
        },
        onDownloadInvoice: (invoice) async {
          await context.read<AppState>().downloadInvoicePdf(invoice);
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.text('pdfReady'))));
        },
      ),
      SettingsPage(
        onEditProfile: _editProfile,
        onLanguageChanged: context.read<AppState>().setLocale,
        onSignOut: context.read<AppState>().signOut,
        onManageSubscription: () {
          context.read<AppState>().openSubscription();
          context.read<AppState>().markPremium(true);
        },
        onCancelSubscription: () => context.read<AppState>().markPremium(false),
      ),
    ];

    final isWide = MediaQuery.of(context).size.width >= 960;

    final navigationDestinations = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: l10n.text('dashboardTab')),
      NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: l10n.text('invoicesTab')),
      NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l10n.text('settingsTab')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('appTitle')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  appState.profile.displayName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    _initials(appState.profile.displayName),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              extended: true,
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: navigationDestinations
                  .map(
                    (destination) => NavigationRailDestination(
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                      label: Text(destination.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: IndexedStack(
                key: ValueKey(_index),
                index: _index,
                children: pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: navigationDestinations,
            ),
    );
  }

  Future<void> _createInvoice() async {
    final appState = context.read<AppState>();
    final invoice = appState.prepareInvoice();
    await showDialog<void>(
      context: context,
      builder: (context) => InvoiceFormDialog(
        invoice: invoice,
        onSubmit: (updated) {
          context.read<AppState>().saveInvoice(updated);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.l10n.text('invoiceSaved'))));
        },
      ),
    );
  }

  Future<void> _editInvoice(Invoice invoice) async {
    await showDialog<void>(
      context: context,
      builder: (context) => InvoiceFormDialog(
        invoice: invoice,
        onSubmit: (updated) {
          context.read<AppState>().saveInvoice(updated);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.l10n.text('invoiceSaved'))));
        },
      ),
    );
  }

  Future<void> _editProfile() async {
    final appState = context.read<AppState>();
    await showDialog<void>(
      context: context,
      builder: (context) => ProfileFormDialog(
        profile: appState.profile,
        onSubmit: (profile) {
          context.read<AppState>().updateProfile(profile);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.l10n.text('profileUpdated'))));
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
