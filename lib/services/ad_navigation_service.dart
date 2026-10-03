import 'package:flutter/widgets.dart';

import 'ad_service.dart';

/// Presents an interstitial before page navigation.
///
/// A missing or unfilled ad never prevents the user from continuing. The
/// guard also prevents repeated taps from queuing duplicate page transitions.
class AdNavigationService {
  AdNavigationService._();

  static bool _isNavigating = false;

  static Future<void> pushAfterInterstitial(
    BuildContext context,
    Route<void> Function() routeBuilder,
  ) async {
    await runAfterInterstitial(context, () {
      Navigator.of(context).push<void>(routeBuilder());
    });
  }

  static Future<void> runAfterInterstitial(
    BuildContext context,
    VoidCallback action,
  ) async {
    if (_isNavigating || !context.mounted) return;

    _isNavigating = true;
    try {
      await AdService().showInterstitialAd();
      if (context.mounted) action();
    } finally {
      _isNavigating = false;
    }
  }
}
