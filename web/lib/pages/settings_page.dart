import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.settingsSubtitle,
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
                    Expanded(child: _BusinessCard(appState: appState, l10n: l10n)),
                    const SizedBox(width: 24),
                    Expanded(child: _PlanCard(appState: appState, l10n: l10n)),
                  ],
                );
              }
              return Column(
                children: [
                  _BusinessCard(appState: appState, l10n: l10n),
                  const SizedBox(height: 24),
                  _PlanCard(appState: appState, l10n: l10n),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _PreferencesCard(appState: appState, l10n: l10n),
          const SizedBox(height: 24),
          _SupportCard(appState: appState, l10n: l10n),
        ],
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.appState, required this.l10n});

  final AppState appState;
  final AppLocalizations l10n;

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
                Text(l10n.settingsBusinessSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(label: l10n.businessNameLabel, value: appState.businessName),
            _InfoRow(label: l10n.ownerLabel, value: appState.ownerName),
            _InfoRow(label: l10n.addressLabel, value: appState.address),
            _InfoRow(label: l10n.postalCodeLabel, value: appState.postalCode),
            _InfoRow(label: l10n.emailLabel, value: appState.email),
            _InfoRow(label: l10n.phoneLabel, value: appState.phoneNumber),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.editProfile),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.appState, required this.l10n});

  final AppState appState;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isPremium = appState.isPremium;
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
                Text(l10n.settingsPlanSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  isPremium ? Icons.star : Icons.lock_open,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              title: Text(isPremium ? l10n.premiumPlanName : l10n.freePlanName),
              subtitle: Text(isPremium ? l10n.premiumPlanDescription : l10n.freePlanDescription),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: isPremium
                        ? () => context.read<AppState>().downgradeToFreePlan()
                        : () => context.read<AppState>().markAsPremium(),
                    child: Text(isPremium ? l10n.downgradeToFreePlanButton : l10n.upgradeToPremiumCta),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.planStripeNotice(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.appState, required this.l10n});

  final AppState appState;
  final AppLocalizations l10n;

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
                Text(l10n.settingsTemplateSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.languageSettingLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                DropdownButton<AppLanguage>(
                  value: appState.language,
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.japanese,
                      child: Text(l10n.languageJapanese),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.english,
                      child: Text(l10n.languageEnglish),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<AppState>().updateLanguage(value);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.autoNumberingTitle),
              subtitle: Text(l10n.autoNumberingSubtitle),
              value: appState.autoNumberingEnabled,
              onChanged: (value) => context.read<AppState>().updateAutoNumbering(value),
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reminderEmailsTitle),
              subtitle: Text(l10n.reminderEmailsSubtitle),
              value: appState.sendReminderEmails,
              onChanged: (value) => context.read<AppState>().updateReminderEmails(value),
            ),
            const Divider(height: 24),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.japaneseEraTitle),
              subtitle: Text(l10n.japaneseEraSubtitle),
              value: appState.showJapaneseEra,
              onChanged: (value) => context.read<AppState>().updateJapaneseEraDisplay(value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.defaultTaxRateLabel,
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
  const _SupportCard({required this.appState, required this.l10n});

  final AppState appState;
  final AppLocalizations l10n;

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
                Text(l10n.supportSectionTitle, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.library_books_outlined),
              title: Text(l10n.helpCenter),
              subtitle: Text(l10n.helpCenterSubtitle),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline),
              title: Text(l10n.supportContact),
              subtitle: Text(appState.email),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {},
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.forum_outlined),
              title: Text(l10n.community),
              subtitle: Text(l10n.communitySubtitle),
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
            width: 120,
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
