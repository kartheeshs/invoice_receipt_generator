// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

class FirestoreService {
  FirestoreService({
    required this.projectId,
    required this.apiKey,
  });

  final String projectId;
  final String apiKey;

  bool get canQuery => projectId.isNotEmpty && apiKey.isNotEmpty;

  Future<String?> fetchUserRole({
    required String uid,
    required String idToken,
  }) async {
    if (!canQuery || uid.isEmpty || idToken.isEmpty) {
      return null;
    }

    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid?mask.fieldPaths=role&key=$apiKey';
    try {
      final request = await html.HttpRequest.request(
        url,
        method: 'GET',
        requestHeaders: {
          'Authorization': 'Bearer $idToken',
        },
      );
      return _parseRole(request.responseText);
    } on html.ProgressEvent catch (event) {
      final target = event.target;
      if (target is html.HttpRequest) {
        final message = target.responseText;
        if (message != null && message.isNotEmpty) {
          final role = _parseRole(message);
          if (role != null) {
            return role;
          }
          final decoded = _decode(message);
          final error = decoded['error'];
          if (error is Map<String, dynamic>) {
            final status = error['status'] as String?;
            if (status == 'NOT_FOUND') {
              return null;
            }
          }
        }
      }
    } catch (_) {
      // Ignore network errors to avoid blocking auth flows.
    }
    return null;
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed responses.
    }
    return const {};
  }

  String? _parseRole(String? body) {
    if (body == null || body.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final fields = decoded['fields'];
      if (fields is! Map<String, dynamic>) {
        return null;
      }
      final roleField = fields['role'];
      if (roleField is Map<String, dynamic>) {
        final value = roleField['stringValue'];
        if (value is String && value.isNotEmpty) {
          return value.toLowerCase();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
