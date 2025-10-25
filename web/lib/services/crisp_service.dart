// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CrispService {
  CrispService(this.subscriptionUrl);

  final String subscriptionUrl;

  bool get hasSubscription => subscriptionUrl.isNotEmpty;

  void openSubscription() {
    if (subscriptionUrl.isEmpty) {
      return;
    }
    html.window.open(subscriptionUrl, '_blank');
  }
}
