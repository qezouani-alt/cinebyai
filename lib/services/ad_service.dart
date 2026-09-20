import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_load_controller.dart';

/// A single, guarded owner for every AdMob ad in the app.
///
/// Each format has at most one request in flight. Failed requests use bounded
/// retries and a later cooldown retry, so an intermittent network failure does
/// not leave the app permanently without ads or create duplicate requests.
class AdService {
  static final AdService _instance = AdService._internal();
  static const _nativeAdFactoryId = 'newmovieNativeAd';
  factory AdService() => _instance;
  AdService._internal();

  static const int maxFailedLoadAttempts = 3;
  static const _appOpenMaxAge = Duration(hours: 4);
  static const _minimumForegroundAppOpenInterval = Duration(seconds: 30);
  static const _portraitTransitionDelay = Duration(milliseconds: 150);
  static const _adDisplayChannel = MethodChannel('newmovie/ad_display');
  static Future<void>? _initializationFuture;

  bool _isShowingAnyAd = false;
  int _lifecycle = 0;
  void Function()? _cancelPresentation;
  StreamSubscription<AppState>? _appStateSubscription;
  DateTime? _lastAppOpenPresentation;
  bool _skipNextForegroundAppOpen = false;

  late final _interstitial = _loader<InterstitialAd>(
    'interstitial',
    (loaded, failed, _) => InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: loaded,
        onAdFailedToLoad: failed,
      ),
    ),
  );
  late final _rewarded = _loader<RewardedAd>(
    'rewarded',
    (loaded, failed, _) => RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded,
        onAdFailedToLoad: failed,
      ),
    ),
  );
  late final _appOpen = _loader<AppOpenAd>(
    'app-open',
    (loaded, failed, _) => AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: loaded,
        onAdFailedToLoad: failed,
      ),
    ),
  );
  late final _native = _loader<NativeAd>('native', (
    loaded,
    failed,
    trackPending,
  ) {
    final ad = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      // This factory supplies a 180-point MediaView on iOS. AdMob requires
      // video media views to be at least 120 by 120 points.
      factoryId: _nativeAdFactoryId,
      listener: NativeAdListener(
        onAdLoaded: (ad) => loaded(ad as NativeAd),
        onAdFailedToLoad: (_, error) => failed(error),
      ),
    );
    trackPending(ad);
    return ad.load();
  });

  // Production iOS ad units.

  static String interstitialAdUnitIdFor(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return 'ca-app-pub-9283129936552011/1934121040';
    }
    throw UnsupportedError('This app supports iOS ads only.');
  }

  static String rewardedAdUnitIdFor(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return 'ca-app-pub-9283129936552011/2658368135';
    }
    throw UnsupportedError('This app supports iOS ads only.');
  }

  static String appOpenAdUnitIdFor(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return 'ca-app-pub-9283129936552011/9621039375';
    }
    throw UnsupportedError('This app supports iOS ads only.');
  }

  static String nativeAdUnitIdFor(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return 'ca-app-pub-9283129936552011/3365410769';
    }
    throw UnsupportedError('This app supports iOS ads only.');
  }

  static String get interstitialAdUnitId =>
      interstitialAdUnitIdFor(defaultTargetPlatform);
  static String get rewardedAdUnitId =>
      rewardedAdUnitIdFor(defaultTargetPlatform);
  static String get appOpenAdUnitId =>
      appOpenAdUnitIdFor(defaultTargetPlatform);
  static String get nativeAdUnitId => nativeAdUnitIdFor(defaultTargetPlatform);

  static Future<void> initialize() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return Future.value();
    }
    return _initializationFuture ??= _initializeSdk();
  }

  static Future<void> _initializeSdk() async {
    try {
      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      // A transient SDK/platform failure must not poison every future request.
      _initializationFuture = null;
      rethrow;
    }
  }

  bool get _canLoadAds =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _log(Object message) {
    if (kDebugMode) debugPrint(message.toString());
  }

  AdLoadController<T> _loader<T extends Ad>(
    String format,
    Future<void> Function(
      void Function(T),
      void Function(Object),
      void Function(T),
    )
    request,
  ) => AdLoadController<T>(
    initialize: initialize,
    request: request,
    disposeAd: (ad) => ad.dispose(),
    isPermanentError: _isPermanentLoadError,
    onError: (error) {
      if (error is LoadAdError) {
        _log('$format ad failed to load: ${error.message} (${error.code}).');
      } else {
        _log('$format ad failed to load: $error');
      }
    },
    maxAttempts: maxFailedLoadAttempts,
  );

  bool _isPermanentLoadError(Object error) {
    if (error is! LoadAdError) return false;
    final message = error.message.toLowerCase();
    return message.contains("doesn't match format") ||
        message.contains('does not match format') ||
        message.contains('invalid ad unit');
  }

  Future<bool> loadInterstitialAd() {
    if (!_canLoadAds || interstitialAdUnitId.isEmpty) {
      return Future.value(false);
    }
    return _interstitial.load();
  }

  Future<bool> loadRewardedAd() {
    if (!_canLoadAds || rewardedAdUnitId.isEmpty) return Future.value(false);
    return _rewarded.load();
  }

  Future<bool> loadAppOpenAd() {
    if (!_canLoadAds || appOpenAdUnitId.isEmpty) return Future.value(false);
    _discardExpiredAppOpenAd();
    return _appOpen.load();
  }

  Future<bool> loadNativeAd() {
    if (!_canLoadAds || nativeAdUnitId.isEmpty) return Future.value(false);
    return _native.load();
  }

  /// Transfers exclusive ownership to a single placement. The caller disposes it.
  Future<NativeAd?> acquireNativeAd() async {
    if (!_canLoadAds) return null;
    while (await loadNativeAd()) {
      final ad = _native.take();
      if (ad != null) return ad;
      // Another placement claimed the shared preload while we were awaiting it.
    }
    return null;
  }

  bool get isNativeAdReady => _native.ad != null;
  bool get isRewardedAdReady => _rewarded.ad != null;

  void _discardExpiredAppOpenAd() {
    final loadedAt = _appOpen.loadedAt;
    if (loadedAt != null &&
        DateTime.now().difference(loadedAt) >= _appOpenMaxAge) {
      _appOpen.dispose();
    }
  }

  bool get isAppOpenAdReady {
    _discardExpiredAppOpenAd();
    return _appOpen.ad != null && !_isShowingAnyAd;
  }

  /// Handles App Open ads after the user returns to a visible app. The first
  /// launch ad is handled by SplashScreen while its loading UI is still shown.
  void startAppOpenForegroundListener() {
    if (!_canLoadAds || _appStateSubscription != null) return;

    AppStateEventNotifier.startListening();
    _appStateSubscription = AppStateEventNotifier.appStateStream.listen((
      state,
    ) {
      if (state != AppState.foreground || _isShowingAnyAd) return;
      if (_skipNextForegroundAppOpen) {
        // Returning from an advertiser must not immediately present another
        // App Open ad. Keep one cached for a later foreground instead.
        _skipNextForegroundAppOpen = false;
        unawaited(loadAppOpenAd());
        return;
      }
      final lastPresentation = _lastAppOpenPresentation;
      if (lastPresentation != null &&
          DateTime.now().difference(lastPresentation) <
              _minimumForegroundAppOpenInterval) {
        return;
      }
      unawaited(showAppOpenAd());
    }, onError: (Object error) => _log('App state listener error: $error'));
  }

  /// Full-screen Google ads are native view controllers.  If an ad is shown
  /// immediately after the player was in landscape, iOS can present it using
  /// the old landscape geometry, even though Flutter has returned to portrait.
  /// Restore and settle the interface orientation before every presentation.
  Future<void> _preparePortraitAdPresentation() async {
    if (!_canLoadAds) return;

    try {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // On iOS 16+, request a scene geometry update as well. This closes the
      // gap between Flutter's orientation request and a native ad overlay.
      await _adDisplayChannel
          .invokeMethod<void>('preparePortrait')
          .timeout(const Duration(milliseconds: 500), onTimeout: () {});
      await Future<void>.delayed(_portraitTransitionDelay);
    } catch (error) {
      // The system orientation request is best-effort. An ad failure must not
      // block the navigation that requested it.
      _log('Unable to prepare portrait ad presentation: $error');
    }
  }

  /// Completes only once the fullscreen content is dismissed or fails to show.
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (_isShowingAnyAd) {
      onAdClosed?.call();
      return;
    }

    final lifecycle = _lifecycle;
    if (_interstitial.ad == null) {
      // If not yet cached, attempt to load with a short bounded timeout
      // so the user does not wait indefinitely, but still gets to view the ad.
      await loadInterstitialAd().timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
    }

    if (_isShowingAnyAd || lifecycle != _lifecycle) {
      onAdClosed?.call();
      return;
    }

    final ad = _interstitial.take();
    if (ad != null) {
      await _preparePortraitAdPresentation();
      if (_isShowingAnyAd || lifecycle != _lifecycle) {
        unawaited(ad.dispose());
      } else {
        await _presentAd<InterstitialAd>(
          ad,
          setCallbacks: (callback) => ad.fullScreenContentCallback = callback,
          show: (_) => ad.show(),
          reload: loadInterstitialAd,
        );
      }
    }
    onAdClosed?.call();
  }

  Future<bool> showRewardedAd() async {
    if (_isShowingAnyAd) return false;
    final lifecycle = _lifecycle;
    if (_rewarded.ad == null && !await loadRewardedAd()) return false;
    // Another format may have started while the rewarded request was awaiting.
    if (_isShowingAnyAd || lifecycle != _lifecycle) return false;
    final ad = _rewarded.take();
    if (ad == null) return false;
    await _preparePortraitAdPresentation();
    if (_isShowingAnyAd || lifecycle != _lifecycle) {
      unawaited(ad.dispose());
      return false;
    }
    return _presentAd<RewardedAd>(
      ad,
      setCallbacks: (callback) => ad.fullScreenContentCallback = callback,
      show: (earned) => ad.show(onUserEarnedReward: (_, _) => earned()),
      reload: loadRewardedAd,
    );
  }

  Future<void> showAppOpenAd() async {
    if (_isShowingAnyAd) return;
    if (!isAppOpenAdReady) {
      // An App Open ad should be cached before it is needed. Do not freeze an
      // already-visible screen while waiting for a network response.
      unawaited(loadAppOpenAd());
      return;
    }
    final lifecycle = _lifecycle;
    final ad = _appOpen.take();
    if (ad == null) return;
    await _preparePortraitAdPresentation();
    if (_isShowingAnyAd || lifecycle != _lifecycle) {
      unawaited(ad.dispose());
      return;
    }
    await _presentAd<AppOpenAd>(
      ad,
      setCallbacks: (callback) => ad.fullScreenContentCallback = callback,
      show: (_) => ad.show(),
      reload: loadAppOpenAd,
    );
  }

  Future<bool> _presentAd<T extends Ad>(
    T ad, {
    required void Function(FullScreenContentCallback<T>) setCallbacks,
    required Future<void> Function(VoidCallback earned) show,
    required Future<bool> Function() reload,
  }) {
    _isShowingAnyAd = true;
    if (ad is AppOpenAd) _lastAppOpenPresentation = DateTime.now();
    final closed = Completer<bool>();
    var finished = false;
    var rewardEarned = false;
    Timer? startTimeout;
    void finish({bool failed = false, bool replenish = true}) {
      if (finished) return;
      finished = true;
      startTimeout?.cancel();
      _cancelPresentation = null;
      _isShowingAnyAd = false;
      unawaited(ad.dispose().catchError((Object error) => _log(error)));
      closed.complete(!failed && rewardEarned);
      if (replenish) unawaited(reload());
    }

    _cancelPresentation = () => finish(failed: true, replenish: false);
    setCallbacks(
      FullScreenContentCallback<T>(
        onAdShowedFullScreenContent: (_) {
          startTimeout?.cancel();
          _log('${ad.runtimeType} showed full-screen content.');
        },
        onAdImpression: (_) =>
            _log('${ad.runtimeType} recorded an impression.'),
        onAdClicked: (_) {
          _log('${ad.runtimeType} was clicked.');
          if (ad is AppOpenAd) _skipNextForegroundAppOpen = true;
        },
        onAdDismissedFullScreenContent: (_) => finish(),
        onAdFailedToShowFullScreenContent: (_, error) {
          _log('Ad failed to show: ${error.message}.');
          finish(failed: true);
        },
      ),
    );
    // Bound a missing native show response. Once shown, respect the SDK's
    // dismissal callback rather than navigating underneath a visible ad.
    startTimeout = Timer(const Duration(seconds: 10), () {
      _log('Ad presentation did not start.');
      finish(failed: true);
    });
    unawaited(
      Future<void>.sync(
        () => show(() {
          if (!finished) rewardEarned = true;
        }),
      ).catchError((Object error) {
        _log('Ad show error: $error');
        finish(failed: true);
      }),
    );
    return closed.future;
  }

  void disposeNativeAd() => _native.dispose();

  void dispose() {
    ++_lifecycle;
    _cancelPresentation?.call();
    _appStateSubscription?.cancel();
    _appStateSubscription = null;
    _interstitial.dispose();
    _rewarded.dispose();
    _appOpen.dispose();
    _native.dispose();
  }
}
