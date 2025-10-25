
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'pages/admin_page.dart';
import 'pages/home_shell.dart';
import 'pages/landing_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/privacy_policy_page.dart';
import 'services/auth_service.dart';
import 'services/crisp_service.dart';
import 'services/pdf_service.dart';
import 'state/app_state.dart';

class InvoiceApp extends StatelessWidget {
  const InvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.fromEnvironment();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            config: config,
            authService: FirebaseAuthService(apiKey: config.firebaseApiKey),
            pdfService: PdfService(),
            crispService: CrispService(config.crispSubscriptionUrl),
          ),
        ),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Invoice & Receipt Generator',
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: ThemeMode.system,
            locale: appState.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const LandingPage(),
                    settings: settings,
                  );
                case '/app':
                  return MaterialPageRoute(
                    builder: (_) => const HomeShell(),
                    settings: settings,
                  );
                case '/sign-in':
                  return MaterialPageRoute(
                    builder: (_) => const SignInPage(),
                    settings: settings,
                  );
                case '/admin':
                  return MaterialPageRoute(
                    builder: (_) => const AdminStandalonePage(),
                    settings: settings,
                  );
                case '/privacy':
                  return MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage(),
                    settings: settings,
                  );
                default:
                  return MaterialPageRoute(
                    builder: (_) => const LandingPage(),
                    settings: settings,
                  );
              }
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    );
    final seed = brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final surface = brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardSurface = brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = brightness == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final shadowColor = brightness == Brightness.dark ? Colors.black54 : const Color(0xFFCBD5F5);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      textTheme: base.textTheme.apply(bodyColor: textColor, displayColor: textColor),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      cardTheme: CardTheme(
        color: cardSurface,
        elevation: 8,
        shadowColor: shadowColor.withOpacity(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.72)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardSurface,
        indicatorColor: colorScheme.primary.withOpacity(0.12),
        labelTextStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: base.textTheme.labelLarge?.copyWith(color: textColor),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700),
        contentTextStyle: base.textTheme.bodyLarge?.copyWith(color: textColor.withOpacity(0.9)),
      ),
    );
  }

}
