import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie_model.dart';
import 'tmdb_service.dart';
import 'ai_service.dart';

/// Centralized service for loading all app data on launch
/// Handles caching, parallel loading, error handling, and retry logic
class AppDataLoader {
  static final AppDataLoader _instance = AppDataLoader._internal();
  factory AppDataLoader() => _instance;
  AppDataLoader._internal();

  final TmdbService _tmdbService = TmdbService();
  final AIService _aiService = AIService.instance;

  // State
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isReady = false;
  Future<void>? _activeLoad;

  // Cached data
  List<Movie>? _trendingMovies;
  List<Movie>? _popularMovies;
  Map<String, dynamic>? _aiDailyPick;

  // Cache expiration
  static const Duration _cacheDuration = Duration(hours: 1);
  static const String _cacheKeyTrending = 'cached_trending';
  static const String _cacheKeyPopular = 'cached_popular';
  static const String _cacheKeyTimestamp = 'cache_timestamp';

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isReady => _isReady;
  List<Movie>? get trendingMovies => _trendingMovies;
  List<Movie>? get popularMovies => _popularMovies;
  Map<String, dynamic>? get aiDailyPick => _aiDailyPick;

  /// Main entry point - loads all required app data
  Future<void> loadAppData({bool forceRefresh = false}) {
    // Every caller must wait for the same in-flight operation. Returning early
    // here used to let the splash screen navigate before data was available.
    final activeLoad = _activeLoad;
    if (activeLoad != null) return activeLoad;

    final load = _loadAppData(forceRefresh: forceRefresh);
    _activeLoad = load.whenComplete(() => _activeLoad = null);
    return _activeLoad!;
  }

  Future<void> _loadAppData({required bool forceRefresh}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _notifyListeners();

    try {
      // Check if we have fresh cached data
      if (!forceRefresh && await _hasFreshCache()) {
        if (kDebugMode) {
          print('📦 Using cached data');
        }
        if (!await _loadFromCache()) {
          throw const FormatException('The cached movie data is incomplete.');
        }
        _isReady = true;
        _isLoading = false;
        _notifyListeners();
        return;
      }

      if (kDebugMode) {
        print('🔄 Loading fresh data from API...');
      }

      // Load all data in parallel for speed
      final results = await Future.wait([
        _loadTrendingMovies(),
        _loadPopularMovies(),
        _loadAIDailyPick(),
      ], eagerError: false); // Don't fail all if one fails

      // Check if any critical load failed
      bool hasFailure = results.any((r) => r == false);

      if (hasFailure) {
        if (kDebugMode) {
          print('⚠️ Some data failed to load, checking fallbacks...');
        }
        // Try to use cached data as fallback
        if (await _hasCachedData() && await _loadFromCache()) {
          _hasError = true;
          _errorMessage = 'Using cached data due to network issues';
        } else {
          throw Exception('Failed to load data and no cache available');
        }
      } else {
        // All data loaded successfully, save to cache
        await _saveToCache();
      }

      _isReady = true;
      _hasError = false;

      if (kDebugMode) {
        print('✅ App data loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ App data loading failed: $e');
      }
      _hasError = true;
      _errorMessage = 'Failed to load app data. Please check your connection.';
      _isReady = false;

      // Try to load from cache as last resort
      if (await _hasCachedData() && await _loadFromCache()) {
        _isReady = true;
        _errorMessage = 'Loaded from cache. Tap retry for fresh data.';
      }
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  /// Retry loading after error
  Future<void> retry() async {
    await loadAppData(forceRefresh: true);
  }

  /// Load trending movies
  Future<bool> _loadTrendingMovies() async {
    try {
      _trendingMovies = await _tmdbService.getTrendingMovies();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load trending: $e');
      }
      return false;
    }
  }

  /// Load popular movies
  Future<bool> _loadPopularMovies() async {
    try {
      _popularMovies = await _tmdbService.getPopularMovies();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load popular: $e');
      }
      return false;
    }
  }

  /// Load AI daily pick
  Future<bool> _loadAIDailyPick() async {
    try {
      _aiDailyPick = await _aiService.getDailyRecommendation();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load AI pick: $e');
      }
      return false;
    }
  }

  /// Check if cached data is still fresh
  Future<bool> _hasFreshCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheKeyTimestamp);

      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);

      return age < _cacheDuration && await _hasCachedData();
    } catch (e) {
      return false;
    }
  }

  /// Check if any cached data exists
  Future<bool> _hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_cacheKeyTrending) &&
          prefs.containsKey(_cacheKeyPopular);
    } catch (e) {
      return false;
    }
  }

  /// Load data from cache
  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load trending
      final trendingJson = prefs.getString(_cacheKeyTrending);
      final popularJson = prefs.getString(_cacheKeyPopular);
      if (trendingJson == null || popularJson == null) return false;
      final trending = json.decode(trendingJson);
      final popular = json.decode(popularJson);
      if (trending is! List || popular is! List) return false;
      final trendingMovies = trending
          .map((m) => Movie.fromJson(m as Map<String, dynamic>))
          .toList();

      // Load popular
      final popularMovies = popular
          .map((m) => Movie.fromJson(m as Map<String, dynamic>))
          .toList();
      if (trendingMovies.isEmpty || popularMovies.isEmpty) return false;
      _trendingMovies = trendingMovies;
      _popularMovies = popularMovies;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load from cache: $e');
      }
      return false;
    }
  }

  /// Save current data to cache
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save trending
      if (_trendingMovies != null) {
        final jsonList = _trendingMovies!.map((m) => m.toJson()).toList();
        await prefs.setString(_cacheKeyTrending, json.encode(jsonList));
      }

      // Save popular
      if (_popularMovies != null) {
        final jsonList = _popularMovies!.map((m) => m.toJson()).toList();
        await prefs.setString(_cacheKeyPopular, json.encode(jsonList));
      }

      // Save timestamp
      await prefs.setInt(
        _cacheKeyTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );

      if (kDebugMode) {
        print('💾 Data saved to cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save cache: $e');
      }
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyTrending);
      await prefs.remove(_cacheKeyPopular);
      await prefs.remove(_cacheKeyTimestamp);

      _trendingMovies = null;
      _popularMovies = null;

      if (kDebugMode) {
        print('🗑️ Cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear cache: $e');
      }
    }
  }

  // Simple state notification (can be replaced with ChangeNotifier if needed)
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}
