
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    required this.isLoading,
    required this.onSignIn,
    required this.onSignUp,
    required this.onForgotPassword,
    required this.errorMessage,
    required this.clearError,
    required this.hasFirebase,
    required this.locale,
    required this.onLocaleChanged,
  });

  final bool isLoading;
  final Future<void> Function(String email, String password) onSignIn;
  final Future<void> Function(String name, String email, String password) onSignUp;
  final Future<void> Function(String email) onForgotPassword;
  final String? errorMessage;
  final VoidCallback clearError;
  final bool hasFirebase;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

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

  @override
  void didUpdateWidget(covariant SignInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null && widget.errorMessage != oldWidget.errorMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.errorMessage!)),
        );
        widget.clearError();
      });
    }
  }

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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DropdownButton<Locale>(
                        value: widget.locale,
                        onChanged: (value) {
                          if (value != null) widget.onLocaleChanged(value);
                        },
                        items: const [
                          DropdownMenuItem(value: Locale('en'), child: Text('English')),
                          DropdownMenuItem(value: Locale('ja'), child: Text('日本語')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.text(_isSignUp ? 'signUpTitle' : 'signInTitle'),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    if (!widget.hasFirebase)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.text('firebaseBanner'),
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
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
                              decoration: InputDecoration(labelText: l10n.text('displayNameLabel')),
                              validator: (value) {
                                if (!_isSignUp) return null;
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.text('validationRequired');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(labelText: l10n.text('emailLabel')),
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: l10n.text('passwordLabel'),
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
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(labelText: l10n.text('confirmPasswordLabel')),
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: widget.isLoading ? null : _submit,
                      child: widget.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                              ),
                            )
                          : Text(l10n.text(_isSignUp ? 'signUpButton' : 'signInButton')),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: widget.isLoading
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.text('validationEmail'))),
                                  );
                                  return;
                                }
                                if (!widget.hasFirebase) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.text('firebaseMissing'))),
                                  );
                                  return;
                                }
                                try {
                                  await widget.onForgotPassword(email);
                                  if (!mounted) return;
                                  final error = context.read<AppState>().errorMessage;
                                  if (error == null) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(content: Text(l10n.text('resetPasswordSent'))));
                                  }
                                } catch (_) {
                                  // Errors are reported via AppState.errorMessage
                                }
                              },
                        child: Text(l10n.text('forgotPassword')),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: widget.isLoading
                          ? null
                          : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                              });
                            },
                      child: Text(
                        _isSignUp ? l10n.text('haveAccountPrompt') : l10n.text('noAccountPrompt'),
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

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isSignUp) {
      final name = _nameController.text.trim();
      await widget.onSignUp(name, email, password);
    } else {
      await widget.onSignIn(email, password);
    }
  }
}
