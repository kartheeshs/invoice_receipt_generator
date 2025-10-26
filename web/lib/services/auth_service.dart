// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.idToken,
    required this.refreshToken,
    this.displayName,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      idToken: json['idToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      displayName: json['displayName'] as String?,
    );
  }

  AuthUser copyWith({
    String? displayName,
    String? idToken,
    String? refreshToken,
  }) {
    return AuthUser(
      uid: uid,
      email: email,
      idToken: idToken ?? this.idToken,
      refreshToken: refreshToken ?? this.refreshToken,
      displayName: displayName ?? this.displayName,
    );
  }

  final String uid;
  final String email;
  final String idToken;
  final String refreshToken;
  final String? displayName;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'idToken': idToken,
      'refreshToken': refreshToken,
      if (displayName != null) 'displayName': displayName,
    };
  }
}

class FirebaseAuthException implements Exception {
  const FirebaseAuthException(this.message);

  final String message;

  @override
  String toString() => 'FirebaseAuthException: $message';
}

class FirebaseAuthService {
  FirebaseAuthService({required this.apiKey});

  final String apiKey;

  String get _baseUrl => 'https://identitytoolkit.googleapis.com/v1';

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      path: 'accounts:signInWithPassword',
      body: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
    return _userFromResponse(response);
  }

  Future<AuthUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _post(
      path: 'accounts:signUp',
      body: {
        'displayName': displayName,
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );
    final user = _userFromResponse(response).copyWith(displayName: displayName);
    if (displayName.isNotEmpty) {
      await updateProfile(idToken: user.idToken, displayName: displayName);
    }
    return user;
  }

  Future<void> updateProfile({
    required String idToken,
    String? displayName,
  }) async {
    await _post(
      path: 'accounts:update',
      body: {
        'idToken': idToken,
        if (displayName != null) 'displayName': displayName,
        'returnSecureToken': true,
      },
    );
  }

  Future<void> sendPasswordReset({required String email}) async {
    await _post(
      path: 'accounts:sendOobCode',
      body: {
        'requestType': 'PASSWORD_RESET',
        'email': email,
      },
    );
  }

  Future<AuthUser> refreshUser(AuthUser user) async {
    final response = await _post(
      path: 'accounts:lookup',
      body: {
        'idToken': user.idToken,
      },
    );
    final users = response['users'];
    if (users is List && users.isNotEmpty) {
      final details = users.first as Map<String, dynamic>;
      return user.copyWith(displayName: details['displayName'] as String?);
    }
    return user;
  }

  Future<void> signOut() async {
    // Firebase Identity Toolkit does not expose a dedicated sign-out endpoint
    // for password-based web clients. The caller is responsible for discarding
    // cached credentials, so this method simply completes to keep the
    // interface uniform across platforms.
    return Future<void>.value();
  }

  Future<Map<String, dynamic>> _post({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    if (apiKey.isEmpty) {
      throw const FirebaseAuthException(
        'Firebase API key is missing. Provide FIREBASE_API_KEY via --dart-define.',
      );
    }

    final url = '$_baseUrl/$path?key=$apiKey';
    try {
      final request = await html.HttpRequest.request(
        url,
        method: 'POST',
        sendData: jsonEncode(body),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      return _decode(request.responseText);
    } on html.ProgressEvent catch (event) {
      final target = event.target;
      if (target is html.HttpRequest && target.responseText != null) {
        final data = _decode(target.responseText);
        final message = _mapFirebaseError(data);
        throw FirebaseAuthException(message);
      }
      throw const FirebaseAuthException('Unable to reach Firebase Auth service.');
    }
  }

  Map<String, dynamic> _decode(String? body) {
    if (body == null || body.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        throw FirebaseAuthException(_mapFirebaseError(decoded));
      }
      return decoded;
    }
    throw const FirebaseAuthException('Unexpected response from Firebase Auth.');
  }

  AuthUser _userFromResponse(Map<String, dynamic> response) {
    return AuthUser(
      uid: response['localId'] as String? ?? '',
      email: response['email'] as String? ?? '',
      idToken: response['idToken'] as String? ?? '',
      refreshToken: response['refreshToken'] as String? ?? '',
      displayName: response['displayName'] as String?,
    );
  }

  String _mapFirebaseError(Map<String, dynamic> response) {
    final error = response['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'] as String?;
      switch (message) {
        case 'EMAIL_EXISTS':
          return 'An account with this email already exists.';
        case 'OPERATION_NOT_ALLOWED':
          return 'Password sign-in is disabled for this project.';
        case 'TOO_MANY_ATTEMPTS_TRY_LATER':
          return 'Too many attempts. Try again later.';
        case 'EMAIL_NOT_FOUND':
        case 'INVALID_LOGIN_CREDENTIALS':
          return 'Invalid email or password.';
        case 'INVALID_PASSWORD':
          return 'Invalid email or password.';
        case 'USER_DISABLED':
          return 'This user account has been disabled.';
        default:
          if (message != null) {
            return message.replaceAll('_', ' ').toLowerCase();
          }
      }
    }
    return 'Authentication failed. Please try again.';
  }
}
