import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tv_show_model.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import '../screens/tv_show_details_page.dart';
import '../services/ad_navigation_service.dart';

class TVShowCarousel extends StatefulWidget {
  final List<TVShow> tvShows;

  const TVShowCarousel({super.key, required this.tvShows});

  @override
  State<TVShowCarousel> createState() => _TVShowCarouselState();
}

class _TVShowCarouselState extends State<TVShowCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    // Delay auto-scroll start until after the PageView is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_pageController.hasClients && widget.tvShows.isNotEmpty) {
        final itemCount = widget.tvShows.length > 10
            ? 10
            : widget.tvShows.length;
        final nextPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tvShows.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show max 10 TV shows in carousel
    final carouselTVShows = widget.tvShows.take(10).toList();

    return Column(
      children: [
        // Carousel
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: carouselTVShows.length,
            itemBuilder: (context, index) {
              return _CarouselItem(tvShow: carouselTVShows[index]);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselTVShows.length,
            (index) => _PageIndicator(isActive: index == _currentPage),
          ),
        ),
      ],
    );
  }
}

class _CarouselItem extends StatelessWidget {
  final TVShow tvShow;

  const _CarouselItem({required this.tvShow});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await AdNavigationService.pushAfterInterstitial(
          context,
          () => CupertinoPageRoute<void>(
            builder: (context) => TVShowDetailsPage(tvShowId: tvShow.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.glassRadius),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.glassRadius),
          child: Stack(
            children: [
              // Backdrop Image
              Positioned.fill(
                child: tvShow.backdropUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: tvShow.backdropUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.transformativeTeal.withValues(
                            alpha: 0.3,
                          ),
                          child: const Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.transformativeTeal.withValues(
                            alpha: 0.3,
                          ),
                          child: const Icon(
                            CupertinoIcons.tv,
                            color: CupertinoColors.white,
                            size: 60,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.transformativeTeal.withValues(
                          alpha: 0.3,
                        ),
                        child: const Icon(
                          CupertinoIcons.tv,
                          color: CupertinoColors.white,
                          size: 60,
                        ),
                      ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoColors.black.withValues(alpha: 0.0),
                        CupertinoColors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Glass Info Card
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.star_fill,
                            color: AppTheme.neonLime,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Top Rated',
                            style: TextStyle(
                              color: AppTheme.neonLime.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tvShow.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neonRed.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.neonRed.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.star_fill,
                                  color: AppTheme.neonRed,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tvShow.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: AppTheme.neonRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tvShow.firstAirDate != null &&
                              tvShow.firstAirDate!.length >= 4) ...[
                            const SizedBox(width: 12),
                            Text(
                              tvShow.firstAirDate!.substring(0, 4),
                              style: TextStyle(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;

  const _PageIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 24 : 6,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.neonRed
            : CupertinoColors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
