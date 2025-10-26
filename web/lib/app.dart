
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
    var colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    colorScheme = colorScheme.copyWith(
      secondary: isDark ? const Color(0xFF8B5CF6) : const Color(0xFF7C3AED),
      tertiary: isDark ? const Color(0xFFFBBF24) : const Color(0xFFF97316),
      surface: isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
      surfaceVariant: isDark ? const Color(0xFF121C33) : const Color(0xFFF1F5FF),
      background: isDark ? const Color(0xFF050B18) : const Color(0xFFF1F5FF),
      outlineVariant: isDark ? const Color(0xFF24324D) : const Color(0xFFD6E0FF),
      error: isDark ? const Color(0xFFFB7185) : const Color(0xFFEF4444),
    );

    final cardSurface = isDark ? const Color(0xFF101A2B) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subduedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, color: textColor),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, color: subduedText),
      labelLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: textColor),
    );

    final primaryTextTheme = GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    final borderRadius = BorderRadius.circular(24);
    final buttonRadius = BorderRadius.circular(20);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      canvasColor: colorScheme.surface,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleTextStyle: textTheme.titleLarge,
        toolbarTextStyle: textTheme.bodyMedium,
        iconTheme: IconThemeData(color: textColor),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 8,
        shadowColor: isDark ? Colors.black45 : const Color(0xFFB3C6FF).withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardSurface,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: subduedText.withOpacity(0.95)),
      ),
      dividerTheme: DividerThemeData(
        color: subduedText.withOpacity(0.22),
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        tileColor: cardSurface,
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        textColor: textColor,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: cardSurface.withOpacity(isDark ? 0.92 : 0.95),
        indicatorColor: colorScheme.primary.withOpacity(0.18),
        labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => textTheme.labelLarge?.copyWith(
            color: states.contains(MaterialState.selected) ? colorScheme.primary : subduedText,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: colorScheme.primary.withOpacity(0.12),
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelLarge?.copyWith(color: textColor),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: isDark ? const Color(0xFF121C33) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        labelStyle: TextStyle(color: subduedText),
        hintStyle: TextStyle(color: subduedText.withOpacity(0.8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.tertiary,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1D4ED8),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        indicator: BoxDecoration(
          borderRadius: buttonRadius,
          color: colorScheme.primary.withOpacity(0.12),
        ),
        labelStyle: textTheme.labelLarge,
        labelColor: colorScheme.primary,
        unselectedLabelColor: subduedText,
      ),
    );
  }

}
