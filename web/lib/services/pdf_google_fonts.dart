import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Lightweight Google Fonts loader for the pdf widget library that relies on
/// the typefaces bundled with the Flutter SDK itself.
///
/// The upstream helper exposed by `package:pdf` is not available when
/// targeting Flutter web in this project.  Instead of reaching out to the
/// public Google Fonts CDN (which fails behind restricted corporate proxies),
/// we resolve the Roboto and Noto Sans families directly from
/// `packages/flutter/fonts`.  These fonts ship with every Flutter release, so
/// they are guaranteed to be available offline on developer machines and in
/// production hosting environments.
class PdfGoogleFonts {
  PdfGoogleFonts._();

  static final Map<String, Future<pw.Font>> _requiredCache = {};
  static final Map<String, Future<pw.Font?>> _optionalCache = {};

  static Future<pw.Font> robotoRegular() =>
      _loadRequired('robotoRegular', const ['packages/flutter/fonts/Roboto-Regular.ttf']);

  static Future<pw.Font> robotoBold() =>
      _loadRequired('robotoBold', const ['packages/flutter/fonts/Roboto-Bold.ttf']);

  static Future<pw.Font> robotoItalic() =>
      _loadRequired('robotoItalic', const ['packages/flutter/fonts/Roboto-Italic.ttf']);

  static Future<pw.Font> robotoBoldItalic() => _loadRequired(
        'robotoBoldItalic',
        const ['packages/flutter/fonts/Roboto-BoldItalic.ttf'],
      );

  static Future<pw.Font?> notoSansRegular() => _loadOptional(
        'notoSansRegular',
        const [
          'packages/flutter/fonts/NotoSans-Regular.ttf',
          'packages/flutter/fonts/NotoSans-Regular.otf',
        ],
      );

  static Future<pw.Font?> notoSansJPRegular() => _loadOptional(
        'notoSansJPRegular',
        const [
          'packages/flutter/fonts/NotoSansJP-Regular.otf',
          'packages/flutter/fonts/NotoSansJP-Regular.ttf',
        ],
      );

  static Future<pw.Font> _loadRequired(String key, List<String> assets) {
    return _requiredCache.putIfAbsent(key, () async {
      final errors = <String>[];
      for (final asset in assets) {
        try {
          final data = await rootBundle.load(asset);
          return pw.Font.ttf(data);
        } catch (error) {
          errors.add('$asset → $error');
        }
      }
      throw FlutterError('Unable to load font "$key". Attempts: ${errors.join('; ')}');
    });
  }

  static Future<pw.Font?> _loadOptional(String key, List<String> assets) {
    return _optionalCache.putIfAbsent(key, () async {
      for (final asset in assets) {
        try {
          final data = await rootBundle.load(asset);
          return pw.Font.ttf(data);
        } catch (_) {
          // Ignore missing assets. We will fall back to the core Roboto bundle
          // below so the PDF render still succeeds.
        }
      }
      return null;
    });
  }
}
