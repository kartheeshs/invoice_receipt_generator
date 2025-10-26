
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
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final seed = isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB);
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
      surface: isDark ? const Color(0xFF0B1220) : const Color(0xFFFDFEFF),
      background: isDark ? const Color(0xFF050B18) : const Color(0xFFF4F6FB),
      surfaceVariant: isDark ? const Color(0xFF101B2B) : const Color(0xFFEFF3FF),
      outlineVariant: isDark ? const Color(0xFF24324D) : const Color(0xFFD5DCF2),
      secondary: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
      tertiary: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF97316),
    );

    final baseText = GoogleFonts.interTextTheme(base.textTheme);
    final headingColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final bodyColor = isDark ? const Color(0xFFCBD5F5) : const Color(0xFF475467);

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(color: headingColor, fontWeight: FontWeight.w700),
      headlineMedium: baseText.headlineMedium?.copyWith(color: headingColor, fontWeight: FontWeight.w700),
      titleLarge: baseText.titleLarge?.copyWith(color: headingColor, fontWeight: FontWeight.w700),
      bodyLarge: baseText.bodyLarge?.copyWith(color: bodyColor, height: 1.6),
      bodyMedium: baseText.bodyMedium?.copyWith(color: bodyColor),
      labelLarge: baseText.labelLarge?.copyWith(color: headingColor, fontWeight: FontWeight.w600),
    );

    final cardColor = isDark ? const Color(0xFF101B2B) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF1F2A3D) : const Color(0xFFE2E8F0);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: headingColor,
        titleTextStyle: textTheme.titleLarge,
        toolbarTextStyle: textTheme.bodyMedium,
        iconTheme: IconThemeData(color: headingColor),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 4 : 8,
        shadowColor: isDark ? Colors.black38 : const Color(0xFFB8C5FF).withOpacity(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: colorScheme.primary.withOpacity(0.4)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: textTheme.labelLarge,
        selectedColor: colorScheme.primary.withOpacity(0.16),
        backgroundColor: colorScheme.primary.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: cardColor,
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textColor: headingColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: cardColor.withOpacity(isDark ? 0.9 : 0.95),
        indicatorColor: colorScheme.primary.withOpacity(0.16),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final color = states.contains(MaterialState.selected) ? colorScheme.primary : bodyColor;
          return textTheme.labelLarge?.copyWith(color: color);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withOpacity(0.12),
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1C2A3D) : Colors.black87,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

}
