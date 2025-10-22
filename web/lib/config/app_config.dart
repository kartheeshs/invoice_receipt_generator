class AppConfig {
  const AppConfig({
    required this.firebaseApiKey,
    required this.crispSubscriptionUrl,
    this.monthlyPlanPrice = 600,
    this.currencyCode = 'JPY',
    this.currencySymbol = '¥',
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      firebaseApiKey: const String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
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
}
