import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import '../models/tv_show_model.dart';
import '../models/movie_details_model.dart';
import '../models/tv_show_details_model.dart';

class TmdbService {
  // IMPORTANT: Replace with your actual TMDB API key from https://www.themoviedb.org/settings/api
  static const String _apiKey = 'e794ccd60488962d067044c54100e665';
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static final TmdbService _instance = TmdbService._internal();
  factory TmdbService() => _instance;
  TmdbService._internal();

  // Get Trending Movies
  Future<List<Movie>> getTrendingMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load trending movies: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching trending movies: $e');
    }
  }

  // Get Top Rated Movies
  Future<List<Movie>> getTopRatedMovies() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/movie/top_rated?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load top rated movies: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching top rated movies: $e');
    }
  }

  // Get Popular Movies
  Future<List<Movie>> getPopularMovies() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/movie/popular?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load popular movies: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching popular movies: $e');
    }
  }

  // Get Newest Movies (Now Playing)
  Future<List<Movie>> getNewestMovies() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/movie/now_playing?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load newest movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching newest movies: $e');
    }
  }

  // Get Trending TV Shows
  Future<List<TVShow>> getTrendingTVShows() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/trending/tv/day?api_key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => TVShow.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load trending TV shows: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching trending TV shows: $e');
    }
  }

  // Get Top Rated TV Shows
  Future<List<TVShow>> getTopRatedTVShows() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/tv/top_rated?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => TVShow.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load top rated TV shows: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching top rated TV shows: $e');
    }
  }

  // Get Popular TV Shows
  Future<List<TVShow>> getPopularTVShows() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/tv/popular?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => TVShow.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load popular TV shows: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching popular TV shows: $e');
    }
  }

  // Get On The Air TV Shows (Newest)
  Future<List<TVShow>> getOnTheAirTVShows() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/tv/on_the_air?api_key=$_apiKey&language=en-US&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => TVShow.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load on the air TV shows: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching on the air TV shows: $e');
    }
  }

  // Get TV Show Genres
  Future<List<Map<String, dynamic>>> getTVShowGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/tv/list?api_key=$_apiKey&language=en-US'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List genres = data['genres'] ?? [];
        return genres.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load TV genres: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching TV genres: $e');
    }
  }

  // Get TV Shows by Genre
  Future<List<TVShow>> getTVShowsByGenre(int genreId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/discover/tv?api_key=$_apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genreId&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => TVShow.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load TV shows by genre: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching TV shows by genre: $e');
    }
  }

  // Get Movie Genres
  Future<List<Map<String, dynamic>>> getMovieGenres() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/genre/movie/list?api_key=$_apiKey&language=en-US'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List genres = data['genres'] ?? [];
        return genres.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load genres: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching genres: $e');
    }
  }

  // Get Movies by Genre
  Future<List<Movie>> getMoviesByGenre(int genreId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/discover/movie?api_key=$_apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genreId&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load movies by genre: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching movies by genre: $e');
    }
  }

  // Search Movies
  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/search/movie?api_key=$_apiKey&language=en-US&query=$query&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching movies: $e');
    }
  }

  // Search TV Shows
  Future<List<TVShow>> searchTVShows(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/search/tv?api_key=$_apiKey&language=en-US&query=$query&page=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => TVShow.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search TV shows: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching TV shows: $e');
    }
  }

  // Get Movie Details with cast, crew, videos
  Future<MovieDetails> getMovieDetails(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/movie/$movieId?api_key=$_apiKey&language=en-US&append_to_response=credits,videos',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MovieDetails.fromJson(data);
      } else {
        throw Exception('Failed to load movie details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movie details: $e');
    }
  }

  // Get TV Show Details with cast, crew, videos
  Future<TVShowDetails> getTVShowDetails(int tvShowId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/tv/$tvShowId?api_key=$_apiKey&language=en-US&append_to_response=credits,videos',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TVShowDetails.fromJson(data);
      } else {
        throw Exception(
          'Failed to load TV show details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching TV show details: $e');
    }
  }

  // Get Season Details (Episodes)
  Future<List<Episode>> getSeasonDetails(int tvShowId, int seasonNumber) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/tv/$tvShowId/season/$seasonNumber?api_key=$_apiKey&language=en-US',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List episodes = data['episodes'] ?? [];
        return episodes.map((json) => Episode.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load season details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching season details: $e');
    }
  }
}
