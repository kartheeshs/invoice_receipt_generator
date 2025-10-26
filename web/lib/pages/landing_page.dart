
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../models/invoice_template_spec.dart';
import '../state/app_state.dart';
import '../widgets/language_menu_button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _LandingNav(appState: appState, l10n: l10n)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: _HeroSection(
                  onLaunch: () => Navigator.of(context).pushNamed('/app'),
                  stats: const [
                    _Metric(value: '1.8k+', label: 'Teams billing with Atlas each month'),
                    _Metric(value: '3 min', label: 'Average draft-to-download time'),
                    _Metric(value: '28', label: 'Currencies formatted automatically'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _FeatureSection(features: _features),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _TemplateSection(
                  templates: appState.availableTemplates,
                  onSelect: (template) {
                    final invoice = appState.prepareInvoice(template: template);
                    appState.selectInvoice(invoice);
                    Navigator.of(context).pushNamed('/app');
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _WorkflowSection(steps: _workflowSteps),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _PricingSection(plans: _plans, onLaunch: () => Navigator.of(context).pushNamed('/app')),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: _CallToAction(onLaunch: () => Navigator.of(context).pushNamed('/app')),
              ),
            ),
            SliverToBoxAdapter(child: _Footer(appState: appState, l10n: l10n)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}

class _LandingNav extends StatelessWidget {
  const _LandingNav({required this.appState, required this.l10n});

  final AppState appState;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice Atlas', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Polished invoices in minutes',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1.1),
                ),
              ),
            ],
          ),
          const Spacer(),
          LanguageMenuButton(
            currentLocale: appState.locale,
            onSelected: (locale) => context.read<AppState>().setLocale(locale),
            isBusy: appState.isLocaleChanging,
            foregroundColor: theme.colorScheme.onSurface,
            backgroundColor: theme.colorScheme.surface,
            borderColor: theme.colorScheme.outlineVariant,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamed('/app'),
            child: Text(l10n.text('launchAppButton')),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onLaunch, required this.stats});

  final VoidCallback onLaunch;
  final List<_Metric> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 960;
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(colorScheme.brightness == Brightness.dark ? 0.4 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 26),
              ),
            ],
          ),
          child: Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: isWide ? 11 : 0,
                child: Column(
                  crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Invoice & receipt workspace',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Send polished invoices in minutes, not hours.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                      ),
                      textAlign: isWide ? TextAlign.start : TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Build branded invoices and receipts with finance-approved templates, collaborate with teammates, and export vector-perfect PDFs from one workspace.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: isWide ? TextAlign.start : TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: onLaunch,
                          child: const Text('Launch the app'),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pushNamed('/app'),
                          child: const Text('View dashboard'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
                      children: stats
                          .map(
                            (metric) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    metric.value,
                                    style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    metric.label,
                                    style: theme.textTheme.bodySmall,
                                    textAlign: isWide ? TextAlign.start : TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28, width: 28),
              Expanded(
                flex: isWide ? 9 : 0,
                child: _HeroPreviewCard(colorScheme: colorScheme),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPreviewCard extends StatelessWidget {
  const _HeroPreviewCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Live PDF preview',
              style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary, letterSpacing: 1.1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Every change you make — colours, copy, totals — updates the PDF instantly so you always know what clients will see.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _TemplatePreviewCard(spec: invoiceTemplateSpec(InvoiceTemplate.waveBlue)),
        ],
      ),
    );
  }
}



class _FeatureSection extends StatelessWidget {
  const _FeatureSection({required this.features});

  final List<_Feature> features;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Everything you need to move from draft to paid',
          body: 'Start with a finance-reviewed template, adjust the details, and export with confidence. No design tools required.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final columns = maxWidth > 960
                ? 3
                : maxWidth > 640
                    ? 2
                    : 1;
            final itemWidth = maxWidth / columns - (16 * (columns - 1) / columns);
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: features
                  .map(
                    (feature) => SizedBox(
                      width: itemWidth,
                      child: _FeatureCard(feature: feature),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.colorScheme.brightness == Brightness.dark ? 0.35 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(feature.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(feature.body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TemplateSection extends StatelessWidget {
  const _TemplateSection({required this.templates, required this.onSelect});

  final List<InvoiceTemplate> templates;
  final ValueChanged<InvoiceTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Template gallery',
          body: 'Swap layouts with a click. Every template adjusts typography, colour, and summary blocks without breaking your data.',
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: templates
              .map(
                (template) => _TemplateCard(
                  template: template,
                  onTap: () => onSelect(template),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final InvoiceTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = invoiceTemplateSpec(template);
    final l10n = context.l10n;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: 280,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.colorScheme.brightness == Brightness.dark ? 0.35 : 0.08),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TemplatePreviewCard(spec: spec),
              const SizedBox(height: 16),
              Text(l10n.text(spec.labelKey), style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(l10n.text(spec.blurbKey), style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              Text('Use template', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatePreviewCard extends StatelessWidget {
  const _TemplatePreviewCard({required this.spec});

  final InvoiceTemplateSpec spec;

  @override
  Widget build(BuildContext context) {
    final gradient = spec.headerGradientColors.map((color) => Color(color)).toList();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75 - index * 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection({required this.steps});

  final List<_WorkflowStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Designed for the full billing workflow',
          body: 'From the first draft to the paid receipt, Invoice Atlas keeps teams aligned and clients confident.',
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: steps
              .map(
                (step) => SizedBox(
                  width: 320,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(theme.colorScheme.brightness == Brightness.dark ? 0.35 : 0.08),
                          blurRadius: 26,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.step, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 12),
                        Text(step.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(step.body, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({required this.plans, required this.onLaunch});

  final List<_PricingPlan> plans;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          title: 'Pricing that scales with your billing volume',
          body: 'Start free, upgrade when collaboration or automation becomes essential. No surprise fees—ever.',
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: plans
              .map(
                (plan) => SizedBox(
                  width: 280,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: plan.featured
                            ? theme.colorScheme.primary.withOpacity(0.3)
                            : theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(theme.colorScheme.brightness == Brightness.dark ? 0.35 : 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.tier, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(plan.description, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 16),
                        Text(plan.price, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        ...plan.points.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(point, style: theme.textTheme.bodySmall)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: onLaunch,
                          child: const Text('Get started'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CallToAction extends StatelessWidget {
  const _CallToAction({required this.onLaunch});

  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            'Ready to send your next invoice?',
            style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Spin up a polished invoice in minutes and keep every client touchpoint on brand.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: onLaunch,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onPrimary,
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Launch workspace'),
              ),
              OutlinedButton(
                onPressed: onLaunch,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  side: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                ),
                child: const Text('View dashboard'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.appState, required this.l10n});

  final AppState appState;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice Atlas', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create invoice and receipt PDFs that feel bespoke without fighting a designer.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamed('/app'),
                child: Text(l10n.text('launchAppButton')),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => appState.setLocale(
                  appState.locale.languageCode == 'en' ? const Locale('ja') : const Locale('en'),
                ),
                child: Text(l10n.text('languageLabel')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _Metric {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;
}

class _Feature {
  const _Feature({required this.title, required this.body});

  final String title;
  final String body;
}

class _WorkflowStep {
  const _WorkflowStep({required this.step, required this.title, required this.body});

  final String step;
  final String title;
  final String body;
}

class _PricingPlan {
  const _PricingPlan({
    required this.tier,
    required this.price,
    required this.description,
    required this.points,
    this.featured = false,
  });

  final String tier;
  final String price;
  final String description;
  final List<String> points;
  final bool featured;
}

const _features = <_Feature>[
  _Feature(
    title: 'Editor that keeps context',
    body: 'Update line items, payment terms, and brand colours while the PDF preview mirrors every change in real time.',
  ),
  _Feature(
    title: 'Templates clients trust',
    body: 'Choose clean finance-reviewed layouts with balance summaries, bilingual labels, and optional signature space.',
  ),
  _Feature(
    title: 'Collaboration built-in',
    body: 'Invite teammates, assign approvals, and leave comments without exposing the entire billing history.',
  ),
  _Feature(
    title: 'Automations that feel human',
    body: 'Schedule reminders, tailor follow-up copy, and monitor payment status from a single dashboard.',
  ),
];

const _workflowSteps = <_WorkflowStep>[
  _WorkflowStep(
    step: '01',
    title: 'Personalise the canvas',
    body: 'Upload your logo, choose a template, and set reusable blocks for service notes or tax language.',
  ),
  _WorkflowStep(
    step: '02',
    title: 'Fill once, reuse forever',
    body: 'Store client records, payment terms, and bank info so new documents start from a polished base.',
  ),
  _WorkflowStep(
    step: '03',
    title: 'Share instantly',
    body: 'Export vector-perfect PDFs, send secure links, or deliver branded emails with automatic reminders.',
  ),
];

const _plans = <_PricingPlan>[
  _PricingPlan(
    tier: 'Starter',
    price: '\$0',
    description: 'For solo builders who need professional invoices without the busywork.',
    points: [
      'Unlimited invoices & receipts',
      'Two premium template families',
      'Smart reminders and status tracking',
    ],
  ),
  _PricingPlan(
    tier: 'Growth',
    price: '\$24/mo',
    featured: true,
    description: 'Unlock collaboration, version history, and automation for scaling teams.',
    points: [
      'Everything in Starter',
      'Approval workflows & roles',
      'Template version history',
      'Analytics workspace',
    ],
  ),
  _PricingPlan(
    tier: 'Enterprise',
    price: 'Let’s talk',
    description: 'SOC2-ready deployment with custom templates, SSO, and dedicated support.',
    points: [
      'Dedicated CSM & migration',
      'Custom domains & SSO',
      'Bespoke template engineering',
    ],
  ),
];
