import 'package:firebase_auth/firebase_auth.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessController = TextEditingController();
  final _ownerController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isRegisterMode ? l10n.registerTitle : l10n.signInTitle,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegisterMode ? l10n.registerSubtitle : l10n.signInSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: l10n.emailFieldLabel,
                            hintText: 'you@example.com',
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return l10n.emailRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: l10n.passwordFieldLabel,
                          ),
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isEmpty) {
                              return l10n.passwordRequired;
                            }
                            if (trimmed.length < 6) {
                              return l10n.passwordLengthError;
                            }
                            return null;
                          },
                        ),
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessController,
                            decoration: InputDecoration(
                              labelText: l10n.signUpBusinessNameLabel,
                              hintText: l10n.signUpBusinessNameHint,
                            ),
                            validator: (value) {
                              if (!_isRegisterMode) {
                                return null;
                              }
                              if ((value ?? '').trim().isEmpty) {
                                return l10n.fieldRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ownerController,
                            decoration: InputDecoration(
                              labelText: l10n.signUpOwnerNameLabel,
                              hintText: l10n.signUpOwnerNameHint,
                            ),
                            validator: (value) {
                              if (!_isRegisterMode) {
                                return null;
                              }
                              if ((value ?? '').trim().isEmpty) {
                                return l10n.fieldRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isLoading ? null : () => _submit(l10n),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isRegisterMode ? l10n.submitRegister : l10n.submitSignIn),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  final state = context.read<AppState>();
                                  setState(() {
                                    _isRegisterMode = !_isRegisterMode;
                                    _error = null;
                                    if (_isRegisterMode) {
                                      _businessController.text = state.businessName;
                                      _ownerController.text = state.ownerName;
                                    }
                                  });
                                },
                          child: Text(
                            _isRegisterMode ? l10n.toggleToSignIn : l10n.toggleToRegister,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.crispPlanDescription,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isRegisterMode) {
        await auth.createUserWithEmailAndPassword(email: email, password: password);
        final appState = context.read<AppState>();
        appState.updateBusinessProfile(
          newBusinessName: _businessController.text.trim(),
          newOwnerName: _ownerController.text.trim(),
          newEmail: email,
          newPhoneNumber: appState.phoneNumber,
          newPostalCode: appState.postalCode,
          newAddress: appState.address,
        );
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        final appState = context.read<AppState>();
        appState.updateBusinessProfile(
          newBusinessName: appState.businessName,
          newOwnerName: appState.ownerName,
          newEmail: email,
          newPhoneNumber: appState.phoneNumber,
          newPostalCode: appState.postalCode,
          newAddress: appState.address,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = l10n.authErrorMessage(e.code);
      });
    } catch (_) {
      setState(() {
        _error = l10n.authGenericError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
