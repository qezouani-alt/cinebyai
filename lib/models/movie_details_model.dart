class MovieDetails {
  final int id;
  final String title;
  final String overview;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final String releaseDate;
  final List<int> genreIds;

  // Extended details
  final int? runtime; // in minutes
  final String? tagline;
  final int? budget;
  final int? revenue;
  final String? status; // Released, Post Production, etc.
  final int voteCount;
  final String? originalLanguage;
  final List<Cast> cast;
  final List<Crew> crew;
  final List<Genre> genres;
  final List<Video> videos;
  final List<ProductionCompany> productionCompanies;

  MovieDetails({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.releaseDate,
    required this.genreIds,
    this.runtime,
    this.tagline,
    this.budget,
    this.revenue,
    this.status,
    this.voteCount = 0,
    this.originalLanguage,
    this.cast = const [],
    this.crew = const [],
    this.genres = const [],
    this.videos = const [],
    this.productionCompanies = const [],
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : '',
      backdropUrl: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/original${json['backdrop_path']}'
          : '',
      rating: (json['vote_average'] ?? 0).toDouble(),
      releaseDate: json['release_date'] ?? '',
      genreIds: (json['genre_ids'] as List<dynamic>?)?.cast<int>() ?? [],
      runtime: json['runtime'],
      tagline: json['tagline'],
      budget: json['budget'],
      revenue: json['revenue'],
      status: json['status'],
      voteCount: json['vote_count'] ?? 0,
      originalLanguage: json['original_language'],
      cast:
          (json['credits']?['cast'] as List<dynamic>?)
              ?.take(10)
              .map((e) => Cast.fromJson(e))
              .toList() ??
          [],
      crew:
          (json['credits']?['crew'] as List<dynamic>?)
              ?.map((e) => Crew.fromJson(e))
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
      productionCompanies:
          (json['production_companies'] as List<dynamic>?)
              ?.map((e) => ProductionCompany.fromJson(e))
              .toList() ??
          [],
    );
  }
}

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
  final String key; // YouTube key
  final String name;
  final String type; // Trailer, Teaser, etc.
  final String site; // YouTube, Vimeo, etc.

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

class Crew {
  final int id;
  final String name;
  final String job;
  final String department;
  final String? profileUrl;

  Crew({
    required this.id,
    required this.name,
    required this.job,
    required this.department,
    this.profileUrl,
  });

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      job: json['job'] ?? '',
      department: json['department'] ?? '',
      profileUrl: json['profile_path'] != null
          ? 'https://image.tmdb.org/t/p/w185${json['profile_path']}'
          : null,
    );
  }
}

class ProductionCompany {
  final int id;
  final String name;
  final String? logoUrl;

  ProductionCompany({required this.id, required this.name, this.logoUrl});

  factory ProductionCompany.fromJson(Map<String, dynamic> json) {
    return ProductionCompany(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logoUrl: json['logo_path'] != null
          ? 'https://image.tmdb.org/t/p/w92${json['logo_path']}'
          : null,
    );
  }
}
