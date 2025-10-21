import 'package:flutter/material.dart';

enum AppLanguage { japanese, english }

extension AppLanguageX on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.japanese:
        return const Locale('ja', 'JP');
      case AppLanguage.english:
        return const Locale('en', 'US');
    }
  }

  String get currencyLocale {
    switch (this) {
      case AppLanguage.japanese:
        return 'ja_JP';
      case AppLanguage.english:
        return 'en_US';
    }
  }
}
