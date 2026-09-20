import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../services/app_data_loader.dart';
import '../services/ad_service.dart';

import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.dataLoader,
    this.prepareAds,
    this.showAppOpenAd,
    this.destinationBuilder,
    this.minimumDisplayDuration = const Duration(seconds: 5),
  });

  final AppDataLoader? dataLoader;
  final Future<void> Function()? prepareAds;
  final Future<void> Function()? showAppOpenAd;
  final WidgetBuilder? destinationBuilder;
  final Duration minimumDisplayDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AppDataLoader _dataLoader = widget.dataLoader ?? AppDataLoader();
  final Completer<void> _adsInitialized = Completer<void>();
  bool _startupInProgress = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _dataLoader.addListener(_onLoadingStateChanged);

    // A SplashScreen context is below CupertinoApp's Navigator, unlike the
    // root MovieApp context. This makes it safe to present the ATT explainer.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        await (widget.prepareAds ?? _requestTrackingAndInitializeAds)();
      } catch (error) {
        debugPrint('Unable to prepare launch ads: $error');
      } finally {
        if (!_adsInitialized.isCompleted) _adsInitialized.complete();
      }
    });

    // Start loading data
    unawaited(_loadData());
  }

  Future<void> _requestTrackingAndInitializeAds() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;

        if (status == TrackingStatus.notDetermined && mounted) {
          await _showTrackingExplainer();
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }
    } catch (error) {
      debugPrint('Unable to request tracking authorization: $error');
    }

    try {
      if (!mounted) return;
      // Initialize ads after the ATT choice is known on iOS.
      await AdService.initialize();
      final adService = AdService();
      final appOpenLoad = _preloadAd(adService.loadAppOpenAd(), 'app-open');
      unawaited(_preloadAd(adService.loadInterstitialAd(), 'interstitial'));
      unawaited(_preloadAd(adService.loadRewardedAd(), 'rewarded'));
      unawaited(_preloadAd(adService.loadNativeAd(), 'native'));

      // Only App Open is presented at launch. The other formats are ready for
      // the first eligible user action without making the launch feel spammy.
      await appOpenLoad.timeout(
        const Duration(seconds: 7),
        onTimeout: () => false,
      );
    } catch (error) {
      debugPrint('Unable to initialize ads: $error');
    }
  }

  Future<void> _showTrackingExplainer() {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Help keep Cineby AI free'),
        content: const Text(
          'With your permission, we use a device identifier to provide more relevant ads. '
          'Your choice will not affect access to the app.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool> _preloadAd(Future<bool> load, String label) async {
    try {
      return await load;
    } catch (error) {
      debugPrint('Unable to preload $label ad: $error');
      return false;
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (_startupInProgress || _hasNavigated || !mounted) return;
    _startupInProgress = true;
    try {
      final splashDeadline = DateTime.now().add(widget.minimumDisplayDuration);
      var dataFinished = false;
      final dataLoad = _dataLoader
          .loadAppData(forceRefresh: forceRefresh)
          .whenComplete(() => dataFinished = true);

      if (forceRefresh || widget.minimumDisplayDuration == Duration.zero) {
        // A user-requested retry should still report a real loading failure.
        await dataLoad;
      } else {
        // Remote data and ad setup are both best-effort. Never leave the user
        // on the launch screen for longer than the configured five seconds.
        await Future.any<void>([
          dataLoad,
          Future<void>.delayed(widget.minimumDisplayDuration),
        ]);
      }

      if (!mounted || _hasNavigated) return;
      // Preserve the retry UI for a fast, definite data failure. A request
      // that is merely slow continues in the background after navigation.
      if (dataFinished && !_dataLoader.isReady) return;

      // Keep the loading screen for its configured duration when data is
      // ready early. This gives the preloaded App Open request enough time to
      // finish without adding an extra network wait to startup.
      final remainingSplashTime = splashDeadline.difference(DateTime.now());
      if (!forceRefresh && remainingSplashTime > Duration.zero) {
        await Future<void>.delayed(remainingSplashTime);
      }
      if (!mounted || _hasNavigated) return;

      // Allow ATT prompt and ad preparation to settle before evaluating launch ad.
      if (!forceRefresh && !_adsInitialized.isCompleted) {
        await _adsInitialized.future.timeout(
          const Duration(seconds: 4),
          onTimeout: () {},
        );
      }
      if (!mounted || _hasNavigated) return;

      // Show a cold-start App Open ad over the loading screen, as recommended
      // by AdMob. A non-ready ad is skipped so network latency never holds up
      // the user after the five-second splash limit.
      await _showReadyLaunchAd();
      if (!mounted || _hasNavigated) return;

      _hasNavigated = true;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: widget.destinationBuilder ?? (_) => const MainScreen(),
          ),
        );
      }
    } finally {
      _startupInProgress = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showReadyLaunchAd() async {
    try {
      if (widget.showAppOpenAd != null) {
        await widget.showAppOpenAd!();
      } else if (AdService().isAppOpenAdReady) {
        await AdService().showAppOpenAd();
      }
    } catch (error) {
      debugPrint('Unable to show launch ad: $error');
    }
  }

  void _onLoadingStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _dataLoader.removeListener(_onLoadingStateChanged);
    if (!_adsInitialized.isCompleted) _adsInitialized.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback color
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App icon with glow
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                      blurRadius: 50,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/appicon.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App name
              const Text(
                'Cineby: Movies & Series',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'MOVIES  •  SERIES',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                  letterSpacing: 4.0, // Wide letter spacing for elegance
                ),
              ),

              const Spacer(),

              // Loading Indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _dataLoader.hasError
                    ? _buildErrorState()
                    : _buildMinimalLoadingBar(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalLoadingBar() {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange[400], size: 32),
        const SizedBox(height: 12),
        Text(
          _dataLoader.errorMessage ?? 'Connection Issue',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _startupInProgress
              ? null
              : () => unawaited(_loadData(forceRefresh: true)),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
