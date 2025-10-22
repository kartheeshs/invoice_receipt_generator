import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'home_shell.dart';
import 'sign_in_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.user == null) {
      return SignInPage(
        isLoading: appState.isLoading,
        onSignIn: (email, password) => context.read<AppState>().signIn(email: email, password: password),
        onSignUp: (name, email, password) =>
            context.read<AppState>().signUp(displayName: name, email: email, password: password),
        onForgotPassword: (email) => context.read<AppState>().sendPasswordReset(email),
        errorMessage: appState.errorMessage,
        clearError: context.read<AppState>().clearError,
        hasFirebase: appState.hasFirebase,
        locale: appState.locale,
        onLocaleChanged: context.read<AppState>().setLocale,
      );
    }
    return const HomeShell();
  }
}
