import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie_model.dart';
import '../models/tv_show_model.dart';
import '../services/tmdb_service.dart';

// TMDB Service Provider
final tmdbServiceProvider = Provider<TmdbService>((ref) {
  return TmdbService();
});

// Trending Movies Provider
final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getTrendingMovies();
});

// Top Rated Movies Provider
final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getTopRatedMovies();
});

// Popular Movies Provider
final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getPopularMovies();
});

// Newest Movies Provider
final newestMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getNewestMovies();
});

// Trending TV Shows Provider
final trendingTVShowsProvider = FutureProvider<List<TVShow>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getTrendingTVShows();
});

// Top Rated TV Shows Provider
final topRatedTVShowsProvider = FutureProvider<List<TVShow>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getTopRatedTVShows();
});

// Popular TV Shows Provider
final popularTVShowsProvider = FutureProvider<List<TVShow>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getPopularTVShows();
});

// On The Air TV Shows Provider
final onTheAirTVShowsProvider = FutureProvider<List<TVShow>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);
  return await tmdbService.getOnTheAirTVShows();
});

// Watchlist State Notifier
class WatchlistNotifier extends StateNotifier<List<Movie>> {
  WatchlistNotifier() : super([]);

  void addMovie(Movie movie) {
    if (!state.any((m) => m.id == movie.id && m.mediaType == movie.mediaType)) {
      state = [...state, movie];
    }
  }

  void removeMovie(int movieId, String mediaType) {
    state = state
        .where((m) => !(m.id == movieId && m.mediaType == mediaType))
        .toList();
  }

  bool isInWatchlist(int movieId, String mediaType) {
    return state.any((m) => m.id == movieId && m.mediaType == mediaType);
  }

  void clearWatchlist() {
    state = [];
  }
}

// Watchlist Provider
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<Movie>>(
  (ref) {
    return WatchlistNotifier();
  },
);
