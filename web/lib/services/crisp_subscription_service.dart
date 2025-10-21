import 'package:url_launcher/url_launcher.dart';

class CrispConfigurationException implements Exception {
  const CrispConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'CrispConfigurationException: $message';
}

class CrispCheckoutException implements Exception {
  const CrispCheckoutException(this.message);

  final String message;

  @override
  String toString() => 'CrispCheckoutException: $message';
}

class CrispSubscriptionService {
  static const _configLink = String.fromEnvironment('CRISP_SUBSCRIPTION_LINK');

  Future<void> startCheckout({required String email}) async {
    if (_configLink.isEmpty) {
      throw const CrispConfigurationException(
        'CRISP_SUBSCRIPTION_LINK is not configured. Provide the Crisp Pay link for the 600 JPY/month plan.',
      );
    }

    final uri = Uri.parse(_configLink);
    final query = Map<String, String>.from(uri.queryParameters);
    if (email.isNotEmpty && !query.containsKey('email')) {
      query['email'] = email;
    }

    final checkoutUrl = uri.replace(queryParameters: query.isEmpty ? null : query);
    final launched = await launchUrl(
      checkoutUrl,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!launched) {
      throw const CrispCheckoutException('Unable to open Crisp checkout link.');
    }
  }
}
