import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final hasSupportLink = context.watch<AppState>().hasSupportLink;

    final sections = [
      _PolicySection(
        icon: Icons.shield_outlined,
        title: l10n.text('privacyDataProtectionTitle'),
        body: l10n.text('privacyDataProtectionBody'),
      ),
      _PolicySection(
        icon: Icons.delete_sweep_outlined,
        title: l10n.text('privacyUserControlTitle'),
        body: l10n.text('privacyUserControlBody'),
      ),
      _PolicySection(
        icon: Icons.gavel_outlined,
        title: l10n.text('privacyFraudTitle'),
        body: l10n.text('privacyFraudBody'),
      ),
      _PolicySection(
        icon: Icons.handshake_outlined,
        title: l10n.text('privacyNoLiabilityTitle'),
        body: l10n.text('privacyNoLiabilityBody'),
      ),
      _PolicySection(
        icon: Icons.support_agent_outlined,
        title: l10n.text('privacySupportTitle'),
        body: l10n.text('privacySupportBody'),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.12),
              theme.colorScheme.secondaryContainer.withOpacity(0.18),
              theme.colorScheme.tertiary.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new),
                          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.text('privacyTitle'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                          icon: const Icon(Icons.home_outlined),
                          label: Text(l10n.text('privacyBackToHome')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.text('privacyUpdatedLabel'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.text('privacyIntro'),
                              style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 32),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 720;
                                if (isWide) {
                                  return Wrap(
                                    spacing: 24,
                                    runSpacing: 24,
                                    children: sections
                                        .map((section) => SizedBox(
                                              width: (constraints.maxWidth - 24) / 2,
                                              child: section,
                                            ))
                                        .toList(),
                                  );
                                }
                                return Column(
                                  children: sections
                                      .map((section) => Padding(
                                            padding: const EdgeInsets.only(bottom: 24),
                                            child: section,
                                          ))
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              runSpacing: 16,
                              spacing: 16,
                              children: [
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pushReplacementNamed('/app'),
                                  child: Text(l10n.text('landingHeroPrimaryCta')),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (hasSupportLink) {
                                      context.read<AppState>().openSupportLink();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.text('privacySupportBody'))),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: Text(l10n.text('privacyContactCta')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
