import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/glass_card.dart';
import '../widgets/movie_carousel.dart';
import '../theme/app_theme.dart';
import '../providers/movie_providers.dart';
import '../models/movie_model.dart';
import '../screens/movie_details_page.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _searchResults = [];
  bool _isSearching = false;

  // Genre selection state
  int? _selectedGenreId = 28; // Action genre ID
  List<Movie> _genreMovies = [];
  bool _isLoadingGenre = false;

  @override
  void initState() {
    super.initState();
    // Load Action movies by default after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadGenreMovies(28);
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
      final results = await tmdbService.searchMovies(query);
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
      final results = await tmdbService.getMoviesByGenre(genreId);
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
                          placeholder: 'Search movies...',
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
                        'No results found',
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
                    return _MovieCard(movie: _searchResults[index]);
                  }, childCount: _searchResults.length),
                ),
              ),
          ] else ...[
            // Top Rated Carousel
            SliverToBoxAdapter(
              child: ref
                  .watch(topRatedMoviesProvider)
                  .when(
                    data: (movies) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: MovieCarousel(movies: movies),
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
                future: ref.read(tmdbServiceProvider).getMovieGenres(),
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
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Center(
                                child: Text(
                                  genreName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.neonRed
                                        : CupertinoColors.white,
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
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

            // Genre Movies Grid (only show if genre is selected)
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
                          child: _MovieCard(movie: _genreMovies[index]),
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

            _buildMovieSection(ref.watch(trendingMoviesProvider)),

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

            _buildMovieSection(ref.watch(popularMoviesProvider)),

            // Newest Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock_fill,
                      color: AppTheme.neonLime,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Newest',
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

            _buildMovieSection(ref.watch(newestMoviesProvider)),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
        ],
      ),
    );
  }

  Widget _buildMovieSection(AsyncValue<List<Movie>> moviesAsync) {
    return moviesAsync.when(
      data: (movies) => SliverToBoxAdapter(
        child: SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: _MovieCard(movie: movies[index]),
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
              'Failed to load movies\nPlease add your TMDB API key',
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

class _MovieCard extends ConsumerWidget {
  final Movie movie;

  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => MovieDetailsPage(movieId: movie.id),
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
            // Movie Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.glassRadius),
              child: movie.posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: movie.posterUrl,
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
                          CupertinoIcons.film,
                          color: CupertinoColors.white,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.transformativeTeal.withValues(alpha: 0.3),
                      child: const Icon(
                        CupertinoIcons.film,
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
                          movie.title,
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
                              movie.voteAverage.toStringAsFixed(1),
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
