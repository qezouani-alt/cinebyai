import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  WatchlistNotifier({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance,
      super([]) {
    ready = _restore();
  }

  static const storageKey = 'saved_watchlist_v1';
  final Future<SharedPreferences> Function() _preferences;
  late final Future<void> ready;
  Future<void> _writeQueue = Future<void>.value();
  bool _hasLocalChange = false;

  Future<void> _restore() async {
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(storageKey);
      if (raw == null || _hasLocalChange || !mounted) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final movies = <Movie>[];
      final ids = <String>{};
      for (final entry in decoded) {
        try {
          final movie = Movie.fromJson(Map<String, dynamic>.from(entry as Map));
          final key = '${movie.mediaType}:${movie.id}';
          if (movie.id > 0 && ids.add(key)) movies.add(movie);
        } catch (error) {
          debugPrint('Ignoring an unreadable saved collection item: $error');
        }
      }
      if (mounted) state = movies;
    } catch (error) {
      debugPrint('Unable to restore collection: $error');
    }
  }

  void _persist() {
    final snapshot = List<Movie>.from(state);
    _writeQueue = _writeQueue
        .catchError((Object error) {
          debugPrint('Unable to save collection: $error');
        })
        .then((_) async {
          await ready;
          final prefs = await _preferences();
          final saved = await prefs.setString(
            storageKey,
            jsonEncode(snapshot.map((movie) => movie.toJson()).toList()),
          );
          if (!saved) throw StateError('Unable to save collection.');
        });
  }

  void addMovie(Movie movie) {
    if (!state.any((m) => m.id == movie.id && m.mediaType == movie.mediaType)) {
      state = [...state, movie];
      _hasLocalChange = true;
      _persist();
    }
  }

  void removeMovie(int movieId, String mediaType) {
    state = state
        .where((m) => !(m.id == movieId && m.mediaType == mediaType))
        .toList();
    _hasLocalChange = true;
    _persist();
  }

  bool isInWatchlist(int movieId, String mediaType) {
    return state.any((m) => m.id == movieId && m.mediaType == mediaType);
  }

  void clearWatchlist() {
    state = [];
    _hasLocalChange = true;
    _persist();
  }
}

// Watchlist Provider
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<Movie>>(
  (ref) {
    return WatchlistNotifier();
  },
);
