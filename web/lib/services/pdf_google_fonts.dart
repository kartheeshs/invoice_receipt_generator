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

  static Future<pw.Font> robotoRegular() => _fromUrl(
        'https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Mu4mxP.ttf',
      );

  static Future<pw.Font> robotoBold() => _fromUrl(
        'https://fonts.gstatic.com/s/roboto/v30/KFOlCnqEu92Fr1MmWUlfBBc4.ttf',
      );

  static Future<pw.Font> robotoItalic() => _fromUrl(
        'https://fonts.gstatic.com/s/roboto/v30/KFOkCnqEu92Fr1Mu51xIIzc.ttf',
      );

  static Future<pw.Font> robotoBoldItalic() => _fromUrl(
        'https://fonts.gstatic.com/s/roboto/v30/KFOjCnqEu92Fr1Mu51TzBhc4EsA.ttf',
      );

  static Future<pw.Font> notoSansRegular() => _fromUrl(
        'https://fonts.gstatic.com/s/notosans/v36/o-0NIpQlx3QUlC5A4PNr6A.ttf',
      );

  static Future<pw.Font> notoSansJPRegular() => _fromUrl(
        'https://fonts.gstatic.com/s/notosansjp/v58/-F61fjptAgt5VM-kVkqdyU8n5LI.ttf',
      );

  static Future<pw.Font> _fromUrl(String url) {
    return _cache.putIfAbsent(url, () async {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load font "$url" (${response.statusCode}).');
      }
      final bytes = response.bodyBytes;
      final data = ByteData.sublistView(bytes);
      return pw.Font.ttf(data);
    });
  }
}
