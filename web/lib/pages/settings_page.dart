
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.onEditProfile,
    required this.onLanguageChanged,
    required this.onSignOut,
    required this.onManageSubscription,
    required this.onCancelSubscription,
    required this.onSignIn,
  });

  final VoidCallback onEditProfile;
  final Future<void> Function(Locale locale) onLanguageChanged;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onManageSubscription;
  final VoidCallback onCancelSubscription;
  final Future<void> Function() onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final profile = appState.profile;
        final locale = appState.locale;
        final isGuest = appState.isGuest;
        final isLocaleChanging = appState.isLocaleChanging;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isGuest) ...[
                Text(l10n.text('settingsGuestCta'), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.text('profileTitle'), style: Theme.of(context).textTheme.headlineSmall),
                                const SizedBox(height: 8),
                                Text(profile.displayName, style: Theme.of(context).textTheme.titleMedium),
                                Text(profile.email.isEmpty ? '-' : profile.email),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: onEditProfile,
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l10n.text('editProfile')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: l10n.text('profileCompanyLabel'), value: profile.companyName),
                      _InfoRow(label: l10n.text('profileAddressLabel'), value: profile.address),
                      _InfoRow(label: l10n.text('profilePhoneLabel'), value: profile.phone),
                      _InfoRow(label: l10n.text('profileTaxIdLabel'), value: profile.taxId),
                      _InfoRow(
                        label: l10n.text('amountLabel'),
                        value: '${profile.currencySymbol} (${profile.currencyCode})',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.text('languageSectionLabel'), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButton<Locale>(
                        value: locale,
                        onChanged: isLocaleChanging
                            ? null
                            : (value) {
                                if (value != null) {
                                  onLanguageChanged(value);
                                }
                              },
                        items: const [
                          DropdownMenuItem(value: Locale('en'), child: Text('English')),
                          DropdownMenuItem(value: Locale('ja'), child: Text('日本語')),
                        ],
                      ),
                      if (isLocaleChanging) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          minHeight: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.text('subscriptionTitle'), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(appState.isPremium ? l10n.text('planPremiumBody') : l10n.text('planFreeBody')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                isGuest ? onSignIn() : onManageSubscription(),
                            icon: const Icon(Icons.workspace_premium),
                            label: Text(appState.isPremium
                                ? l10n.text('manageSubscription')
                                : l10n.text('subscribeCrisp')),
                          ),
                          const SizedBox(width: 12),
                          if (appState.isPremium && !isGuest)
                            OutlinedButton(
                              onPressed: onCancelSubscription,
                              child: Text(l10n.text('cancelSubscription')),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: isGuest
                    ? FilledButton.icon(
                        onPressed: () => onSignIn(),
                        icon: const Icon(Icons.login),
                        label: Text(l10n.text('signInButton')),
                      )
                    : OutlinedButton.icon(
                        onPressed: () async {
                          final shouldSignOut = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(l10n.text('signOut')),
                                  content: Text(l10n.text('confirmSignOut')),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(l10n.text('cancelButton'))),
                                    FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: Text(l10n.text('confirm'))),
                                  ],
                                ),
                              ) ??
                              false;
                          if (shouldSignOut) {
                            await onSignOut();
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.text('signOut')),
                      ),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
