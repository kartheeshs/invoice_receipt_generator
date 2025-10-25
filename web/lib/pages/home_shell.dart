
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';
import '../widgets/profile_form_dialog.dart';
import 'dashboard_page.dart';
import 'invoices_page.dart';
import 'settings_page.dart';
import 'sign_in_page.dart';

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
    final isGuest = appState.isGuest;

    final pages = [
      DashboardPage(
        onCreateInvoice: _createInvoice,
        onOpenSubscription: _handleManageSubscription,
        onRequestSignIn: () => _openAuthFlow(),
      ),
      InvoicesPage(
        onDownloadInvoice: _handleDownloadInvoice,
        onRequestSignIn: () => _openAuthFlow(),
      ),
      SettingsPage(
        onEditProfile: _editProfile,
        onLanguageChanged: context.read<AppState>().setLocale,
        onSignOut: context.read<AppState>().signOut,
        onManageSubscription: _handleManageSubscription,
        onCancelSubscription: () => context.read<AppState>().markPremium(false),
        onSignIn: () => _openAuthFlow(),
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
            child: isGuest
                ? FilledButton.icon(
                    onPressed: () => _openAuthFlow(),
                    icon: const Icon(Icons.login),
                    label: Text(l10n.text('signInButton')),
                  )
                : Row(
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

  void _createInvoice() {
    final appState = context.read<AppState>();
    final invoice = appState.prepareInvoice();
    appState.selectInvoice(invoice);
    setState(() => _index = 1);
  }

  Future<void> _handleDownloadInvoice(Invoice invoice) async {
    final authenticated = await _ensureAuthenticated(messageKey: 'downloadRequiresAccount');
    if (!authenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.text('downloadRequiresAccount'))));
      return;
    }
    try {
      await context.read<AppState>().downloadInvoicePdf(invoice);
    } on AccessDeniedException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.text(error.reasonKey))));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.text('pdfReady'))));
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

  Future<void> _handleManageSubscription() async {
    final authenticated = await _ensureAuthenticated();
    if (!authenticated) return;
    context.read<AppState>().openSubscription();
    context.read<AppState>().markPremium(true);
  }

  Future<void> _openAuthFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignInPage(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<bool> _ensureAuthenticated({String? messageKey}) async {
    final appState = context.read<AppState>();
    if (appState.isAuthenticated) {
      return true;
    }

    final l10n = context.l10n;
    final shouldSignIn = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.text('authRequiredTitle')),
            content: Text(l10n.text(messageKey ?? 'authRequiredBody')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.text('notNow')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.text('signInButton')),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !shouldSignIn) {
      return false;
    }

    await _openAuthFlow();
    if (!mounted) {
      return false;
    }
    return context.read<AppState>().isAuthenticated;
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
