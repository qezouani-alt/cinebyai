import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../providers/movie_providers.dart';
import '../models/movie_model.dart';
import '../screens/movie_details_page.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
import '../screens/tv_show_details_page.dart';
import '../services/ad_navigation_service.dart';

class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);
    final reminders = ref.watch(reminderProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: CustomScrollView(
        slivers: [
          // Custom Header (Replaces Navbar to remove top space)
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    const Text(
                      'My Collection',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Custom Elegant Tab Switch
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth / 2;
                          return Stack(
                            children: [
                              // Animated Active Indicator
                              AnimatedAlign(
                                alignment: _selectedSegment == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: Container(
                                  width: width,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonRed,
                                    borderRadius: BorderRadius.circular(21),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.neonRed.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Tab Labels
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        if (_selectedSegment != 0) {
                                          HapticFeedback.lightImpact();
                                          setState(() => _selectedSegment = 0);
                                        }
                                      },
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: TextStyle(
                                            color: _selectedSegment == 0
                                                ? CupertinoColors
                                                      .white // Text on Green should be White? Or Black? iOS usually White on heavy colors.
                                                : CupertinoColors.white
                                                      .withValues(alpha: 0.6),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'SF Pro Display',
                                          ),
                                          child: const Text('Watchlist'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        if (_selectedSegment != 1) {
                                          HapticFeedback.lightImpact();
                                          setState(() => _selectedSegment = 1);
                                        }
                                      },
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          style: TextStyle(
                                            color: _selectedSegment == 1
                                                ? CupertinoColors.white
                                                : CupertinoColors.white
                                                      .withValues(alpha: 0.6),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'SF Pro Display',
                                          ),
                                          child: const Text('Reminders'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedSegment == 0) ...[
            // Watchlist Count
            if (watchlist.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.bookmark_fill,
                          color: AppTheme.neonRed,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${watchlist.length} Movies',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Watchlist Grid
            watchlist.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.bookmark,
                            size: 80,
                            color: CupertinoColors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your watchlist is empty',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add movies from Discover',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.4,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childCount: watchlist.length,
                      itemBuilder: (context, index) {
                        return _WatchlistCard(movie: watchlist[index]);
                      },
                    ),
                  ),
          ] else ...[
            // Reminders Content
            if (reminders.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 1, // List view style for reminders
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childCount: reminders.length,
                  itemBuilder: (context, index) {
                    return _ReminderCard(reminder: reminders[index]);
                  },
                ),
              )
            else
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.bell,
                        size: 80,
                        color: CupertinoColors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Reminders',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.6),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upcoming releases will appear here',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
        ],
      ),
    );
  }
}

class _WatchlistCard extends ConsumerStatefulWidget {
  final Movie movie;

  const _WatchlistCard({required this.movie});

  @override
  ConsumerState<_WatchlistCard> createState() => _WatchlistCardState();
}

class _WatchlistCardState extends ConsumerState<_WatchlistCard> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.movie.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        ref
            .read(watchlistProvider.notifier)
            .removeMovie(widget.movie.id, widget.movie.mediaType);
      },
      background: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppTheme.glassRadius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          if (widget.movie.mediaType == 'tv') {
            await AdNavigationService.pushAfterInterstitial(
              context,
              () => CupertinoPageRoute<void>(
                builder: (context) =>
                    TVShowDetailsPage(tvShowId: widget.movie.id),
              ),
            );
          } else {
            await AdNavigationService.pushAfterInterstitial(
              context,
              () => CupertinoPageRoute<void>(
                builder: (context) =>
                    MovieDetailsPage(movieId: widget.movie.id),
              ),
            );
          }
        },
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              // Poster
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.glassRadius),
                  bottomLeft: Radius.circular(AppTheme.glassRadius),
                ),
                child: widget.movie.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.movie.posterUrl,
                        width: 80,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 120,
                          color: AppTheme.transformativeTeal.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 120,
                          color: AppTheme.transformativeTeal.withValues(
                            alpha: 0.3,
                          ),
                          child: const Icon(
                            CupertinoIcons.film,
                            color: CupertinoColors.white,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 120,
                        color: AppTheme.transformativeTeal.withValues(
                          alpha: 0.3,
                        ),
                        child: const Icon(
                          CupertinoIcons.film,
                          color: CupertinoColors.white,
                        ),
                      ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.movie.releaseDate != null &&
                          widget.movie.releaseDate!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.movie.releaseDate!.split('-').first,
                          style: TextStyle(
                            color: CupertinoColors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.star_fill,
                            color: CupertinoColors.systemYellow,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.movie.voteAverage.toStringAsFixed(1)} / 10',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow Indicator
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        try {
          await ref.read(reminderProvider.notifier).removeReminder(reminder.id);
          return true;
        } catch (_) {
          return false;
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppTheme.glassRadius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.white,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          if (reminder.mediaType == 'movie') {
            await AdNavigationService.pushAfterInterstitial(
              context,
              () => CupertinoPageRoute<void>(
                builder: (context) =>
                    MovieDetailsPage(movieId: reminder.mediaId),
              ),
            );
          } else {
            await AdNavigationService.pushAfterInterstitial(
              context,
              () => CupertinoPageRoute<void>(
                builder: (context) =>
                    TVShowDetailsPage(tvShowId: reminder.mediaId),
              ),
            );
          }
        },
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              // Poster
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.glassRadius),
                  bottomLeft: Radius.circular(AppTheme.glassRadius),
                ),
                child: reminder.posterUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: reminder.posterUrl,
                        width: 80,
                        height: 120, // Rectangular aspect fit
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 120,
                          color: AppTheme.transformativeTeal.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 120,
                          color: AppTheme.transformativeTeal.withValues(
                            alpha: 0.3,
                          ),
                          child: const Icon(
                            CupertinoIcons.film,
                            color: CupertinoColors.white,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 120,
                        color: AppTheme.transformativeTeal.withValues(
                          alpha: 0.3,
                        ),
                        child: const Icon(
                          CupertinoIcons.film,
                          color: CupertinoColors.white,
                        ),
                      ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            color: CupertinoColors.white.withValues(alpha: 0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(reminder.scheduledTime),
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.time,
                            color: CupertinoColors.white.withValues(alpha: 0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(reminder.scheduledTime),
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bell Icon Indicator
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  CupertinoIcons.bell_fill,
                  color: CupertinoColors.systemOrange.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
