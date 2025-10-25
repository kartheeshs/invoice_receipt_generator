
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'pages/home_shell.dart';
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
            home: const HomeShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.dark)
        : ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF111214) : const Color(0xFFF5F5F7),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        backgroundColor: colorScheme.surface,
        labelTextStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
