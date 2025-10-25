import 'package:firebase_core/firebase_core.dart';

import 'config/app_config.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    final config = AppConfig.fromEnvironment();

    const appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
    const messagingSenderId =
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
    const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
    const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
    const measurementId =
        String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: '');

    final apiKey = config.firebaseApiKey;

    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty || messagingSenderId.isEmpty) {
      throw StateError(
        'Missing Firebase configuration. Provide FIREBASE_API_KEY, FIREBASE_APP_ID, '
        'FIREBASE_PROJECT_ID, and FIREBASE_MESSAGING_SENDER_ID via --dart-define.',
      );
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: _nullable(authDomain),
      storageBucket: _nullable(storageBucket),
      measurementId: _nullable(measurementId),
    );
  }

  static String? _nullable(String value) => value.isEmpty ? null : value;
}
