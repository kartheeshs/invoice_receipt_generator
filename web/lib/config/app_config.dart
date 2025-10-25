class AppConfig {
  const AppConfig({
    required this.firebaseApiKey,
    required this.crispSubscriptionUrl,
    this.monthlyPlanPrice = 600,
    this.currencyCode = 'JPY',
    this.currencySymbol = '¥',
    this.adminEmails = const [],
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

    final adminEmailsRaw = const String.fromEnvironment('ADMIN_EMAILS', defaultValue: '');
    final environmentAdmins = adminEmailsRaw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return AppConfig(
      firebaseApiKey: resolvedFirebaseKey.isNotEmpty
          ? resolvedFirebaseKey
          : _defaultFirebaseApiKey,
      crispSubscriptionUrl:
          const String.fromEnvironment('CRISP_SUBSCRIPTION_URL', defaultValue: ''),
      adminEmails: environmentAdmins.isNotEmpty
          ? environmentAdmins
          : const ['admin@example.com', 'haruto@example.com'],
    );
  }

  final String firebaseApiKey;
  final String crispSubscriptionUrl;
  final double monthlyPlanPrice;
  final String currencyCode;
  final String currencySymbol;
  final List<String> adminEmails;

  bool get hasFirebase => firebaseApiKey.isNotEmpty;
  bool get hasCrispSubscriptionLink => crispSubscriptionUrl.isNotEmpty;

  static const String _defaultFirebaseApiKey = 'AIzaSyC9yXs3QnOfRyLyN74QyilSfeKL-fVUxAQ';
}
