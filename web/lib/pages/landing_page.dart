import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_template_spec.dart';
import '../state/app_state.dart';
import '../widgets/language_menu_button.dart';
import 'home_shell.dart';
import 'sign_in_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final _productKey = GlobalKey();
  final _templatesKey = GlobalKey();
  final _pricingKey = GlobalKey();
  final _supportKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(context, appState),
                Container(key: _productKey, child: _buildFeatureSection(context)),
                Container(key: _templatesKey, child: _buildTemplateShowcase(context)),
                _buildJapaneseHighlight(context),
                Container(key: _pricingKey, child: _buildWorkflowSection(context)),
                _buildSecuritySection(context),
                Container(key: _supportKey, child: _buildCtaSection(context, appState)),
                _buildFooter(context),
              ],
            ),
          ),
          if (appState.isLocaleChanging) const _LandingLocaleOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, AppState appState) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 980;

    final gradientColors = [
      theme.colorScheme.primary,
      theme.colorScheme.tertiary,
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: math.max(24.0, MediaQuery.of(context).size.width * 0.08),
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LandingNavBar(
                onOpenProduct: () => _scrollTo(_productKey),
                onOpenTemplates: () => _scrollTo(_templatesKey),
                onOpenPricing: () => _scrollTo(_pricingKey),
                onOpenSupport: () => _scrollTo(_supportKey),
                onLaunchApp: () => _openApp(),
                onSignIn: appState.isGuest ? () => _openSignIn() : null,
                currentLocale: appState.locale,
                onLocaleSelected: (locale) => context.read<AppState>().setLocale(locale),
                isLocaleChanging: appState.isLocaleChanging,
              ),
              const SizedBox(height: 56),
              Builder(builder: (context) {
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.text('landingHeroBadge').toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.text('landingHeroTitle'),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.text('landingHeroSubtitle'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _openApp,
                          icon: const Icon(Icons.open_in_new),
                          label: Text(l10n.text('landingHeroPrimaryCta')),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _scrollTo(_templatesKey),
                          icon: const Icon(Icons.view_carousel_outlined),
                          label: Text(l10n.text('landingHeroSecondaryCta')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.6)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _HeroChip(
                          icon: Icons.cloud_done_outlined,
                          label: l10n.text('landingHeroPointSync'),
                        ),
                        _HeroChip(
                          icon: Icons.language_outlined,
                          label: l10n.text('landingHeroPointGlobal'),
                        ),
                        _HeroChip(
                          icon: Icons.picture_as_pdf_outlined,
                          label: l10n.text('landingHeroPointPdf'),
                        ),
                      ],
                    ),
                  ],
                );
                final preview = _TemplateHeroCard(spec: invoiceTemplateSpec(InvoiceTemplate.executive));
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 48),
                      preview,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: content),
                    const SizedBox(width: 48),
                    Expanded(flex: 4, child: preview),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = math.max(24.0, width * 0.08);
    final contentWidth = width - horizontalPadding * 2;
    final isNarrow = width < 900;

    final cards = [
      _FeatureCard(
        icon: Icons.auto_awesome_mosaic_outlined,
        title: l10n.text('landingFeatureAutomationTitle'),
        description: l10n.text('landingFeatureAutomationBody'),
      ),
      _FeatureCard(
        icon: Icons.branding_watermark_outlined,
        title: l10n.text('landingFeatureBrandingTitle'),
        description: l10n.text('landingFeatureBrandingBody'),
      ),
      _FeatureCard(
        icon: Icons.gavel_outlined,
        title: l10n.text('landingFeatureComplianceTitle'),
        description: l10n.text('landingFeatureComplianceBody'),
      ),
      _FeatureCard(
        icon: Icons.groups_outlined,
        title: l10n.text('landingFeatureCollaborationTitle'),
        description: l10n.text('landingFeatureCollaborationBody'),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('landingFeatureSectionTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.text('landingFeatureSectionSubtitle'),
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: cards
                .map((card) => SizedBox(
                      width: isNarrow
                          ? double.infinity
                          : math.max(320.0, contentWidth / 2 - 10),
                      child: card,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateShowcase(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = math.max(24.0, width * 0.08);
    final contentWidth = width - horizontalPadding * 2;
    final isNarrow = width < 1000;

    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('landingTemplateSectionTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.text('landingTemplateSectionSubtitle'),
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: InvoiceTemplate.values
                .map((template) => _TemplatePreviewCard(
                      template: template,
                      width: isNarrow
                          ? double.infinity
                          : math.max(320.0, contentWidth / 2 - 10),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJapaneseHighlight(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = math.max(24.0, width * 0.08);
    final isNarrow = width < 900;
    final palette = invoiceTemplateSpec(InvoiceTemplate.japanese);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 96,
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: palette.border.withOpacity(0.7)),
          color: palette.surface,
          boxShadow: [
            BoxShadow(
              color: palette.accent.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Builder(builder: (context) {
          final description = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.text('landingTemplateJapaneseTitle'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.text('landingTemplateJapaneseBody'),
                style: theme.textTheme.titleMedium?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _HeroChip(
                    icon: Icons.translate_outlined,
                    label: l10n.text('landingTemplateJapaneseFeatureBilingual'),
                  ),
                  _HeroChip(
                    icon: Icons.balance_outlined,
                    label: l10n.text('landingTemplateJapaneseFeatureTax'),
                  ),
                  _HeroChip(
                    icon: Icons.storefront_outlined,
                    label: l10n.text('landingTemplateJapaneseFeatureRetail'),
                  ),
                ],
              ),
            ],
          );
          final preview = _JapanesePreviewCard(palette: palette);
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                description,
                const SizedBox(height: 32),
                preview,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: description),
              const SizedBox(width: 32),
              Expanded(flex: 5, child: preview),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWorkflowSection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = math.max(24.0, width * 0.08);
    final contentWidth = width - horizontalPadding * 2;
    final isNarrow = width < 900;

    final steps = [
      (Icons.dashboard_customize_outlined, l10n.text('landingWorkflowStepCapture')),
      (Icons.style_outlined, l10n.text('landingWorkflowStepDesign')),
      (Icons.send_outlined, l10n.text('landingWorkflowStepSend')),
      (Icons.autorenew_outlined, l10n.text('landingWorkflowStepAutomate')),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('landingWorkflowTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.text('landingWorkflowSubtitle'),
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: List.generate(steps.length, (index) {
              final entry = steps[index];
              return SizedBox(
                width: isNarrow
                    ? double.infinity
                    : math.max(260.0, contentWidth / 4 - 15),
                child: _WorkflowStepCard(
                  index: index + 1,
                  icon: entry.$1,
                  description: entry.$2,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = math.max(24.0, width * 0.08);
    final contentWidth = width - horizontalPadding * 2;
    final isNarrow = width < 960;

    final cards = [
      _FeatureCard(
        icon: Icons.shield_outlined,
        title: l10n.text('landingSecurityFeature1Title'),
        description: l10n.text('landingSecurityFeature1Body'),
      ),
      _FeatureCard(
        icon: Icons.https_outlined,
        title: l10n.text('landingSecurityFeature2Title'),
        description: l10n.text('landingSecurityFeature2Body'),
      ),
      _FeatureCard(
        icon: Icons.support_agent_outlined,
        title: l10n.text('landingSecurityFeature3Title'),
        description: l10n.text('landingSecurityFeature3Body'),
      ),
    ];

    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 96,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('landingSecurityTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.text('landingSecuritySubtitle'),
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: cards
                .map((card) => SizedBox(
                      width: isNarrow
                          ? double.infinity
                          : math.max(320.0, contentWidth / 2 - 10),
                      child: card,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context, AppState appState) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final palette = invoiceTemplateSpec(InvoiceTemplate.executive);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: math.max(24.0, width * 0.08),
        vertical: 96,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: LinearGradient(
            colors: [palette.headerGradientColors.first.toColor(), palette.headerGradientColors.last.toColor()],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 18)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.text('landingCtaTitle'),
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.text('landingCtaSubtitle'),
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _openApp,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: palette.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  ),
                  child: Text(appState.isAuthenticated
                      ? l10n.text('landingCtaButtonAuthed')
                      : l10n.text('landingCtaButton')),
                ),
                if (appState.isGuest)
                  OutlinedButton(
                    onPressed: _openSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    ),
                    child: Text(l10n.text('signInButton')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final width = MediaQuery.of(context).size.width;
    final padding = math.max(24.0, width * 0.08);

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 48, padding, 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('appTitle'),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.text('landingFooterCopyright').replaceFirst('{year}', DateTime.now().year.toString()),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _openApp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  void _openSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  }

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }
}

class _LandingNavBar extends StatelessWidget {
  const _LandingNavBar({
    required this.onOpenProduct,
    required this.onOpenTemplates,
    required this.onOpenPricing,
    required this.onOpenSupport,
    required this.onLaunchApp,
    required this.currentLocale,
    required this.onLocaleSelected,
    required this.isLocaleChanging,
    this.onSignIn,
  });

  final VoidCallback onOpenProduct;
  final VoidCallback onOpenTemplates;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenSupport;
  final VoidCallback onLaunchApp;
  final Locale currentLocale;
  final Future<void> Function(Locale) onLocaleSelected;
  final bool isLocaleChanging;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isNarrow = MediaQuery.of(context).size.width < 840;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.text('appTitle'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (!isNarrow)
              Wrap(
                spacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _NavLink(label: l10n.text('landingNavProduct'), onTap: onOpenProduct),
                  _NavLink(label: l10n.text('landingNavTemplates'), onTap: onOpenTemplates),
                  _NavLink(label: l10n.text('landingNavPricing'), onTap: onOpenPricing),
                  _NavLink(label: l10n.text('landingNavSupport'), onTap: onOpenSupport),
                ],
              ),
            const SizedBox(width: 16),
            LanguageMenuButton(
              currentLocale: currentLocale,
              onSelected: onLocaleSelected,
              isBusy: isLocaleChanging,
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.12),
              borderColor: Colors.white.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            const SizedBox(width: 16),
            if (onSignIn != null)
              TextButton(
                onPressed: onSignIn,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(l10n.text('signInButton')),
              ),
            FilledButton(
              onPressed: onLaunchApp,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
              ),
              child: Text(l10n.text('landingHeroPrimaryCta')),
            ),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              LanguageMenuButton(
                currentLocale: currentLocale,
                onSelected: onLocaleSelected,
                isBusy: isLocaleChanging,
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.12),
                borderColor: Colors.white.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              _NavChip(label: l10n.text('landingNavProduct'), onTap: onOpenProduct),
              _NavChip(label: l10n.text('landingNavTemplates'), onTap: onOpenTemplates),
              _NavChip(label: l10n.text('landingNavPricing'), onTap: onOpenPricing),
              _NavChip(label: l10n.text('landingNavSupport'), onTap: onOpenSupport),
            ],
          ),
        ],
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: Colors.white.withOpacity(0.18),
      labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 18),
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TemplateHeroCard extends StatelessWidget {
  const _TemplateHeroCard({required this.spec});

  final InvoiceTemplateSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 40,
            offset: const Offset(0, 28),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: spec.headerGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('landingTemplateGlobalLabel'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: spec.headerText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.text('landingTemplateGlobalBody'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: spec.headerText.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.text('landingHeroPointPdf'), style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(context.l10n.text('landingHeroPointGlobal'), style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: spec.badgeBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.receipt_long_outlined, color: spec.accent, size: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  const _TemplatePreviewCard({required this.template, required this.width});

  final InvoiceTemplate template;
  final double width;

  @override
  Widget build(BuildContext context) {
    final spec = invoiceTemplateSpec(template);
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: spec.surface,
          border: Border.all(color: spec.border.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 36,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: spec.headerGradient,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.invoiceTemplateLabel(template),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.text(spec.blurbKey),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _JapanesePreviewCard extends StatelessWidget {
  const _JapanesePreviewCard({required this.palette});

  final InvoiceTemplateSpec palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: palette.headerGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.text('invoiceJapaneseTitle'),
                  style: theme.textTheme.titleLarge?.copyWith(color: palette.headerText, fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('株式会社 架空商事', style: theme.textTheme.titleSmall?.copyWith(color: palette.headerText)),
                    Text('〒150-0002 東京都渋谷区', style: theme.textTheme.bodySmall?.copyWith(color: palette.headerText.withOpacity(0.8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _PreviewRow(label: context.l10n.text('invoiceJapaneseNumberLabel'), value: 'INV-2024-081'),
          _PreviewRow(label: context.l10n.text('invoiceJapaneseIssueLabel'), value: '2024年5月1日'),
          _PreviewRow(label: context.l10n.text('invoiceJapaneseDueLabel'), value: '2024年5月31日'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.balanceBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.text('landingTemplateJapaneseAmount'), style: theme.textTheme.titleSmall?.copyWith(color: palette.accent)),
                const SizedBox(height: 6),
                Text('¥480,000', style: theme.textTheme.headlineSmall?.copyWith(color: palette.accent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({
    required this.index,
    required this.icon,
    required this.description,
  });

  final int index;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LandingLocaleOverlay extends StatelessWidget {
  const _LandingLocaleOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: theme.colorScheme.surface.withOpacity(0.75)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.text('loadingMessage'), style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ColorIntX on int {
  Color toColor() => Color(this);
}
