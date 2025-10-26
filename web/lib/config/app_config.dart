class AppConfig {
  const AppConfig({
    required this.firebaseApiKey,
    required this.crispSubscriptionUrl,
    this.monthlyPlanPrice = 600,
    this.currencyCode = 'JPY',
    this.currencySymbol = '¥',
    this.adminEmails = const [],
    this.firebaseProjectId = '',
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

    const projectIdEnv = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
    final projectId = projectIdEnv.isNotEmpty ? projectIdEnv : _defaultFirebaseProjectId;

    return AppConfig(
      firebaseApiKey: resolvedFirebaseKey.isNotEmpty
          ? resolvedFirebaseKey
          : _defaultFirebaseApiKey,
      crispSubscriptionUrl:
          const String.fromEnvironment('CRISP_SUBSCRIPTION_URL', defaultValue: ''),
      adminEmails: environmentAdmins.isNotEmpty
          ? environmentAdmins
          : const ['admin@example.com', 'haruto@example.com'],
      firebaseProjectId: projectId,
    );
  }

  final String firebaseApiKey;
  final String crispSubscriptionUrl;
  final double monthlyPlanPrice;
  final String currencyCode;
  final String currencySymbol;
  final List<String> adminEmails;
  final String firebaseProjectId;

  bool get hasFirebase => firebaseApiKey.isNotEmpty;
  bool get hasCrispSubscriptionLink => crispSubscriptionUrl.isNotEmpty;

  static const String _defaultFirebaseApiKey = 'AIzaSyC9yXs3QnOfRyLyN74QyilSfeKL-fVUxAQ';
  static const String _defaultFirebaseProjectId = 'invoice-receipt-generator-g7';
}
