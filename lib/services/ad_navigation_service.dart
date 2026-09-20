import 'package:flutter/widgets.dart';

import 'ad_service.dart';

/// Presents an interstitial before opening a selected title's detail page.
///
/// A missing or unfilled ad never prevents the user from continuing. The
/// guard also prevents repeated taps from queuing duplicate detail routes.
class AdNavigationService {
  AdNavigationService._();

  static bool _isNavigating = false;

  static Future<void> pushAfterInterstitial(
    BuildContext context,
    Route<void> Function() routeBuilder,
  ) async {
    if (_isNavigating || !context.mounted) return;

    _isNavigating = true;
    try {
      await AdService().showInterstitialAd();
      if (context.mounted) {
        Navigator.of(context).push<void>(routeBuilder());
      }
    } finally {
      _isNavigating = false;
    }
  }
}
