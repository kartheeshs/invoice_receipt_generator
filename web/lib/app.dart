
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
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
        ? const Color(0xFF7C3AED)
        : const Color(0xFF4F46E5);
    var colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final accent = brightness == Brightness.dark ? const Color(0xFF22D3EE) : const Color(0xFF0EA5E9);
    colorScheme = colorScheme.copyWith(
      secondary: brightness == Brightness.dark ? const Color(0xFFF472B6) : const Color(0xFFFB7185),
      tertiary: accent,
      surface: brightness == Brightness.dark ? const Color(0xFF0B1120) : const Color(0xFFF4F7FF),
      background: brightness == Brightness.dark ? const Color(0xFF050A19) : const Color(0xFFF0F4FF),
    );

    final cardSurface = brightness == Brightness.dark ? const Color(0xFF131C2F) : Colors.white;
    final textColor = brightness == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF101733);
    final shadowColor = brightness == Brightness.dark ? Colors.black54 : const Color(0xFFB3C6FF);

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      textTheme: textTheme,
      primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 12,
        shadowColor: shadowColor.withOpacity(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: brightness == Brightness.dark ? const Color(0xFF1C2741) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.28)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.55)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 3,
          shadowColor: colorScheme.primary.withOpacity(0.35),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.tertiary,
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: cardSurface.withOpacity(0.94),
        indicatorColor: colorScheme.primary.withOpacity(0.14),
        labelTextStyle: MaterialStateProperty.all(textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.primary.withOpacity(0.08),
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelLarge?.copyWith(color: textColor),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: textColor.withOpacity(0.92)),
      ),
      dividerTheme: DividerThemeData(
        color: textColor.withOpacity(0.08),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: cardSurface,
      ),
    );
  }

}
