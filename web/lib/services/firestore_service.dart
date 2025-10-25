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

  Future<Map<String, dynamic>?> fetchUserState({
    required String uid,
    required String idToken,
  }) async {
    if (!canQuery || uid.isEmpty || idToken.isEmpty) {
      return null;
    }

    try {
      final results = await Future.wait<Map<String, dynamic>?>([
        _fetchFields('userDetails/$uid', idToken),
        _fetchFields('userInvoices/$uid', idToken),
        _fetchFields('userSubscriptions/$uid', idToken),
      ]);

      final detailsFields = results[0];
      final invoiceFields = results[1];
      final subscriptionFields = results[2];

      final payload = <String, dynamic>{};

      if (detailsFields != null) {
        final profileJson = _stringValue(detailsFields['profile']);
        if (profileJson != null && profileJson.isNotEmpty) {
          final decodedProfile = _decodeJsonMap(profileJson);
          if (decodedProfile != null) {
            payload['profile'] = decodedProfile;
          }
        }
        final locale = _stringValue(detailsFields['locale']);
        if (locale != null && locale.isNotEmpty) {
          payload['locale'] = locale;
        }
        final isPremium = _boolValue(detailsFields['isPremium']);
        if (isPremium != null) {
          payload['isPremium'] = isPremium;
        }
        final selectedInvoice = _stringValue(detailsFields['selectedInvoiceId']);
        if (selectedInvoice != null && selectedInvoice.isNotEmpty) {
          payload['selectedInvoiceId'] = selectedInvoice;
        }
      }

      if (invoiceFields != null) {
        final invoiceJson = _stringValue(invoiceFields['items']);
        if (invoiceJson != null && invoiceJson.isNotEmpty) {
          final decodedInvoices = _decodeJsonList(invoiceJson);
          if (decodedInvoices != null) {
            payload['invoices'] = decodedInvoices;
          }
        }
      }

      if (subscriptionFields != null) {
        final accountsJson = _stringValue(subscriptionFields['accounts']);
        if (accountsJson != null && accountsJson.isNotEmpty) {
          final decodedAccounts = _decodeJsonList(accountsJson);
          if (decodedAccounts != null) {
            payload['accounts'] = decodedAccounts;
          }
        }
        final activityJson = _stringValue(subscriptionFields['activityLog']);
        if (activityJson != null && activityJson.isNotEmpty) {
          final decodedActivity = _decodeJsonList(activityJson);
          if (decodedActivity != null) {
            payload['activityLog'] = decodedActivity;
          }
        }
      }

      if (payload.isEmpty) {
        return null;
      }
      return payload;
    } catch (_) {
      // Ignore fetch errors to keep flows responsive.
    }
    return null;
  }

  Future<void> saveUserState({
    required String uid,
    required String idToken,
    required Map<String, dynamic> data,
  }) async {
    if (!canQuery || uid.isEmpty || idToken.isEmpty) {
      return;
    }

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final profileJson = jsonEncode(data['profile'] ?? const {});
      final invoicesJson = jsonEncode(data['invoices'] ?? const []);
      final accountsJson = jsonEncode(data['accounts'] ?? const []);
      final activityJson = jsonEncode(data['activityLog'] ?? const []);
      final locale = data['locale'] as String? ?? 'en';
      final isPremium = data['isPremium'] as bool? ?? false;
      final selectedInvoice = data.containsKey('selectedInvoiceId')
          ? data['selectedInvoiceId'] as String?
          : null;

      await Future.wait([
        _patchDocument(
          path: 'userDetails/$uid',
          idToken: idToken,
          fields: {
            'profile': _stringField(profileJson),
            'locale': _stringField(locale),
            'isPremium': _boolField(isPremium),
            'selectedInvoiceId': selectedInvoice != null && selectedInvoice.isNotEmpty
                ? _stringField(selectedInvoice)
                : _nullField(),
            'updatedAt': _timestampField(now),
          },
        ),
        _patchDocument(
          path: 'userInvoices/$uid',
          idToken: idToken,
          fields: {
            'items': _stringField(invoicesJson),
            'updatedAt': _timestampField(now),
          },
        ),
        _patchDocument(
          path: 'userSubscriptions/$uid',
          idToken: idToken,
          fields: {
            'accounts': _stringField(accountsJson),
            'activityLog': _stringField(activityJson),
            'updatedAt': _timestampField(now),
          },
        ),
      ]);
    } catch (_) {
      // Ignore persistence errors to avoid disrupting the UX.
    }
  }

  Future<Map<String, dynamic>?> _fetchFields(String path, String idToken) async {
    final document = await _fetchDocument(path, idToken);
    if (document == null) {
      return null;
    }
    final fields = document['fields'];
    if (fields is Map<String, dynamic>) {
      return fields;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchDocument(String path, String idToken) async {
    final url = _documentUrl(path);
    try {
      final request = await html.HttpRequest.request(
        url,
        method: 'GET',
        requestHeaders: {
          'Authorization': 'Bearer $idToken',
        },
      );
      return _decode(request.responseText);
    } on html.ProgressEvent catch (event) {
      final target = event.target;
      if (target is html.HttpRequest) {
        if (target.status == 404) {
          return null;
        }
        return _decode(target.responseText);
      }
    } catch (_) {
      // Ignore transient network errors.
    }
    return null;
  }

  Future<void> _patchDocument({
    required String path,
    required String idToken,
    required Map<String, Map<String, dynamic>> fields,
  }) async {
    final payload = {
      'name': _documentName(path),
      'fields': fields,
    };

    await html.HttpRequest.request(
      _documentUrl(path),
      method: 'PATCH',
      sendData: jsonEncode(payload),
      requestHeaders: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );
  }

  Map<String, dynamic> _decode(String? body) {
    if (body == null || body.isEmpty) {
      return const {};
    }
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

  Map<String, dynamic>? _decodeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<dynamic>? _decodeJsonList(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic> _stringField(String value) => {'stringValue': value};

  Map<String, dynamic> _boolField(bool value) => {'booleanValue': value};

  Map<String, dynamic> _nullField() => {'nullValue': null};

  Map<String, dynamic> _timestampField(String isoString) => {'timestampValue': isoString};

  String? _stringValue(dynamic field) {
    if (field is Map<String, dynamic>) {
      final value = field['stringValue'];
      if (value is String) {
        return value;
      }
    }
    return null;
  }

  bool? _boolValue(dynamic field) {
    if (field is Map<String, dynamic>) {
      final value = field['booleanValue'];
      if (value is bool) {
        return value;
      }
    }
    return null;
  }

  String _documentUrl(String path) =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$path?key=$apiKey';

  String _documentName(String path) =>
      'projects/$projectId/databases/(default)/documents/$path';
}
