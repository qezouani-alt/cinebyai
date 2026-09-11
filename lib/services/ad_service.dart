import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A single, guarded owner for every AdMob ad in the app.
///
/// Each format has at most one request in flight. Failed requests use bounded
/// retries and a later cooldown retry, so an intermittent network failure does
/// not leave the app permanently without ads or create duplicate requests.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const int maxFailedLoadAttempts = 3;
  static const _appOpenMaxAge = Duration(hours: 4);
  static Future<void>? _initializationFuture;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;
  NativeAd? nativeAd;

  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  bool _isAppOpenLoading = false;
  bool _isNativeLoading = false;
  bool _isShowingAnyAd = false;
  bool _isShowingAppOpenAd = false;
  bool isNativeAdReady = false;

  int _interstitialLoadAttempts = 0;
  int _rewardedLoadAttempts = 0;
  int _appOpenLoadAttempts = 0;
  int _nativeLoadAttempts = 0;
  DateTime? _appOpenLoadedAt;

  Completer<bool>? _interstitialLoadCompleter;
  Completer<bool>? _rewardedLoadCompleter;
  Completer<bool>? _appOpenLoadCompleter;
  Completer<bool>? _nativeLoadCompleter;

  Timer? _interstitialRetryTimer;
  Timer? _rewardedRetryTimer;
  Timer? _appOpenRetryTimer;
  Timer? _nativeRetryTimer;

  // Release builds use the app's production IDs. The previous iOS rewarded
  // ID was a different ad format, so pass a genuine Rewarded ID at build time.
  static const _iosRewardedProductionId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
  );
  static const _androidInterstitialProductionId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
  );
  static const _androidRewardedProductionId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
  );
  static const _androidAppOpenProductionId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_OPEN_ID',
  );
  static const _androidNativeProductionId = String.fromEnvironment(
    'ADMOB_ANDROID_NATIVE_ID',
  );

  /// Development builds use Google's official format-specific test IDs.
  static String interstitialAdUnitIdFor(TargetPlatform platform) {
    if (kDebugMode) {
      return switch (platform) {
        TargetPlatform.android => 'ca-app-pub-3940256099942544/1033173712',
        TargetPlatform.iOS => 'ca-app-pub-3940256099942544/4411468910',
        _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
      };
    }
    return switch (platform) {
      TargetPlatform.iOS => 'ca-app-pub-9283129936552011/1934121040',
      TargetPlatform.android => _androidInterstitialProductionId,
      _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
    };
  }

  static String rewardedAdUnitIdFor(TargetPlatform platform) {
    if (kDebugMode) {
      return switch (platform) {
        TargetPlatform.android => 'ca-app-pub-3940256099942544/5224354917',
        TargetPlatform.iOS => 'ca-app-pub-3940256099942544/1712485313',
        _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
      };
    }
    return switch (platform) {
      TargetPlatform.iOS => _iosRewardedProductionId,
      TargetPlatform.android => _androidRewardedProductionId,
      _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
    };
  }

  static String appOpenAdUnitIdFor(TargetPlatform platform) {
    if (kDebugMode) {
      return switch (platform) {
        TargetPlatform.android => 'ca-app-pub-3940256099942544/9257395921',
        TargetPlatform.iOS => 'ca-app-pub-3940256099942544/5575463023',
        _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
      };
    }
    return switch (platform) {
      TargetPlatform.iOS => 'ca-app-pub-9283129936552011/9621039375',
      TargetPlatform.android => _androidAppOpenProductionId,
      _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
    };
  }

  static String nativeAdUnitIdFor(TargetPlatform platform) {
    if (kDebugMode) {
      return switch (platform) {
        TargetPlatform.android => 'ca-app-pub-3940256099942544/2247696110',
        TargetPlatform.iOS => 'ca-app-pub-3940256099942544/3986624511',
        _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
      };
    }
    return switch (platform) {
      TargetPlatform.iOS => 'ca-app-pub-9283129936552011/3365410769',
      TargetPlatform.android => _androidNativeProductionId,
      _ => throw UnsupportedError('AdMob supports Android and iOS only.'),
    };
  }

  static String get interstitialAdUnitId =>
      interstitialAdUnitIdFor(defaultTargetPlatform);
  static String get rewardedAdUnitId =>
      rewardedAdUnitIdFor(defaultTargetPlatform);
  static String get appOpenAdUnitId =>
      appOpenAdUnitIdFor(defaultTargetPlatform);
  static String get nativeAdUnitId => nativeAdUnitIdFor(defaultTargetPlatform);

  static Future<void> initialize() {
    return _initializationFuture ??= MobileAds.instance.initialize().then<void>(
      (_) {},
    );
  }

  bool get _canLoadAds {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
  }

  Duration _retryDelay(int attempt) =>
      Duration(seconds: 2 << (attempt - 1).clamp(0, 3));

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  bool _isPermanentFormatError(LoadAdError error) =>
      error.message.toLowerCase().contains("doesn't match format");

  Future<bool> loadInterstitialAd() async {
    if (!_canLoadAds || interstitialAdUnitId.isEmpty) return false;
    await initialize();
    if (_interstitialAd != null) return true;
    if (_isInterstitialLoading && _interstitialLoadCompleter != null) {
      return _interstitialLoadCompleter!.future;
    }
    _interstitialRetryTimer?.cancel();
    _interstitialLoadAttempts = 0;
    _isInterstitialLoading = true;
    _interstitialLoadCompleter = Completer<bool>();
    _loadInterstitialAttempt();
    return _interstitialLoadCompleter!.future;
  }

  void _loadInterstitialAttempt() {
    _log(
      'Loading interstitial ad (attempt ${_interstitialLoadAttempts + 1}/$maxFailedLoadAttempts)...',
    );
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          _isInterstitialLoading = false;
          _interstitialLoadCompleter?.complete(true);
          _interstitialLoadCompleter = null;
          _log('Interstitial ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _log('Interstitial ad failed: ${error.message} (${error.code}).');
          if (_interstitialLoadAttempts < maxFailedLoadAttempts) {
            Future<void>.delayed(_retryDelay(_interstitialLoadAttempts), () {
              if (_isInterstitialLoading) _loadInterstitialAttempt();
            });
            return;
          }
          _isInterstitialLoading = false;
          _interstitialLoadCompleter?.complete(false);
          _interstitialLoadCompleter = null;
          _interstitialRetryTimer = Timer(const Duration(seconds: 45), () {
            unawaited(loadInterstitialAd());
          });
        },
      ),
    );
  }

  /// Completes after the ad closes, allowing callers to navigate safely.
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    final ad = _interstitialAd;
    if (ad == null || _isShowingAnyAd) {
      unawaited(loadInterstitialAd());
      onAdClosed?.call();
      return;
    }
    _interstitialAd = null;
    _isShowingAnyAd = true;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _isShowingAnyAd = false;
        onAdClosed?.call();
        unawaited(loadInterstitialAd());
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        _log('Interstitial ad failed to show: ${error.message}.');
        shownAd.dispose();
        _isShowingAnyAd = false;
        onAdClosed?.call();
        unawaited(loadInterstitialAd());
        if (!closed.isCompleted) closed.complete();
      },
    );
    try {
      await ad.show();
      await closed.future;
    } catch (error) {
      _log('Interstitial show error: $error');
      ad.dispose();
      _isShowingAnyAd = false;
      onAdClosed?.call();
      unawaited(loadInterstitialAd());
    }
  }

  Future<bool> loadRewardedAd() async {
    if (!_canLoadAds || rewardedAdUnitId.isEmpty) {
      _log(
        'Rewarded ads are disabled until ADMOB_IOS_REWARDED_ID is configured for release.',
      );
      return false;
    }
    await initialize();
    if (_rewardedAd != null) return true;
    if (_isRewardedLoading && _rewardedLoadCompleter != null) {
      return _rewardedLoadCompleter!.future;
    }
    _rewardedRetryTimer?.cancel();
    _rewardedLoadAttempts = 0;
    _isRewardedLoading = true;
    _rewardedLoadCompleter = Completer<bool>();
    _loadRewardedAttempt();
    return _rewardedLoadCompleter!.future;
  }

  void _loadRewardedAttempt() {
    _log(
      'Loading rewarded ad (attempt ${_rewardedLoadAttempts + 1}/$maxFailedLoadAttempts)...',
    );
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _rewardedLoadAttempts = 0;
          _isRewardedLoading = false;
          _rewardedLoadCompleter?.complete(true);
          _rewardedLoadCompleter = null;
          _log('Rewarded ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedLoadAttempts++;
          _log('Rewarded ad failed: ${error.message} (${error.code}).');
          if (!_isPermanentFormatError(error) &&
              _rewardedLoadAttempts < maxFailedLoadAttempts) {
            Future<void>.delayed(_retryDelay(_rewardedLoadAttempts), () {
              if (_isRewardedLoading) _loadRewardedAttempt();
            });
            return;
          }
          _isRewardedLoading = false;
          _rewardedLoadCompleter?.complete(false);
          _rewardedLoadCompleter = null;
          if (!_isPermanentFormatError(error)) {
            _rewardedRetryTimer = Timer(const Duration(seconds: 45), () {
              unawaited(loadRewardedAd());
            });
          }
        },
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    if (_isShowingAnyAd) return false;
    if (_rewardedAd == null && !await loadRewardedAd()) return false;
    final ad = _rewardedAd;
    if (ad == null) return false;
    _rewardedAd = null;
    _isShowingAnyAd = true;
    var rewardEarned = false;
    final closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _isShowingAnyAd = false;
        unawaited(loadRewardedAd());
        if (!closed.isCompleted) closed.complete(rewardEarned);
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        _log('Rewarded ad failed to show: ${error.message}.');
        shownAd.dispose();
        _isShowingAnyAd = false;
        unawaited(loadRewardedAd());
        if (!closed.isCompleted) closed.complete(false);
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, __) => rewardEarned = true);
      return await closed.future;
    } catch (error) {
      _log('Rewarded show error: $error');
      ad.dispose();
      _isShowingAnyAd = false;
      unawaited(loadRewardedAd());
      return false;
    }
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  Future<bool> loadAppOpenAd() async {
    if (!_canLoadAds || appOpenAdUnitId.isEmpty) return false;
    await initialize();
    if (isAppOpenAdReady) return true;
    if (_isAppOpenLoading && _appOpenLoadCompleter != null) {
      return _appOpenLoadCompleter!.future;
    }
    _appOpenRetryTimer?.cancel();
    _appOpenLoadAttempts = 0;
    _isAppOpenLoading = true;
    _appOpenLoadCompleter = Completer<bool>();
    _loadAppOpenAttempt();
    return _appOpenLoadCompleter!.future;
  }

  void _loadAppOpenAttempt() {
    _log(
      'Loading app-open ad (attempt ${_appOpenLoadAttempts + 1}/$maxFailedLoadAttempts)...',
    );
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          _appOpenAd = ad;
          _appOpenLoadedAt = DateTime.now();
          _appOpenLoadAttempts = 0;
          _isAppOpenLoading = false;
          _appOpenLoadCompleter?.complete(true);
          _appOpenLoadCompleter = null;
          _log('App-open ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _appOpenLoadAttempts++;
          _log('App-open ad failed: ${error.message} (${error.code}).');
          if (_appOpenLoadAttempts < maxFailedLoadAttempts) {
            Future<void>.delayed(_retryDelay(_appOpenLoadAttempts), () {
              if (_isAppOpenLoading) _loadAppOpenAttempt();
            });
            return;
          }
          _isAppOpenLoading = false;
          _appOpenLoadCompleter?.complete(false);
          _appOpenLoadCompleter = null;
          _appOpenRetryTimer = Timer(const Duration(seconds: 45), () {
            unawaited(loadAppOpenAd());
          });
        },
      ),
    );
  }

  bool get isAppOpenAdReady {
    final loadedAt = _appOpenLoadedAt;
    if (_appOpenAd != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) >= _appOpenMaxAge) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _appOpenLoadedAt = null;
      unawaited(loadAppOpenAd());
    }
    return _appOpenAd != null && !_isShowingAppOpenAd;
  }

  Future<void> showAppOpenAd() async {
    if (_isShowingAnyAd || !isAppOpenAdReady) {
      if (!_isShowingAnyAd) unawaited(loadAppOpenAd());
      return;
    }
    final ad = _appOpenAd;
    if (ad == null) return;
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _isShowingAnyAd = true;
    _isShowingAppOpenAd = true;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        _isShowingAnyAd = false;
        _isShowingAppOpenAd = false;
        unawaited(loadAppOpenAd());
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        _log('App-open ad failed to show: ${error.message}.');
        shownAd.dispose();
        _isShowingAnyAd = false;
        _isShowingAppOpenAd = false;
        unawaited(loadAppOpenAd());
        if (!closed.isCompleted) closed.complete();
      },
    );
    try {
      await ad.show();
      await closed.future;
    } catch (error) {
      _log('App-open show error: $error');
      ad.dispose();
      _isShowingAnyAd = false;
      _isShowingAppOpenAd = false;
      unawaited(loadAppOpenAd());
    }
  }

  Future<bool> loadNativeAd() async {
    if (!_canLoadAds || nativeAdUnitId.isEmpty) return false;
    await initialize();
    if (isNativeAdReady && nativeAd != null) return true;
    if (_isNativeLoading && _nativeLoadCompleter != null) {
      return _nativeLoadCompleter!.future;
    }
    _nativeRetryTimer?.cancel();
    _nativeLoadAttempts = 0;
    _isNativeLoading = true;
    _nativeLoadCompleter = Completer<bool>();
    _loadNativeAttempt();
    return _nativeLoadCompleter!.future;
  }

  void _loadNativeAttempt() {
    final ad = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF1A1A1A),
        cornerRadius: 10,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF000000),
          backgroundColor: const Color(0xFFFFFFFF),
          style: NativeTemplateFontStyle.bold,
          size: 16,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFFFFFFFF),
          backgroundColor: const Color(0x00000000),
          style: NativeTemplateFontStyle.bold,
          size: 16,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xB3FFFFFF),
          backgroundColor: const Color(0x00000000),
          style: NativeTemplateFontStyle.normal,
          size: 14,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0x99FFFFFF),
          backgroundColor: const Color(0x00000000),
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (loadedAd) {
          nativeAd?.dispose();
          nativeAd = loadedAd as NativeAd;
          isNativeAdReady = true;
          _isNativeLoading = false;
          _nativeLoadAttempts = 0;
          _nativeLoadCompleter?.complete(true);
          _nativeLoadCompleter = null;
          _log('Native ad loaded.');
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          _nativeLoadAttempts++;
          _log('Native ad failed: ${error.message} (${error.code}).');
          if (_nativeLoadAttempts < maxFailedLoadAttempts) {
            Future<void>.delayed(_retryDelay(_nativeLoadAttempts), () {
              if (_isNativeLoading) _loadNativeAttempt();
            });
            return;
          }
          _isNativeLoading = false;
          isNativeAdReady = false;
          _nativeLoadCompleter?.complete(false);
          _nativeLoadCompleter = null;
          _nativeRetryTimer = Timer(const Duration(seconds: 45), () {
            unawaited(loadNativeAd());
          });
        },
      ),
    );
    unawaited(ad.load());
  }

  void disposeNativeAd() {
    nativeAd?.dispose();
    nativeAd = null;
    isNativeAdReady = false;
  }

  void dispose() {
    _interstitialRetryTimer?.cancel();
    _rewardedRetryTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    _nativeRetryTimer?.cancel();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
    disposeNativeAd();
    _interstitialAd = null;
    _rewardedAd = null;
    _appOpenAd = null;
    _appOpenLoadedAt = null;
    _isShowingAnyAd = false;
    _isShowingAppOpenAd = false;
  }
}
