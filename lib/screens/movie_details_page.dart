import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie_model.dart';
import '../models/movie_details_model.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../providers/movie_providers.dart';
import '../providers/reminder_provider.dart';
import '../screens/reminder_page.dart';
import '../services/ad_service.dart';

class MovieDetailsPage extends ConsumerStatefulWidget {
  final int movieId;

  const MovieDetailsPage({super.key, required this.movieId});

  @override
  ConsumerState<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends ConsumerState<MovieDetailsPage> {
  final TmdbService _tmdbService = TmdbService();
  final AdService _adService = AdService();
  MovieDetails? _movieDetails;
  bool _isLoading = true;
  bool _isOverviewExpanded = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final details = await _tmdbService.getMovieDetails(widget.movieId);
      if (mounted) {
        setState(() {
          _movieDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatRuntime(int? minutes) {
    if (minutes == null) return 'N/A';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  String _formatMoney(int? amount) {
    if (amount == null || amount == 0) return 'N/A';
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return '\$$amount';
  }

  String? _getDirector() {
    if (_movieDetails == null) return null;
    final director = _movieDetails!.crew.firstWhere(
      (member) => member.job == 'Director',
      orElse: () => _movieDetails!.crew.firstWhere(
        (member) => member.department == 'Directing',
        orElse: () => _movieDetails!.crew.first,
      ),
    );
    return director.name.isNotEmpty ? director.name : null;
  }

  Future<void> _watchTrailer() async {
    if (_movieDetails == null) return;

    // Find trailer video (YouTube)
    final trailer = _movieDetails!.videos.firstWhere(
      (video) => video.type == 'Trailer' && video.site == 'YouTube',
      orElse: () => _movieDetails!.videos.firstWhere(
        (video) => video.site == 'YouTube',
        orElse: () => _movieDetails!.videos.isNotEmpty
            ? _movieDetails!.videos.first
            : Video(id: '', key: '', name: '', type: '', site: ''),
      ),
    );

    if (trailer.key.isEmpty) {
      // Show error if no trailer found
      if (mounted) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.darkBackgroundGray.withValues(
                        alpha: 0.85,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CupertinoColors.systemGrey.withValues(
                          alpha: 0.3,
                        ),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.video_camera_solid,
                          color: CupertinoColors.systemGrey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Trailer Available',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sorry, no trailer is available for this movie.',
                          style: TextStyle(
                            color: CupertinoColors.white.withValues(alpha: 0.8),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return;
    }

    // Open YouTube video
    final url = Uri.parse('https://www.youtube.com/watch?v=${trailer.key}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.darkBackgroundGray.withValues(
                        alpha: 0.85,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CupertinoColors.systemRed.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          color: CupertinoColors.systemRed,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to open trailer.',
                          style: TextStyle(
                            color: CupertinoColors.white.withValues(alpha: 0.8),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  void _toggleWatchlist() {
    if (_movieDetails == null) return;

    // Convert MovieDetails to Movie
    final movie = Movie(
      id: _movieDetails!.id,
      title: _movieDetails!.title,
      overview: _movieDetails!.overview,
      posterPath: _movieDetails!.posterUrl,
      backdropPath: _movieDetails!.backdropUrl,
      voteAverage: _movieDetails!.rating,
      releaseDate: _movieDetails!.releaseDate,
    );

    // Check if already in watchlist
    final isAlreadyInWatchlist = ref
        .read(watchlistProvider.notifier)
        .isInWatchlist(movie.id, 'movie');

    if (isAlreadyInWatchlist) {
      // Remove from watchlist
      ref.read(watchlistProvider.notifier).removeMovie(movie.id, 'movie');

      // Show removed message (glassmorphic dialog)
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemRed.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.minus_circle_fill,
                        color: CupertinoColors.systemRed,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Removed',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${movie.title} has been removed from your watchlist.',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CupertinoColors.systemRed,
                                CupertinoColors.systemRed.withValues(
                                  alpha: 0.8,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemRed.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Add to watchlist
      ref.read(watchlistProvider.notifier).addMovie(movie);

      // Show success message (glassmorphic dialog)
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.neonGreen),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonGreen.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: AppTheme.neonGreen,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Added to Watchlist',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${movie.title} has been added to your watchlist.',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.8),
                          fontSize: 15,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.neonGreen,
                                AppTheme.neonGreen.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonGreen.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: CupertinoColors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if movie is in watchlist
    final watchlist = ref.watch(watchlistProvider);
    final isInWatchlist =
        _movieDetails != null &&
        watchlist.any((m) => m.id == _movieDetails!.id);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);

        // Show Ad
        await _adService.showInterstitialAd();

        // Allow pop next time
        if (mounted) {
          setState(() {
            _canPop = true;
          });
          // Trigger pop again
          Future.microtask(() {
            if (mounted) {
              navigator.pop(result);
            }
          });
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: _isLoading
            ? const Center(
                child: CupertinoActivityIndicator(
                  radius: 20,
                  color: AppTheme.neonRed,
                ),
              )
            : _movieDetails == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 60,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load movie details',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Header with Poster and Info
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Main Content
                        Column(
                          children: [
                            const SizedBox(height: 60), // Space for back button
                            // Centered Poster
                            Center(
                              child: Container(
                                width: 200,
                                height: 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.glassRadius,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CupertinoColors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.glassRadius,
                                  ),
                                  child: _movieDetails!.posterUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: _movieDetails!.posterUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: AppTheme.transformativeTeal
                                                .withValues(alpha: 0.3),
                                            child: const Center(
                                              child:
                                                  CupertinoActivityIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: AppTheme
                                                    .transformativeTeal
                                                    .withValues(alpha: 0.3),
                                                child: const Icon(
                                                  CupertinoIcons.film,
                                                  color: CupertinoColors.white,
                                                  size: 60,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          color: AppTheme.transformativeTeal
                                              .withValues(alpha: 0.3),
                                          child: const Icon(
                                            CupertinoIcons.film,
                                            color: CupertinoColors.white,
                                            size: 60,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const SizedBox(height: 24),
                            // Elite Title & Info
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _movieDetails!.title.toUpperCase(),
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      height: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: AppTheme.neonRed,
                                          blurRadius: 20,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  // Glass Info Pill
                                  GlassCard(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Rating
                                        const Icon(
                                          CupertinoIcons.star_fill,
                                          color: AppTheme.neonRed,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _movieDetails!.rating.toStringAsFixed(
                                            1,
                                          ),
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          width: 1,
                                          height: 14,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                        // Year
                                        Text(
                                          _movieDetails!
                                                      .releaseDate
                                                      .isNotEmpty &&
                                                  _movieDetails!
                                                          .releaseDate
                                                          .length >=
                                                      4
                                              ? _movieDetails!.releaseDate
                                                    .substring(0, 4)
                                              : 'N/A',
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          width: 1,
                                          height: 14,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                        // Runtime
                                        Text(
                                          _formatRuntime(
                                            _movieDetails!.runtime,
                                          ),
                                          style: TextStyle(
                                            color: CupertinoColors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Tagline removed
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                children: [
                                  // Watch Button
                                  _buildActionButton(
                                    icon: CupertinoIcons.play_fill,
                                    label: 'Watch Trailer',
                                    isPrimary: false,
                                    onTap: () async {
                                      HapticFeedback.mediumImpact();
                                      await _watchTrailer();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildActionButton(
                                          icon: isInWatchlist
                                              ? CupertinoIcons.bookmark_fill
                                              : CupertinoIcons.bookmark,
                                          label: isInWatchlist
                                              ? 'Remove'
                                              : 'Watchlist',
                                          isPrimary: false,
                                          accentColor: isInWatchlist
                                              ? AppTheme.neonGreen
                                              : null,
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            _toggleWatchlist();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Consumer(
                                          builder: (context, ref, child) {
                                            final reminders = ref.watch(
                                              reminderProvider,
                                            );
                                            final isReminderSet = reminders.any(
                                              (r) =>
                                                  r.mediaId ==
                                                      _movieDetails!.id &&
                                                  r.mediaType == 'movie',
                                            );

                                            return _buildActionButton(
                                              icon: isReminderSet
                                                  ? CupertinoIcons.bell_fill
                                                  : CupertinoIcons.bell,
                                              label: 'Reminder',
                                              accentColor: isReminderSet
                                                  ? AppTheme.sunsetOrange
                                                  : null,
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                if (_movieDetails != null) {
                                                  Navigator.push(
                                                    context,
                                                    CupertinoPageRoute(
                                                      builder: (context) =>
                                                          ReminderPage(
                                                            mediaId:
                                                                _movieDetails!
                                                                    .id,
                                                            mediaType: 'movie',
                                                            title:
                                                                _movieDetails!
                                                                    .title,
                                                            posterUrl:
                                                                _movieDetails!
                                                                    .posterUrl,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                        // Back Button (Overlay)
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.maybePop(context);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.black.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CupertinoColors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  CupertinoIcons.back,
                                  color: CupertinoColors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Overview Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overview',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isOverviewExpanded = !_isOverviewExpanded;
                              });
                            },
                            child: Text(
                              _movieDetails!.overview.isNotEmpty
                                  ? _movieDetails!.overview
                                  : 'No overview available.',
                              style: TextStyle(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 14,
                                height: 1.5,
                              ),
                              maxLines: _isOverviewExpanded ? null : 4,
                              overflow: _isOverviewExpanded
                                  ? null
                                  : TextOverflow.ellipsis,
                            ),
                          ),
                          if (_movieDetails!.overview.length > 200)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isOverviewExpanded = !_isOverviewExpanded;
                                  });
                                },
                                child: Text(
                                  _isOverviewExpanded
                                      ? 'Show less'
                                      : 'Read more',
                                  style: const TextStyle(
                                    color: AppTheme.neonRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Details Info (Runtime, Budget, Revenue, Status, Votes, Language)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildInfoChip(
                            CupertinoIcons.time,
                            _formatRuntime(_movieDetails!.runtime),
                          ),
                          if (_movieDetails!.status?.isNotEmpty ?? false)
                            _buildInfoChip(
                              CupertinoIcons.checkmark_seal_fill,
                              _movieDetails!.status!,
                            ),
                          if (_movieDetails!.voteCount > 0)
                            _buildInfoChip(
                              CupertinoIcons.star,
                              '${_movieDetails!.voteCount} votes',
                            ),
                          if (_movieDetails!.originalLanguage != null)
                            _buildInfoChip(
                              CupertinoIcons.globe,
                              _movieDetails!.originalLanguage!.toUpperCase(),
                            ),
                          if (_movieDetails!.budget != null &&
                              _movieDetails!.budget! > 0)
                            _buildInfoChip(
                              CupertinoIcons.money_dollar_circle,
                              'Budget: ${_formatMoney(_movieDetails!.budget)}',
                            ),
                          if (_movieDetails!.revenue != null &&
                              _movieDetails!.revenue! > 0)
                            _buildInfoChip(
                              CupertinoIcons.chart_bar_alt_fill,
                              'Revenue: ${_formatMoney(_movieDetails!.revenue)}',
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Director & Production Companies
                  if (_getDirector() != null ||
                      _movieDetails!.productionCompanies.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_getDirector() != null) ...[
                              const Text(
                                'Director',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonRed.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.neonRed.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getDirector()!,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            if (_movieDetails!
                                .productionCompanies
                                .isNotEmpty) ...[
                              if (_getDirector() != null)
                                const SizedBox(height: 16),
                              const Text(
                                'Production',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _movieDetails!.productionCompanies
                                    .take(3)
                                    .map(
                                      (company) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.white
                                              .withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          company.name,
                                          style: TextStyle(
                                            color: CupertinoColors.white
                                                .withValues(alpha: 0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Genres
                  if (_movieDetails!.genres.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _movieDetails!.genres
                              .map(
                                (genre) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonRed.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.neonRed.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    genre.name,
                                    style: const TextStyle(
                                      color: AppTheme.neonRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),

                  // Cast Section
                  if (_movieDetails!.cast.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: const Text(
                          'Cast',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _movieDetails!.cast.length,
                          itemBuilder: (context, index) {
                            final actor = _movieDetails!.cast[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 100,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: actor.profileUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: actor.profileUrl!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: AppTheme
                                                        .transformativeTeal
                                                        .withValues(alpha: 0.3),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    color: AppTheme
                                                        .transformativeTeal
                                                        .withValues(alpha: 0.3),
                                                    child: const Icon(
                                                      CupertinoIcons
                                                          .person_fill,
                                                      color:
                                                          CupertinoColors.white,
                                                      size: 40,
                                                    ),
                                                  ),
                                            )
                                          : Container(
                                              width: 100,
                                              height: 100,
                                              color: AppTheme.transformativeTeal
                                                  .withValues(alpha: 0.3),
                                              child: const Icon(
                                                CupertinoIcons.person_fill,
                                                color: CupertinoColors.white,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      actor.name,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      actor.character,
                                      style: TextStyle(
                                        color: CupertinoColors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Detailed Info Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                        child: const Text(
                          'Production & Info',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Director',
                                _getDirector() ?? 'Unknown',
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              _buildDetailRow(
                                'Budget',
                                _formatMoney(_movieDetails!.budget),
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              _buildDetailRow(
                                'Revenue',
                                _formatMoney(_movieDetails!.revenue),
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              _buildDetailRow(
                                'Status',
                                _movieDetails!.status ?? 'N/A',
                              ),
                              if (_movieDetails!.originalLanguage != null) ...[
                                const Divider(
                                  color: Colors.white12,
                                  height: 24,
                                ),
                                _buildDetailRow(
                                  'Language',
                                  _movieDetails!.originalLanguage!
                                      .toUpperCase(),
                                ),
                              ],
                              if (_movieDetails!
                                  .productionCompanies
                                  .isNotEmpty) ...[
                                const Divider(
                                  color: Colors.white12,
                                  height: 24,
                                ),
                                const Text(
                                  'Production',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _movieDetails!.productionCompanies
                                      .map((c) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white10,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.white12,
                                            ),
                                          ),
                                          child: Text(
                                            c.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Bottom Padding
                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color? accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          // Primary: Vibrant Purple (Gradient for depth)
          // Secondary: Semi-transparent Dark Slate
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppTheme.vibrantPurple, AppTheme.deepIndigo],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isPrimary
              ? null
              : AppTheme.darkSlate.withValues(
                  alpha: 0.8,
                ), // Semi-transparent Dark Slate
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                accentColor ??
                (isPrimary
                    ? Colors.transparent
                    : CupertinoColors.white.withValues(
                        alpha: 0.1,
                      )), // Subtle white border
            width: 1,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.vibrantPurple.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accentColor ?? CupertinoColors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: accentColor ?? CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: isPrimary
                    ? [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.25),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.neonRed, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
