import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_data_loader.dart';
import '../services/ad_service.dart';

import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppDataLoader _dataLoader = AppDataLoader();
  final Completer<void> _adsInitialized = Completer<void>();

  @override
  void initState() {
    super.initState();

    // A SplashScreen context is below CupertinoApp's Navigator, unlike the
    // root MovieApp context. This makes it safe to present the ATT explainer.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestTrackingAndInitializeAds();
      if (!_adsInitialized.isCompleted) {
        _adsInitialized.complete();
      }
    });

    // Start loading data
    _loadData();
  }

  Future<void> _requestTrackingAndInitializeAds() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final status =
            await AppTrackingTransparency.trackingAuthorizationStatus;

        if (status == TrackingStatus.notDetermined && mounted) {
          await _showTrackingExplainer();
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      }
    } catch (error) {
      debugPrint('Unable to request tracking authorization: $error');
    }

    try {
      // Initialize ads after the ATT choice is known on iOS. A declined choice
      // still allows the ad SDK to serve non-personalized ads.
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

  Future<void> _loadData() async {
    // Add listener to track state changes
    _dataLoader.addListener(_onLoadingStateChanged);

    // Wait a minimum time for branding (aesthetic)
    await Future.wait([
      _dataLoader.loadAppData(),
      Future.delayed(const Duration(milliseconds: 3500)), // Min splash time
    ]);

    // Keep the splash visible until the ATT flow and initial app-open ad load
    // finish. This gives the app-open ad a chance to display before navigation.
    await _adsInitialized.future;

    // Navigate to main screen when ready
    if (_dataLoader.isReady && mounted) {
      // Show app open ad before navigating
      final adService = AdService();
      await adService.showAppOpenAd();

      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => const MainScreen()),
        );
      }
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

              // Title: Cine by AI
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Cine ',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: 'by ',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white70,
                      ),
                    ),
                    TextSpan(
                      text: 'AI',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w900, // Extra bold for AI
                        color: Colors.redAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle: AI Recomandation
              Text(
                'AI RECOMMENDATION', // Corrected spelling for pro look
                style: GoogleFonts.outfit(
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
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {});
            _dataLoader.retry();
          },
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
