class TVShowDetails {
  final int id;
  final String name;
  final String overview;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final String firstAirDate;
  final List<int> genreIds;

  // Extended details
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<int>? episodeRuntime; // Can have multiple runtimes
  final String? status; // Returning Series, Ended, etc.
  final String? type; // Scripted, Documentary, etc.
  final List<Cast> cast;
  final List<Genre> genres;
  final List<Video> videos;
  final List<Season> seasons;

  TVShowDetails({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.firstAirDate,
    required this.genreIds,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.episodeRuntime,
    this.status,
    this.type,
    this.cast = const [],
    this.genres = const [],
    this.videos = const [],
    this.seasons = const [],
  });

  factory TVShowDetails.fromJson(Map<String, dynamic> json) {
    return TVShowDetails(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : '',
      backdropUrl: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/original${json['backdrop_path']}'
          : '',
      rating: (json['vote_average'] ?? 0).toDouble(),
      firstAirDate: json['first_air_date'] ?? '',
      genreIds: (json['genre_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
      episodeRuntime: (json['episode_run_time'] as List<dynamic>?)?.cast<int>(),
      status: json['status'],
      type: json['type'],
      cast:
          (json['credits']?['cast'] as List<dynamic>?)
              ?.take(10)
              .map((e) => Cast.fromJson(e))
              .toList() ??
          [],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => Genre.fromJson(e))
              .toList() ??
          [],
      videos:
          (json['videos']?['results'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e))
              .toList() ??
          [],
      seasons:
          (json['seasons'] as List<dynamic>?)
              ?.map((e) => Season.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Season {
  final int id;
  final String name;
  final int seasonNumber;
  final int episodeCount;
  final String? airDate;
  final String? posterUrl;

  Season({
    required this.id,
    required this.name,
    required this.seasonNumber,
    required this.episodeCount,
    this.airDate,
    this.posterUrl,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      seasonNumber: json['season_number'] ?? 0,
      episodeCount: json['episode_count'] ?? 0,
      airDate: json['air_date'],
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w185${json['poster_path']}'
          : null,
    );
  }
}

// Reuse Cast, Genre, Video from movie_details_model
class Cast {
  final int id;
  final String name;
  final String character;
  final String? profileUrl;

  Cast({
    required this.id,
    required this.name,
    required this.character,
    this.profileUrl,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      profileUrl: json['profile_path'] != null
          ? 'https://image.tmdb.org/t/p/w185${json['profile_path']}'
          : null,
    );
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class Video {
  final String id;
  final String key;
  final String name;
  final String type;
  final String site;

  Video({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
    required this.site,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      site: json['site'] ?? '',
    );
  }
}

class Episode {
  final int id;
  final String name;
  final String overview;
  final int episodeNumber;
  final int seasonNumber;
  final String? stillPath;
  final String? airDate;
  final double voteAverage;
  final int? runtime;

  Episode({
    required this.id,
    required this.name,
    required this.overview,
    required this.episodeNumber,
    required this.seasonNumber,
    this.stillPath,
    this.airDate,
    required this.voteAverage,
    this.runtime,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Episode ${json['episode_number']}',
      overview: json['overview'] ?? '',
      episodeNumber: json['episode_number'] ?? 0,
      seasonNumber: json['season_number'] ?? 0,
      stillPath: json['still_path'] != null
          ? 'https://image.tmdb.org/t/p/w300${json['still_path']}'
          : null,
      airDate: json['air_date'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      runtime: json['runtime'],
    );
  }
}
