class AppConfig {
  const AppConfig({
    required this.firebaseApiKey,
    required this.crispSubscriptionUrl,
    this.monthlyPlanPrice = 600,
    this.currencyCode = 'JPY',
    this.currencySymbol = '¥',
  });

  factory AppConfig.fromEnvironment() {
    const primaryKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
    const legacyKey = String.fromEnvironment('FIREBASE_APP_KEY', defaultValue: '');
    const webKey = String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: '');
    final resolvedFirebaseKey = primaryKey.isNotEmpty
        ? primaryKey
        : legacyKey.isNotEmpty
            ? legacyKey
            : webKey;

    return AppConfig(
      firebaseApiKey: resolvedFirebaseKey.isNotEmpty
          ? resolvedFirebaseKey
          : _defaultFirebaseApiKey,
      crispSubscriptionUrl:
          const String.fromEnvironment('CRISP_SUBSCRIPTION_URL', defaultValue: ''),
    );
  }

  final String firebaseApiKey;
  final String crispSubscriptionUrl;
  final double monthlyPlanPrice;
  final String currencyCode;
  final String currencySymbol;

  bool get hasFirebase => firebaseApiKey.isNotEmpty;
  bool get hasCrispSubscriptionLink => crispSubscriptionUrl.isNotEmpty;

  static const String _defaultFirebaseApiKey = 'AIzaSyC9yXs3QnOfRyLyN74QyilSfeKL-fVUxAQ';
}
