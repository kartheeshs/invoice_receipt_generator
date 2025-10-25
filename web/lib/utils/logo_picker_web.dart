import 'dart:async';
import 'dart:html' as html;

Future<String?> pickLogoDataUrl() {
  final completer = Completer<String?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onLoadEnd.listen((event) {
      if (!completer.isCompleted) {
        final result = reader.result;
        completer.complete(result is String ? result : null);
      }
    });

    reader.onError.listen((event) {
      if (!completer.isCompleted) {
        completer.completeError(event ?? 'logo-read-error');
      }
    });

    reader.readAsDataUrl(file);
  });

  uploadInput.onError.listen((event) {
    if (!completer.isCompleted) {
      completer.completeError(event ?? 'logo-upload-error');
    }
  });

  uploadInput.click();

  return completer.future;
}
