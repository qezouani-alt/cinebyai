import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tv_show_details_model.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';
import '../screens/watch_screen.dart';
import '../services/ad_service.dart';
import 'premium_access_dialog.dart';

class SeasonsSheet extends StatefulWidget {
  final int tvShowId;
  final String showTitle;
  final List<Season> seasons;

  const SeasonsSheet({
    super.key,
    required this.tvShowId,
    required this.showTitle,
    required this.seasons,
  });

  @override
  State<SeasonsSheet> createState() => _SeasonsSheetState();
}

class _SeasonsSheetState extends State<SeasonsSheet> {
  final TmdbService _tmdbService = TmdbService();
  final AdService _adService = AdService();
  int? _expandedSeasonId;
  final Map<int, List<Episode>> _seasonEpisodes = {};
  final Map<int, bool> _isLoadingSeason = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.deepCharcoal,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seasons',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.seasons.length} Seasons',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Seasons List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: widget.seasons.length,
              itemBuilder: (context, index) {
                final season = widget.seasons[index];
                final isExpanded = _expandedSeasonId == season.seasonNumber;
                final isLoading =
                    _isLoadingSeason[season.seasonNumber] ?? false;
                final episodes = _seasonEpisodes[season.seasonNumber];

                return Column(
                  children: [
                    // Season Header (Clickable)
                    GestureDetector(
                      onTap: () => _toggleSeason(season.seasonNumber),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppTheme.neonRed.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExpanded
                                ? AppTheme.neonRed.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Season Poster
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: season.posterUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: season.posterUrl!,
                                      width: 48,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 48,
                                      height: 72,
                                      color: Colors.grey.shade900,
                                      child: const Icon(
                                        Icons.tv,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    season.name,
                                    style: TextStyle(
                                      color: isExpanded
                                          ? AppTheme.neonRed
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${season.episodeCount} Episodes',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Icon
                            if (isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.neonRed,
                                ),
                              )
                            else
                              Icon(
                                isExpanded
                                    ? CupertinoIcons.chevron_up
                                    : CupertinoIcons.chevron_down,
                                color: isExpanded
                                    ? AppTheme.neonRed
                                    : Colors.white54,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Episodes List
                    if (isExpanded && episodes != null)
                      ...episodes.map((episode) => _buildEpisodeItem(episode)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeItem(Episode episode) {
    return GestureDetector(
      onTap: () {
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => PremiumAccessDialog(
            title: 'Unlock Episode',
            message:
                'Watch a short ad to support our platform and watch this episode immediately.',
            onCancel: () => Navigator.pop(dialogContext),
            onWatchAd: () async {
              Navigator.pop(dialogContext); // Close Dialog
              final navigator = Navigator.of(context);
              final watched = await _adService.showRewardedAd();
              if (watched && context.mounted) {
                navigator.pop(); // Close Sheet
                navigator.push(
                  CupertinoPageRoute(
                    builder: (context) => WatchScreen(
                      movieId: widget.tvShowId,
                      title: widget.showTitle,
                      isTvShow: true,
                      season: episode.seasonNumber,
                      episode: episode.episodeNumber,
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(32, 4, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Play Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.neonRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.play_fill,
                color: AppTheme.neonRed,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${episode.episodeNumber}. ${episode.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (episode.overview.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        episode.overview,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSeason(int seasonNumber) async {
    if (_expandedSeasonId == seasonNumber) {
      setState(() => _expandedSeasonId = null);
      return;
    }

    setState(() {
      _expandedSeasonId = seasonNumber;
    });

    // Fetch episodes if not loaded
    if (!_seasonEpisodes.containsKey(seasonNumber)) {
      setState(() {
        _isLoadingSeason[seasonNumber] = true;
      });

      try {
        final episodes = await _tmdbService.getSeasonDetails(
          widget.tvShowId,
          seasonNumber,
        );
        if (mounted) {
          setState(() {
            _seasonEpisodes[seasonNumber] = episodes;
            _isLoadingSeason[seasonNumber] = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingSeason[seasonNumber] = false;
          });
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load episodes: $e')),
          );
        }
      }
    }
  }
}
