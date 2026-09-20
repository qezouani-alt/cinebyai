import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tv_show_details_model.dart';

import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:newmovie/services/remote_config_service.dart';
import '../models/movie_model.dart';
import '../providers/movie_providers.dart';
import '../providers/reminder_provider.dart';
import '../screens/reminder_page.dart';
import '../services/ad_service.dart';
import '../widgets/seasons_sheet.dart';

class TVShowDetailsPage extends ConsumerStatefulWidget {
  final int tvShowId;

  const TVShowDetailsPage({super.key, required this.tvShowId});

  @override
  ConsumerState<TVShowDetailsPage> createState() => _TVShowDetailsPageState();
}

class _TVShowDetailsPageState extends ConsumerState<TVShowDetailsPage> {
  final TmdbService _tmdbService = TmdbService();
  final AdService _adService = AdService();
  TVShowDetails? _tvShowDetails;
  bool _isLoading = true;
  bool _isOverviewExpanded = false;
  bool _canPop = false;
  bool showSpecialButton = false;
  bool isRemoteConfigLoaded = false;
  Timer? _remoteConfigTimer;

  @override
  void initState() {
    super.initState();
    _loadTVShowDetails();
    loadRemoteConfig();
    _remoteConfigTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadRemoteConfig(),
    );
  }

  Future<void> loadRemoteConfig() async {
    final result = await RemoteConfigService.shouldShowSpecialButton();
    if (!mounted) return;

    setState(() {
      showSpecialButton = result;
      isRemoteConfigLoaded = true;
    });
  }

  @override
  void dispose() {
    _remoteConfigTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTVShowDetails() async {
    try {
      final details = await _tmdbService.getTVShowDetails(widget.tvShowId);
      if (mounted) {
        setState(() {
          _tvShowDetails = details;
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

  String _formatRuntime(List<int>? runtimes) {
    if (runtimes == null || runtimes.isEmpty) return 'N/A';
    final avgRuntime = runtimes.reduce((a, b) => a + b) ~/ runtimes.length;
    return '${avgRuntime}m';
  }

  void _watchFullSeries() {
    final show = _tvShowDetails;
    if (show == null || show.seasons.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SeasonsSheet(
        tvShowId: show.id,
        showTitle: show.name,
        seasons: show.seasons,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if TV show is in watchlist
    final watchlist = ref.watch(watchlistProvider);
    final isInWatchlist =
        _tvShowDetails != null &&
        watchlist.any((m) => m.id == _tvShowDetails!.id);

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
          if (mounted) {
            navigator.pop(result);
          }
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
            : _tvShowDetails == null
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
                      'Failed to load TV show details',
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
                  // Backdrop Header with Back Button (Fixed)
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    backgroundColor: CupertinoColors.black,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    leadingWidth: 72,
                    leading: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        top: 8,
                        bottom: 8,
                      ),
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
                            color: CupertinoColors.black.withValues(alpha: 0.5),
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
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_tvShowDetails!.backdropUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: _tvShowDetails!.backdropUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppTheme.transformativeTeal.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppTheme.transformativeTeal.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            )
                          else
                            Container(
                              color: AppTheme.transformativeTeal.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  CupertinoColors.black.withValues(alpha: 0.3),
                                  CupertinoColors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Elite Header with Poster and Info
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // Main Content
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            // Poster Removed
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
                                    _tvShowDetails!.name.toUpperCase(),
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
                                          _tvShowDetails!.rating
                                              .toStringAsFixed(1),
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
                                          _tvShowDetails!
                                                      .firstAirDate
                                                      .isNotEmpty &&
                                                  _tvShowDetails!
                                                          .firstAirDate
                                                          .length >=
                                                      4
                                              ? _tvShowDetails!.firstAirDate
                                                    .substring(0, 4)
                                              : 'N/A',
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status text removed
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (showSpecialButton)
                              _buildActionButton(
                                icon: CupertinoIcons.play_fill,
                                label: 'Watch Full Series',
                                isPrimary: true,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _watchFullSeries();
                                },
                              ),
                            const SizedBox(height: 12),
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
                                            r.mediaId == _tvShowDetails!.id &&
                                            r.mediaType == 'tv',
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
                                          if (_tvShowDetails != null) {
                                            Navigator.push(
                                              context,
                                              CupertinoPageRoute(
                                                builder: (context) =>
                                                    ReminderPage(
                                                      mediaId:
                                                          _tvShowDetails!.id,
                                                      mediaType: 'tv',
                                                      title:
                                                          _tvShowDetails!.name,
                                                      posterUrl: _tvShowDetails!
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
                              _tvShowDetails!.overview.isNotEmpty
                                  ? _tvShowDetails!.overview
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
                          if (_tvShowDetails!.overview.length > 200)
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

                  // Info Grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: CupertinoColors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildInfoItem(
                                  'Status',
                                  _tvShowDetails!.status ?? 'N/A',
                                ),
                                _buildInfoItem(
                                  'Type',
                                  _tvShowDetails!.type ?? 'TV Show',
                                ),
                                _buildInfoItem(
                                  'First Air',
                                  _tvShowDetails!.firstAirDate.split('-').first,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _buildInfoItem(
                                  'Seasons',
                                  '${_tvShowDetails!.numberOfSeasons ?? 0}',
                                ),
                                _buildInfoItem(
                                  'Episodes',
                                  '${_tvShowDetails!.numberOfEpisodes ?? 0}',
                                ),
                                _buildInfoItem(
                                  'Runtime',
                                  _formatRuntime(
                                    _tvShowDetails!.episodeRuntime,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Genres
                  if (_tvShowDetails!.genres.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tvShowDetails!.genres
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

                  // Seasons Section
                  if (_tvShowDetails!.seasons.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: const Text(
                          'Seasons',
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
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _tvShowDetails!.seasons.length,
                          itemBuilder: (context, index) {
                            final season = _tvShowDetails!.seasons[index];
                            return Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: season.posterUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: season.posterUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: AppTheme.neonRed
                                                        .withValues(alpha: 0.1),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        color: CupertinoColors
                                                            .systemGrey6,
                                                        child: const Icon(
                                                          CupertinoIcons.tv,
                                                          color: CupertinoColors
                                                              .systemGrey,
                                                        ),
                                                      ),
                                            )
                                          : Container(
                                              color:
                                                  CupertinoColors.systemGrey6,
                                              child: const Icon(
                                                CupertinoIcons.tv,
                                                color:
                                                    CupertinoColors.systemGrey,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    season.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${season.episodeCount} Episodes',
                                    style: TextStyle(
                                      color: CupertinoColors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // Cast Section
                  if (_tvShowDetails!.cast.isNotEmpty) ...[
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
                          itemCount: _tvShowDetails!.cast.length,
                          itemBuilder: (context, index) {
                            final actor = _tvShowDetails!.cast[index];
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

                    // TV Show Information
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                        child: const Text(
                          'Show Info',
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
                            children: [
                              _buildDetailRow(
                                'Seasons',
                                '${_tvShowDetails!.numberOfSeasons ?? "N/A"}',
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              _buildDetailRow(
                                'Episodes',
                                '${_tvShowDetails!.numberOfEpisodes ?? "N/A"}',
                              ),
                              const Divider(color: Colors.white12, height: 24),
                              _buildDetailRow(
                                'Status',
                                _tvShowDetails!.status ?? 'N/A',
                              ),
                              if (_tvShowDetails!.type != null) ...[
                                const Divider(
                                  color: Colors.white12,
                                  height: 24,
                                ),
                                _buildDetailRow('Type', _tvShowDetails!.type!),
                              ],
                              const Divider(color: Colors.white12, height: 24),
                              _buildDetailRow(
                                'First Air',
                                _tvShowDetails!.firstAirDate,
                              ),
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

  Future<void> _watchTrailer() async {
    if (_tvShowDetails == null) return;

    // Find trailer video (YouTube)
    final trailer = _tvShowDetails!.videos.firstWhere(
      (video) => video.type == 'Trailer' && video.site == 'YouTube',
      orElse: () => _tvShowDetails!.videos.firstWhere(
        (video) => video.site == 'YouTube',
        orElse: () => _tvShowDetails!.videos.isNotEmpty
            ? _tvShowDetails!.videos.first
            : Video(id: '', key: '', name: '', type: '', site: ''),
      ),
    );

    if (trailer.key.isEmpty) {
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CupertinoColors.white.withValues(alpha: 0.1),
                      ),
                    ),
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
                          'Sorry, we couldn\'t find a trailer for this TV show.',
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CupertinoColors.white.withValues(alpha: 0.1),
                      ),
                    ),
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
                          'Could not open the trailer URL.',
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
    if (_tvShowDetails == null) return;

    // Convert TVShowDetails to Movie (Adapter pattern for watchlist)
    final movie = Movie(
      id: _tvShowDetails!.id,
      title: _tvShowDetails!.name,
      overview: _tvShowDetails!.overview,
      posterPath: _tvShowDetails!.posterUrl.replaceFirst(
        'https://image.tmdb.org/t/p/w500',
        '',
      ),
      backdropPath: _tvShowDetails!.backdropUrl.replaceFirst(
        'https://image.tmdb.org/t/p/original',
        '',
      ),
      voteAverage: _tvShowDetails!.rating,
      releaseDate: _tvShowDetails!.firstAirDate,
      mediaType: 'tv',
    );

    // Check if already in watchlist
    final isAlreadyInWatchlist = ref
        .read(watchlistProvider.notifier)
        .isInWatchlist(movie.id, 'tv');

    if (isAlreadyInWatchlist) {
      // Remove from watchlist
      ref.read(watchlistProvider.notifier).removeMovie(movie.id, 'tv');

      // Show removed message
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
    } else {
      // Add to watchlist
      ref.read(watchlistProvider.notifier).addMovie(movie);

      // Show success message
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

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
