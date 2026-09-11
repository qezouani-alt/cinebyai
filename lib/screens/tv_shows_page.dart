import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/glass_card.dart';
import '../widgets/tv_show_carousel.dart';
import '../theme/app_theme.dart';
import '../providers/movie_providers.dart';
import '../models/tv_show_model.dart';
import '../screens/tv_show_details_page.dart';

class TVShowsPage extends ConsumerStatefulWidget {
  const TVShowsPage({super.key});

  @override
  ConsumerState<TVShowsPage> createState() => _TVShowsPageState();
}

class _TVShowsPageState extends ConsumerState<TVShowsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<TVShow> _searchResults = [];
  bool _isSearching = false;

  // Genre selection state
  int? _selectedGenreId = 10759; // Action & Adventure genre ID
  List<TVShow> _genreMovies = [];
  bool _isLoadingGenre = false;

  @override
  void initState() {
    super.initState();
    // Load Action & Adventure TV shows by default after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadGenreMovies(10759);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final tmdbService = ref.read(tmdbServiceProvider);
      final results = await tmdbService.searchTVShows(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _loadGenreMovies(int genreId) async {
    setState(() {
      _isLoadingGenre = true;
    });

    try {
      final tmdbService = ref.read(tmdbServiceProvider);
      final results = await tmdbService.getTVShowsByGenre(genreId);
      if (mounted) {
        setState(() {
          _genreMovies = results;
          _isLoadingGenre = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGenre = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _searchController.text.isNotEmpty;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: CustomScrollView(
        slivers: [
          // Search Bar (Safe Area)
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.search,
                        color: AppTheme.neonRed,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _searchController,
                          placeholder: 'Search TV shows...',
                          placeholderStyle: TextStyle(
                            color: CupertinoColors.white.withValues(alpha: 0.5),
                          ),
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                          ),
                          decoration: null,
                          onChanged: (value) {
                            _performSearch(value);
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                            _performSearch('');
                          },
                          child: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Results or Regular Content
          if (showSearchResults) ...[
            if (_isSearching)
              const SliverFillRemaining(
                child: Center(
                  child: CupertinoActivityIndicator(
                    radius: 20,
                    color: AppTheme.neonRed,
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.search,
                        size: 60,
                        color: CupertinoColors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No TV shows found',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.6),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _TVShowCard(tvShow: _searchResults[index]);
                  }, childCount: _searchResults.length),
                ),
              ),
          ] else ...[
            // Top Rated Carousel
            SliverToBoxAdapter(
              child: ref
                  .watch(topRatedTVShowsProvider)
                  .when(
                    data: (tvShows) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TVShowCarousel(tvShows: tvShows),
                    ),
                    loading: () => const SizedBox(
                      height: 340,
                      child: Center(
                        child: CupertinoActivityIndicator(
                          radius: 20,
                          color: AppTheme.neonRed,
                        ),
                      ),
                    ),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),
            ),

            // Browse by Genre Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.square_grid_2x2,
                      color: AppTheme.neonRed,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Browse by Genre',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.9),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Genre Chips
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ref.read(tmdbServiceProvider).getTVShowGenres(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 60);
                  }

                  final genres = snapshot.data!;

                  return SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: genres.length,
                      itemBuilder: (context, index) {
                        final genre = genres[index];
                        final genreId = genre['id'] as int;
                        final genreName = genre['name'] as String;
                        final isSelected = _selectedGenreId == genreId;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (_selectedGenreId == genreId) {
                                _selectedGenreId = null;
                                _genreMovies = [];
                              } else {
                                _selectedGenreId = genreId;
                                _loadGenreMovies(genreId);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.neonRed.withValues(alpha: 0.15)
                                  : CupertinoColors.black.withValues(
                                      alpha: 0.6,
                                    ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.neonRed
                                    : CupertinoColors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.neonRed.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                genreName,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.neonRed
                                      : CupertinoColors.white,
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(top: 10)),

            // Genre TV Shows Grid (only show if genre is selected)
            if (_selectedGenreId != null) ...[
              if (_isLoadingGenre)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(
                      child: CupertinoActivityIndicator(
                        radius: 20,
                        color: AppTheme.neonRed,
                      ),
                    ),
                  ),
                )
              else if (_genreMovies.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _genreMovies.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 16),
                          child: _TVShowCard(tvShow: _genreMovies[index]),
                        );
                      },
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(top: 20)),
            ],

            // Trending Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.flame,
                      color: AppTheme.neonRed,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trending Now',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.9),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildTVShowSection(ref.watch(trendingTVShowsProvider)),

            // Popular Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.heart_fill,
                      color: AppTheme.neonRed,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Popular',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.9),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildTVShowSection(ref.watch(popularTVShowsProvider)),

            // On The Air Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.antenna_radiowaves_left_right,
                      color: AppTheme.neonLime,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'On The Air',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.9),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildTVShowSection(ref.watch(onTheAirTVShowsProvider)),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
        ],
      ),
    );
  }

  Widget _buildTVShowSection(AsyncValue<List<TVShow>> tvShowsAsync) {
    return tvShowsAsync.when(
      data: (tvShows) => SliverToBoxAdapter(
        child: SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tvShows.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: _TVShowCard(tvShow: tvShows[index]),
              );
            },
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 280,
          child: Center(
            child: CupertinoActivityIndicator(
              radius: 20,
              color: AppTheme.neonRed,
            ),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: SizedBox(
          height: 280,
          child: Center(
            child: Text(
              'Failed to load TV shows\nPlease add your TMDB API key',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TVShowCard extends StatelessWidget {
  final TVShow tvShow;

  const _TVShowCard({required this.tvShow});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => TVShowDetailsPage(tvShowId: tvShow.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.glassRadius),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // TV Show Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.glassRadius),
              child: tvShow.posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: tvShow.posterUrl,
                      width: double.infinity,
                      height: double.infinity,
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
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.transformativeTeal.withValues(alpha: 0.3),
                      child: const Icon(
                        CupertinoIcons.tv,
                        color: CupertinoColors.white,
                        size: 40,
                      ),
                    ),
            ),

            // Glass Overlay (High Contrast)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.glassRadius),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: 0.6),
                      border: Border(
                        top: BorderSide(
                          color: CupertinoColors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tvShow.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.star_fill,
                              color: AppTheme.neonLime,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tvShow.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
