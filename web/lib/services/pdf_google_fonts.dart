import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

/// Lightweight Google Fonts loader for the pdf widget library.
///
/// The upstream `PdfGoogleFonts` helper is currently unavailable in the
/// Flutter web toolchain we target.  This shim mirrors the subset of fonts
/// we rely on by streaming the font files directly from Google's CDN and
/// caching the resolved [pw.Font] instances for reuse.
class PdfGoogleFonts {
  PdfGoogleFonts._();

  static final Map<String, Future<pw.Font>> _cache = {};

  static Future<pw.Font> robotoRegular() =>
      _fromSources('robotoRegular', const [
        'https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Mu4mxM.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/apache/roboto/Roboto-Regular.ttf',
      ]);

  static Future<pw.Font> robotoBold() =>
      _fromSources('robotoBold', const [
        'https://fonts.gstatic.com/s/roboto/v30/KFOlCnqEu92Fr1MmWUlfBBc9.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/apache/roboto/Roboto-Bold.ttf',
      ]);

  static Future<pw.Font> robotoItalic() =>
      _fromSources('robotoItalic', const [
        'https://fonts.gstatic.com/s/roboto/v30/KFOkCnqEu92Fr1Mu51xFIzI.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/apache/roboto/Roboto-Italic.ttf',
      ]);

  static Future<pw.Font> robotoBoldItalic() =>
      _fromSources('robotoBoldItalic', const [
        'https://fonts.gstatic.com/s/roboto/v30/KFOjCnqEu92Fr1Mu51TzBhc9EsA.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/apache/roboto/Roboto-BoldItalic.ttf',
      ]);

  static Future<pw.Font> notoSansRegular() =>
      _fromSources('notoSansRegular', const [
        'https://fonts.gstatic.com/s/notosans/v36/o-0NIpQlx3QUlC5A4PNr4A.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/notosans/NotoSans-Regular.ttf',
      ]);

  static Future<pw.Font> notoSansJPRegular() =>
      _fromSources('notoSansJPRegular', const [
        'https://fonts.gstatic.com/s/notosansjp/v58/-F61fjptAgt5VM-kVkqdyU8n5K0.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/notosansjp/NotoSansJP-Regular.ttf',
      ]);

  static Future<pw.Font> _fromSources(String key, List<String> sources) {
    return _cache.putIfAbsent(key, () async {
      final errors = <String>[];
      for (final url in sources) {
        try {
          final font = await _fromUrl(url);
          return font;
        } catch (error) {
          errors.add('$url → $error');
        }
      }
      throw Exception('Unable to load font "$key". Attempts: ${errors.join('; ')}');
    });
  }

  static Future<pw.Font> _fromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('status ${response.statusCode}');
    }
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw Exception('empty response');
    }
    final data = ByteData.sublistView(bytes);
    return pw.Font.ttf(data);
  }
}
