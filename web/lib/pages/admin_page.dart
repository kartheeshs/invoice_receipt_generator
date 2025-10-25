import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/invoice.dart';
import '../state/app_state.dart';
import '../widgets/language_menu_button.dart';

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
    final invoices = appState.invoices;
    final premiumAccounts = accounts.where((account) => account.isPremium).toList();
    final currencyFormat = NumberFormat.currency(
      name: appState.profile.currencyCode,
      symbol: appState.profile.currencySymbol,
    );
    final totalRevenue = invoices.fold<double>(0, (sum, invoice) => sum + invoice.amount);
    final outstanding = appState.outstandingTotal;
    final averageInvoice = appState.averageInvoice;
    final recurringRevenue = appState.planPrice * premiumAccounts.length;
    final revenueTrend = _buildRevenueTrend(invoices, l10n.locale);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.maxWidth == double.infinity ? 1100.0 : constraints.maxWidth;
        final metricColumns = maxWidth >= 1100
            ? 3
            : maxWidth >= 720
                ? 2
                : 1;
        final spacing = 16.0;
        final double metricWidth = metricColumns == 1
            ? maxWidth
            : (maxWidth - spacing * (metricColumns - 1)) / metricColumns;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminHeader(
                  accountCount: accounts.length,
                  monthlyPriceLabel: currencyFormat.format(appState.planPrice),
                  l10n: l10n,
                  theme: theme,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: metricWidth,
                      child: _AdminMetricCard(
                        icon: Icons.currency_exchange_outlined,
                        title: l10n.text('adminMetricRevenue'),
                        value: currencyFormat.format(totalRevenue),
                        caption: l10n.text('adminMetricRevenueCaption'),
                      ),
                    ),
                    SizedBox(
                      width: metricWidth,
                      child: _AdminMetricCard(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.text('adminMetricOutstanding'),
                        value: currencyFormat.format(outstanding),
                        caption: l10n.text('adminMetricOutstandingCaption'),
                      ),
                    ),
                    SizedBox(
                      width: metricWidth,
                      child: _AdminMetricCard(
                        icon: Icons.groups_outlined,
                        title: l10n.text('adminMetricActiveSubscribers'),
                        value: premiumAccounts.length.toString(),
                        caption:
                            '${l10n.text('adminMetricRecurringRevenue')}: ${currencyFormat.format(recurringRevenue)}',
                      ),
                    ),
                    SizedBox(
                      width: metricWidth,
                      child: _AdminMetricCard(
                        icon: Icons.analytics_outlined,
                        title: l10n.text('adminMetricAverageInvoice'),
                        value: currencyFormat.format(averageInvoice),
                        caption: l10n.text('adminMetricAverageInvoiceCaption'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _AdminRevenueCard(
                  trend: revenueTrend,
                  currencyFormat: currencyFormat,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
                _AdminSubscriptionsCard(
                  accounts: premiumAccounts,
                  currencyFormat: currencyFormat,
                  l10n: l10n,
                  planPrice: appState.planPrice,
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
      },
    );
  }
}

class AdminStandalonePage extends StatelessWidget {
  const AdminStandalonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.text('adminTitle')),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LanguageMenuButton(
              currentLocale: appState.locale,
              onSelected: (locale) => context.read<AppState>().setLocale(locale),
              isBusy: appState.isLocaleChanging,
              foregroundColor: theme.colorScheme.onSurface,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              borderColor: theme.colorScheme.outlineVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: appState.isAdmin
                ? OutlinedButton.icon(
                    onPressed: () => context.read<AppState>().adminSignOut(),
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.text('adminLogout')),
                  )
                : (appState.isGuest
                    ? FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/sign-in'),
                        icon: const Icon(Icons.login),
                        label: Text(l10n.text('signInButton')),
                      )
                    : FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/app'),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l10n.text('landingHeroPrimaryCta')),
                      )),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: appState.isAdmin
                ? const AdminPage()
                : _AdminLoginView(
                    isLoading: appState.isAdminLoading,
                    errorMessage: appState.adminErrorMessage,
                    errorKey: appState.adminErrorKey,
                    onFieldChanged: context.read<AppState>().clearAdminError,
                    onSubmit: (email, password) => context.read<AppState>().adminSignIn(
                          email: email,
                          password: password,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AdminLoginView extends StatefulWidget {
  const _AdminLoginView({
    required this.isLoading,
    required this.errorMessage,
    required this.errorKey,
    required this.onSubmit,
    required this.onFieldChanged,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? errorKey;
  final void Function(String email, String password) onSubmit;
  final VoidCallback onFieldChanged;

  @override
  State<_AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<_AdminLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final form = _formKey.currentState;
    if (form == null) {
      return;
    }
    if (!form.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.always;
      });
      return;
    }
    if (widget.isLoading) return;
    FocusScope.of(context).unfocus();
    widget.onSubmit(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final errorText = widget.errorKey != null ? l10n.text(widget.errorKey!) : widget.errorMessage;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.text('adminLoginTitle'), style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      l10n.text('adminLoginSubtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 24),
                    if (errorText != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          errorText,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.text('adminIdLabel'),
                        prefixIcon: const Icon(Icons.alternate_email),
                      ),
                      onChanged: (_) => widget.onFieldChanged(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.text('adminEmailRequired');
                        }
                        if (!value.contains('@')) {
                          return l10n.text('adminEmailInvalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.text('adminPasswordLabel'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      onChanged: (_) => widget.onFieldChanged(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.text('adminPasswordRequired');
                        }
                        if (value.length < 6) {
                          return l10n.text('adminPasswordTooShort');
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _handleSubmit,
                      icon: widget.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.admin_panel_settings_outlined),
                      label: Text(widget.isLoading
                          ? l10n.text('adminLoginLoading')
                          : l10n.text('adminLoginButton')),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.accountCount,
    required this.monthlyPriceLabel,
    required this.l10n,
    required this.theme,
  });

  final int accountCount;
  final String monthlyPriceLabel;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.text('adminTitle'), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          l10n.text('adminSubtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Chip(
              avatar: const Icon(Icons.people_alt_outlined, size: 18),
              label: Text('${l10n.text('adminHeaderAccounts')}: $accountCount'),
            ),
            Chip(
              avatar: const Icon(Icons.credit_card_outlined, size: 18),
              label: Text('${l10n.text('adminHeaderPlanPrice')}: $monthlyPriceLabel'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRevenueCard extends StatelessWidget {
  const _AdminRevenueCard({
    required this.trend,
    required this.currencyFormat,
    required this.l10n,
  });

  final List<_TrendPoint> trend;
  final NumberFormat currencyFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('adminTrendTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (trend.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.text('adminTrendEmpty'), style: theme.textTheme.bodyMedium),
              )
            else
              SizedBox(
                height: 240,
                child: _RevenueTrendChart(
                  trend: trend,
                  currencyFormat: currencyFormat,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  const _RevenueTrendChart({required this.trend, required this.currencyFormat});

  final List<_TrendPoint> trend;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = trend.fold<double>(0, (value, point) => point.total > value ? point.total : value);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final barWidth = trend.isEmpty
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (trend.length - 1)) / trend.length;
        final maxBarHeight = (constraints.maxHeight - 60).clamp(48.0, constraints.maxHeight);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < trend.length; i++) ...[
              SizedBox(
                width: barWidth.isFinite && barWidth > 0 ? barWidth : constraints.maxWidth / trend.length,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: maxValue == 0
                              ? 8
                              : (trend[i].total / maxValue) * maxBarHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.85),
                                theme.colorScheme.primaryContainer,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currencyFormat.format(trend[i].total),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trend[i].label,
                      style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
              if (i != trend.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class _AdminSubscriptionsCard extends StatelessWidget {
  const _AdminSubscriptionsCard({
    required this.accounts,
    required this.currencyFormat,
    required this.l10n,
    required this.planPrice,
  });

  final List<ManagedAccount> accounts;
  final NumberFormat currencyFormat;
  final AppLocalizations l10n;
  final double planPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('adminSubscriptionListTitle'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.text('adminSubscriptionEmpty'), style: theme.textTheme.bodyMedium),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < accounts.length; i++) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Text(_initials(accounts[i].displayName)),
                      ),
                      title: Text(accounts[i].displayName),
                      subtitle: Text(_subscriptionDetails(accounts[i])),
                      trailing: Text(
                        accounts[i].isPremium
                            ? '${currencyFormat.format(planPrice)} / ${l10n.text('adminSubscriptionMonthly')}'
                            : l10n.text('adminSubscriptionInactive'),
                      ),
                    ),
                    if (i != accounts.length - 1) const Divider(height: 20),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _subscriptionDetails(ManagedAccount account) {
    final localeTag = l10n.locale.toLanguageTag();
    final plan = '${l10n.text('adminSubscriptionPlan')}: ${account.plan}';
    final since = account.subscriptionSince != null
        ? '${l10n.text('adminSubscriptionSince')}: ${DateFormat.yMMMd(localeTag).format(account.subscriptionSince!)}'
        : l10n.text('adminSubscriptionNoStart');
    return '$plan • $since';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final firstCodeUnit = trimmed.runes.first;
    return String.fromCharCode(firstCodeUnit).toUpperCase();
  }
}

class _TrendPoint {
  const _TrendPoint({required this.label, required this.total});

  final String label;
  final double total;
}

List<_TrendPoint> _buildRevenueTrend(List<Invoice> invoices, Locale locale) {
  if (invoices.isEmpty) {
    return const [];
  }
  final now = DateTime.now();
  final months = List.generate(6, (index) {
    final date = DateTime(now.year, now.month - (5 - index), 1);
    return DateTime(date.year, date.month);
  });
  final Map<DateTime, double> totals = {
    for (final month in months) month: 0,
  };
  for (final invoice in invoices) {
    final monthDate = DateTime(invoice.issueDate.year, invoice.issueDate.month);
    final diff = (now.year - monthDate.year) * 12 + now.month - monthDate.month;
    if (diff >= 0 && diff < months.length) {
      final key = DateTime(monthDate.year, monthDate.month);
      totals[key] = (totals[key] ?? 0) + invoice.amount;
    }
  }
  final formatter = DateFormat('MMM', locale.toLanguageTag());
  return months
      .map((month) => _TrendPoint(label: formatter.format(month), total: totals[month] ?? 0))
      .toList();
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
    final localeTag = l10n.locale.toLanguageTag();
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
                        avatar: const Icon(Icons.layers_outlined, size: 18),
                        label: Text('${l10n.text('adminSubscriptionPlan')}: ${account.plan}'),
                      ),
                      Chip(
                        avatar: Icon(
                          account.isPremium ? Icons.star : Icons.star_border,
                          size: 18,
                        ),
                        label: Text(account.isPremium
                            ? l10n.text('adminPremiumLabel')
                            : l10n.text('planStatusFree')),
                      ),
                      if (account.subscriptionSince != null)
                        Chip(
                          avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                          label: Text(
                            '${l10n.text('adminSubscriptionSinceShort')} ${DateFormat.yMMMd(localeTag).format(account.subscriptionSince!)}',
                          ),
                        ),
                      if (account.hasAdminRole)
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
              value: account.hasAdminRole,
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
