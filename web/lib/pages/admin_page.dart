import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (!appState.isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.text('adminRestricted'),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final accounts = appState.accounts;
    final activity = appState.activityLog;
    final planPriceFormat = NumberFormat.currency(
      name: appState.profile.currencyCode,
      symbol: appState.profile.currencySymbol,
    );
    final planPrice = planPriceFormat.format(appState.planPrice);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
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
                      Text(l10n.text('adminTitle'), style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        l10n.text('adminSubtitle'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.people_alt_outlined, size: 18),
                      label: Text(accounts.length.toString()),
                    ),
                    Chip(
                      avatar: const Icon(Icons.attach_money_outlined, size: 18),
                      label: Text('${l10n.text('monthlyPrice')}: $planPrice'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _AdminAccountsCard(
              accounts: accounts,
              currentEmail: appState.user?.email,
              onTogglePremium: appState.toggleAccountPremium,
              onToggleAdmin: appState.toggleAccountAdmin,
              onRemove: appState.removeAccount,
            ),
            const SizedBox(height: 24),
            _AdminActivityCard(activity: activity.take(15).toList()),
          ],
        ),
      ),
    );
  }
}

class _AdminAccountsCard extends StatelessWidget {
  const _AdminAccountsCard({
    required this.accounts,
    required this.currentEmail,
    required this.onTogglePremium,
    required this.onToggleAdmin,
    required this.onRemove,
  });

  final List<ManagedAccount> accounts;
  final String? currentEmail;
  final void Function(String id, bool value) onTogglePremium;
  final void Function(String id, bool value) onToggleAdmin;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('adminAccountsTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.text('adminAccountsEmpty'), style: theme.textTheme.bodyMedium),
              )
            else
              ...[
                for (var index = 0; index < accounts.length; index++)
                  ...[
                    _AdminAccountTile(
                      account: accounts[index],
                      isSelf: currentEmail != null &&
                          accounts[index].email.toLowerCase() == currentEmail!.toLowerCase(),
                      onTogglePremium: (value) => onTogglePremium(accounts[index].id, value),
                      onToggleAdmin: (value) => onToggleAdmin(accounts[index].id, value),
                      onRemove: () => onRemove(accounts[index].id),
                    ),
                    if (index != accounts.length - 1) const Divider(height: 28),
                  ],
              ],
          ],
        ),
      ),
    );
  }
}

class _AdminAccountTile extends StatelessWidget {
  const _AdminAccountTile({
    required this.account,
    required this.isSelf,
    required this.onTogglePremium,
    required this.onToggleAdmin,
    required this.onRemove,
  });

  final ManagedAccount account;
  final bool isSelf;
  final ValueChanged<bool> onTogglePremium;
  final ValueChanged<bool> onToggleAdmin;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.displayName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(account.email, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(
                          account.isPremium ? Icons.star : Icons.star_border,
                          size: 18,
                        ),
                        label: Text(account.isPremium
                            ? l10n.text('adminPremiumLabel')
                            : l10n.text('planStatusFree')),
                      ),
                      if (account.isAdmin)
                        Chip(
                          avatar: const Icon(Icons.shield, size: 18),
                          label: Text(l10n.text('adminAdminLabel')),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelf)
              IconButton(
                tooltip: l10n.text('adminRemoveAccount'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.text('adminRemoveAccount')),
                          content: Text(l10n.text('adminRemoveAccountConfirm')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.text('cancelButton')),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.text('deleteButton')),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (confirmed) {
                    onRemove();
                  }
                },
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _AdminToggle(label: l10n.text('adminPremiumLabel'), value: account.isPremium, onChanged: onTogglePremium),
            _AdminToggle(
              label: l10n.text('adminAdminLabel'),
              value: account.isAdmin,
              onChanged: isSelf ? null : onToggleAdmin,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminToggle extends StatelessWidget {
  const _AdminToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch.adaptive(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _AdminActivityCard extends StatelessWidget {
  const _AdminActivityCard({required this.activity});

  final List<String> activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('adminActivityTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (activity.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.text('adminActivityEmpty'), style: theme.textTheme.bodyMedium),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activity.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (context, index) {
                  final entry = activity[index];
                  final closingIndex = entry.indexOf(']');
                  final timestamp = closingIndex != -1 && entry.startsWith('[')
                      ? entry.substring(1, closingIndex)
                      : '';
                  final message = closingIndex != -1 && closingIndex + 1 < entry.length
                      ? entry.substring(closingIndex + 2)
                      : entry;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(message),
                    subtitle: timestamp.isEmpty ? null : Text(timestamp),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
