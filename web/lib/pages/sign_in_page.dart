import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _lastError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isLoading = appState.isLoading;
    final hasFirebase = appState.hasFirebase;
    final locale = appState.locale;

    final errorMessage = appState.errorMessage;
    if (errorMessage != null && errorMessage != _lastError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        context.read<AppState>().clearError();
      });
      _lastError = errorMessage;
    }

    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.4),
              secondaryColor.withOpacity(0.25),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 920;
              final maxCardWidth = isWide ? 400.0 : 520.0;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 980 : maxCardWidth + 48),
                  child: Card(
                    elevation: 16,
                    color: theme.colorScheme.surface.withOpacity(0.9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 48 : 32,
                        vertical: isWide ? 40 : 32,
                      ),
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(child: _buildHeroColumn(theme, l10n, appState)),
                                const SizedBox(width: 48),
                                SizedBox(width: maxCardWidth, child: _buildForm(context, theme, l10n, appState, hasFirebase, locale, isLoading)),
                              ],
                            )
                          : _buildForm(context, theme, l10n, appState, hasFirebase, locale, isLoading),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroColumn(ThemeData theme, AppLocalizations l10n, AppState appState) {
    final headline = theme.textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );

    final body = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Chip(
          label: Text(l10n.text('signInHeroBadge')),
          avatar: const Icon(Icons.workspace_premium, size: 18),
          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.6),
          labelStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 24),
        Text(l10n.text('signInHeroTitle'), style: headline),
        const SizedBox(height: 16),
        Text(l10n.text('signInHeroSubtitle'), style: body),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _HeroPill(icon: Icons.picture_as_pdf_outlined, label: l10n.text('signInHeroFeatureOne')),
            _HeroPill(icon: Icons.auto_graph_outlined, label: l10n.text('signInHeroFeatureTwo')),
            _HeroPill(icon: Icons.security_outlined, label: l10n.text('signInHeroFeatureThree')),
          ],
        ),
        const SizedBox(height: 40),
        if (!appState.isAuthenticated)
          Text(
            l10n.text('signInHeroFooter'),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    AppState appState,
    bool hasFirebase,
    Locale locale,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: locale,
                    onChanged: (value) {
                      if (value != null) context.read<AppState>().setLocale(value);
                    },
                    items: const [
                      DropdownMenuItem(value: Locale('en'), child: Text('English')),
                      DropdownMenuItem(value: Locale('ja'), child: Text('日本語')),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.text(_isSignUp ? 'signUpTitle' : 'signInTitle'),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.text(_isSignUp ? 'signUpSubtitle' : 'signInSubtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          if (!hasFirebase)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.text('firebaseBanner'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.text('displayNameLabel'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (!_isSignUp) return null;
                      if (value == null || value.trim().isEmpty) {
                        return l10n.text('validationRequired');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.text('emailLabel'),
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.text('validationRequired');
                    }
                    final regex = RegExp(r'^.+@.+\..+$');
                    if (!regex.hasMatch(value.trim())) {
                      return l10n.text('validationEmail');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.text('passwordLabel'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.text('validationRequired');
                    }
                    if (value.length < 6) {
                      return l10n.text('validationPasswordLength');
                    }
                    return null;
                  },
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: l10n.text('confirmPasswordLabel'),
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (!_isSignUp) return null;
                      if (value == null || value.isEmpty) {
                        return l10n.text('validationRequired');
                      }
                      if (value != _passwordController.text) {
                        return l10n.text('validationPasswordMatch');
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                      ),
                    )
                  : Icon(_isSignUp ? Icons.person_add_alt : Icons.login),
              label: Text(l10n.text(_isSignUp ? 'signUpButton' : 'signInButton')),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(l10n.text('validationEmail'))));
                        return;
                      }
                      if (!hasFirebase) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(l10n.text('firebaseMissing'))));
                        return;
                      }
                      try {
                        await context.read<AppState>().sendPasswordReset(email);
                        if (!mounted) return;
                        if (context.read<AppState>().errorMessage == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(l10n.text('resetPasswordSent'))));
                        }
                      } catch (_) {
                        // Errors handled via AppState.errorMessage.
                      }
                    },
              child: Text(l10n.text('forgotPassword')),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                    context.read<AppState>().clearError();
                  },
            child: Text(
              _isSignUp ? l10n.text('haveAccountPrompt') : l10n.text('noAccountPrompt'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final appState = context.read<AppState>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      final name = _nameController.text.trim();
      await appState.signUp(displayName: name, email: email, password: password);
    } else {
      await appState.signIn(email: email, password: password);
    }

    if (!mounted) return;
    if (appState.isAuthenticated) {
      Navigator.of(context).pop();
    }
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
