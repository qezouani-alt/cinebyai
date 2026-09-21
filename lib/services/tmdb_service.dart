import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import '../models/tv_show_model.dart';
import '../models/movie_details_model.dart';
import '../models/tv_show_details_model.dart';

class TmdbService {
  static const String _apiKey = 'e794ccd60488962d067044c54100e665';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static final TmdbService _instance = TmdbService._internal();
  factory TmdbService() => _instance;
  TmdbService._internal()
    : _client = http.Client(),
      _requestTimeout = const Duration(seconds: 15);

  @visibleForTesting
  TmdbService.forTesting({
    required http.Client client,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _client = client,
       _requestTimeout = requestTimeout;

  final http.Client _client;
  final Duration _requestTimeout;
  final Map<Uri, Future<Map<String, dynamic>>> _pendingRequests = {};

  // Coalesce requests shared by splash, providers, and AI recommendations.
  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String> parameters = const {},
  ]) {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: {
        'api_key': _apiKey,
        'language': 'en-US',
        ...parameters,
      },
    );
    return _pendingRequests.putIfAbsent(uri, () async {
      try {
        final response = await _client.get(uri).timeout(_requestTimeout);
        if (response.statusCode != 200) {
          throw StateError('Movie data request failed (HTTP ${response.statusCode}).');
        }
        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Movie data response is invalid.');
        }
        return data;
      } on TimeoutException {
        throw TimeoutException('Movie data request timed out.', _requestTimeout);
      } on http.ClientException {
        // ClientException may include the request URL and its API key.
        throw StateError('Unable to connect to the movie service.');
      } finally {
        _pendingRequests.remove(uri);
      }
    });
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) decode, {
    Map<String, String> parameters = const {},
    String field = 'results',
  }) async {
    final data = await _get(path, parameters);
    final results = data[field];
    if (results is! List) {
      throw const FormatException('Movie data response is missing its list.');
    }
    return results.whereType<Map<String, dynamic>>().map(decode).toList();
  }

  Future<List<Movie>> getTrendingMovies() =>
      _getList('/trending/movie/day', Movie.fromJson);

  Future<List<Movie>> getTopRatedMovies() =>
      _getList('/movie/top_rated', Movie.fromJson);

  Future<List<Movie>> getPopularMovies() =>
      _getList('/movie/popular', Movie.fromJson);

  Future<List<Movie>> getNewestMovies() =>
      _getList('/movie/now_playing', Movie.fromJson);

  Future<List<TVShow>> getTrendingTVShows() =>
      _getList('/trending/tv/day', TVShow.fromJson);

  Future<List<TVShow>> getTopRatedTVShows() =>
      _getList('/tv/top_rated', TVShow.fromJson);

  Future<List<TVShow>> getPopularTVShows() =>
      _getList('/tv/popular', TVShow.fromJson);

  Future<List<TVShow>> getOnTheAirTVShows() =>
      _getList('/tv/on_the_air', TVShow.fromJson);

  Future<List<Map<String, dynamic>>> getTVShowGenres() =>
      _getList('/genre/tv/list', (genre) => genre, field: 'genres');

  Future<List<TVShow>> getTVShowsByGenre(int genreId) => _getList(
    '/discover/tv',
    TVShow.fromJson,
    parameters: {'sort_by': 'popularity.desc', 'with_genres': '$genreId'},
  );

  Future<List<Map<String, dynamic>>> getMovieGenres() =>
      _getList('/genre/movie/list', (genre) => genre, field: 'genres');

  Future<List<Movie>> getMoviesByGenre(int genreId) => _getList(
    '/discover/movie',
    Movie.fromJson,
    parameters: {'sort_by': 'popularity.desc', 'with_genres': '$genreId'},
  );

  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    return _getList(
      '/search/movie',
      Movie.fromJson,
      parameters: {'query': query.trim()},
    );
  }

  Future<List<TVShow>> searchTVShows(String query) async {
    if (query.trim().isEmpty) return [];
    return _getList(
      '/search/tv',
      TVShow.fromJson,
      parameters: {'query': query.trim()},
    );
  }

  Future<MovieDetails> getMovieDetails(int movieId) async {
    final data = await _get(
      '/movie/$movieId',
      {'append_to_response': 'credits,videos'},
    );
    return MovieDetails.fromJson(data);
  }

  Future<TVShowDetails> getTVShowDetails(int tvShowId) async {
    final data = await _get(
      '/tv/$tvShowId',
      {'append_to_response': 'credits,videos'},
    );
    return TVShowDetails.fromJson(data);
  }

  Future<List<Episode>> getSeasonDetails(int tvShowId, int seasonNumber) =>
      _getList(
        '/tv/$tvShowId/season/$seasonNumber',
        Episode.fromJson,
        field: 'episodes',
      );
}
