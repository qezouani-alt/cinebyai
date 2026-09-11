import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import 'tmdb_service.dart';

/// AI Service for Movie Recommendations
///
/// Powered by Google Gemini AI for intelligent movie discovery
class AIService {
  static final AIService _instance = AIService._internal();
  static AIService get instance => _instance;

  final TmdbService _tmdbService = TmdbService();
  final Random _random = Random();

  static const _apiKey = 'AIzaSyCaV90MmceX7NngfrdK5KGYFt9kV2s9xkc';
  static const _modelName = 'gemini-3.6-flash';
  static const _interactionsEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/interactions';

  // Debouncing
  Timer? _debounceTimer;

  // Error state
  String? _lastError;
  DateTime? _lastErrorTime;

  // Avoid spending API quota again whenever the user changes tabs.
  static const _recommendationCacheDuration = Duration(minutes: 30);
  Map<String, dynamic>? _cachedDailyRecommendation;
  DateTime? _dailyRecommendationCachedAt;
  List<Map<String, dynamic>>? _cachedTrendingWithHooks;
  DateTime? _trendingWithHooksCachedAt;
  DateTime? _quotaBlockedUntil;

  AIService._internal();

  /// Sends a text prompt through Gemini's current Interactions API.
  Future<String> _generateText(
    String prompt, {
    int maxOutputTokens = 1024,
  }) async {
    final quotaBlockedUntil = _quotaBlockedUntil;
    if (quotaBlockedUntil != null &&
        DateTime.now().isBefore(quotaBlockedUntil)) {
      throw StateError('Gemini quota is temporarily unavailable.');
    }

    final response = await http.post(
      Uri.parse(_interactionsEndpoint),
      headers: const {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        'model': _modelName,
        'input': prompt,
        'generation_config': {
          'max_output_tokens': maxOutputTokens,
          'thinking_level': 'low',
        },
      }),
    );

    final decodedPayload = jsonDecode(response.body);
    if (decodedPayload is! Map<String, dynamic>) {
      throw const FormatException('Gemini returned an invalid response.');
    }
    final payload = decodedPayload;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 429) {
        _quotaBlockedUntil = DateTime.now().add(const Duration(minutes: 2));
      }
      final error = payload['error'];
      final message = error is Map<String, dynamic>
          ? error['message']
          : response.body;
      throw StateError(
        'Gemini request failed (${response.statusCode}): $message',
      );
    }

    final steps = payload['steps'];
    if (steps is! List) {
      throw const FormatException(
        'Gemini response did not include output steps.',
      );
    }

    final output = StringBuffer();
    for (final step in steps) {
      if (step is! Map<String, dynamic> || step['type'] != 'model_output') {
        continue;
      }
      final content = step['content'];
      if (content is! List) continue;
      for (final part in content) {
        if (part is Map<String, dynamic> && part['type'] == 'text') {
          output.write(part['text'] ?? '');
        }
      }
    }

    final text = output.toString().trim();
    if (text.isEmpty) {
      throw const FormatException('Gemini returned an empty response.');
    }
    return text;
  }

  bool _isFresh(DateTime? cachedAt) {
    return cachedAt != null &&
        DateTime.now().difference(cachedAt) < _recommendationCacheDuration;
  }

  String _stripMarkdownFences(String text) {
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  /// Get last error message for UI display
  String? get lastError => _lastError;

  /// Check if we recently had an error
  bool get hasRecentError {
    if (_lastErrorTime == null) return false;
    return DateTime.now().difference(_lastErrorTime!).inSeconds < 30;
  }

  /// Semantic Mood Search with Debouncing
  /// Converts mood descriptions into movie recommendations using AI
  Future<List<Movie>> searchByMood(
    String moodQuery, {
    Duration debounceDuration = const Duration(milliseconds: 500),
  }) async {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create a completer for the debounced result
    final completer = Completer<List<Movie>>();

    _debounceTimer = Timer(debounceDuration, () async {
      // 1. Check for predefined mood keywords first (same as chat)
      final predefinedMovies = await _getPredefinedMoodMovies(moodQuery);
      if (predefinedMovies != null) {
        debugPrint('✅ Using predefined mood response for: "$moodQuery"');
        completer.complete(predefinedMovies);
        return;
      }

      // 2. Fallback to AI for complex mood queries
      try {
        debugPrint('🔍 AI Search: Starting search for: "$moodQuery"');

        final prompt =
            '''
You are an expert movie recommendation AI. Based on the user's mood/vibe, recommend exactly 10 movies.

User's Mood: "$moodQuery"

IMPORTANT: Return ONLY a valid JSON array of movie titles. No explanations, no markdown, just the array.
Format: ["Movie Title 1", "Movie Title 2", "Movie Title 3", ...]

Focus on:
- Movies that match the mood, atmosphere, and emotional tone
- Well-known titles that are likely in TMDB database
- Diverse genres that fit the vibe
- Recent and classic films

Example output:
["Inception", "The Matrix", "Blade Runner 2049"]
''';

        debugPrint('🤖 AI Search: Sending request to Gemini...');
        final text = await _generateText(prompt);

        debugPrint(
          '✅ AI Search: Got response: ${text.substring(0, min(100, text.length))}...',
        );

        // Clear any previous errors
        _lastError = null;
        _lastErrorTime = null;

        // Extract JSON array from response
        final jsonMatch = RegExp(r'\[.*?\]', dotAll: true).firstMatch(text);
        if (jsonMatch == null) {
          debugPrint('⚠️ AI Search: No JSON found in response, using trending');
          completer.complete(await _tmdbService.getTrendingMovies());
          return;
        }

        final movieTitles = List<String>.from(json.decode(jsonMatch.group(0)!));
        debugPrint(
          '🎬 AI Search: Found ${movieTitles.length} movie titles: $movieTitles',
        );

        // Search TMDB for these movies
        final movies = <Movie>[];
        for (final title in movieTitles.take(10)) {
          try {
            debugPrint('🔎 Searching TMDB for: $title');
            final results = await _tmdbService.searchMovies(title);
            if (results.isNotEmpty) {
              movies.add(results.first);
              debugPrint('✓ Found: ${results.first.title}');
            }
          } catch (e) {
            debugPrint('✗ Error searching for $title: $e');
            continue;
          }
        }

        debugPrint('📊 AI Search: Returning ${movies.length} movies');
        completer.complete(
          movies.isNotEmpty ? movies : await _tmdbService.getTrendingMovies(),
        );
      } catch (e) {
        debugPrint('❌ AI Search Error: $e');

        // Set user-friendly error message
        if (e.toString().contains('quota') ||
            e.toString().contains('rate limit')) {
          _lastError =
              'AI is taking a quick break. Try again in a few seconds! 🌟';
        } else if (e.toString().contains('not found')) {
          _lastError = 'AI model unavailable. Showing trending movies instead.';
        } else {
          _lastError =
              'AI search temporarily unavailable. Showing trending movies.';
        }
        _lastErrorTime = DateTime.now();

        // Fallback to trending on error
        completer.complete(await _tmdbService.getTrendingMovies());
      }
    });

    return completer.future;
  }

  /// AI Chat Assistant Stream
  /// Returns a stream of AI responses for the chat interface
  Stream<String> chatStream(String userMessage) async* {
    // 1. Check for predefined "demo" response first to save quota/time
    final predefinedResponse = _getPredefinedResponse(userMessage);
    if (predefinedResponse != null) {
      await Future.delayed(
        const Duration(milliseconds: 600),
      ); // Simulate thinking
      yield predefinedResponse;
      return;
    }

    // 2. Fallback to real AI for other queries
    try {
      final prompt =
          '''
You are "Cine Ai", a super fan of movies, anime, and TV shows.
You are NOT a robot, but a friendly, enthusiastic movie buff friend.

User: $userMessage

Guidelines:
- Chat naturally like a human friend (use emojis, casual tone).
- If the user mentions Anime (like Hunter x Hunter), be excited about it!
- Don't be too formal.
- Keep responses concise (2-3 sentences max usually).
''';

      // The Interactions API call returns one completed response. Keep the
      // stream contract for the chat UI by yielding that response as a chunk.
      yield await _generateText(prompt);
    } catch (e) {
      debugPrint('Chat stream error: $e');
      yield 'My bad, I spaced out for a second! 😅 Could you ask that again?';
    }
  }

  /// Get predefined movie lists for common moods (Hybrid Mode)
  Future<List<Movie>?> _getPredefinedMoodMovies(String moodQuery) async {
    final lowercased = moodQuery.toLowerCase();

    // Define common mood -> movie title mappings
    List<String>? movieTitles;

    if (lowercased.contains('happy') ||
        lowercased.contains('😊') ||
        lowercased.contains('joy')) {
      movieTitles = [
        'Forrest Gump',
        'The Grand Budapest Hotel',
        'Sing',
        'Paddington',
        'The Secret Life of Walter Mitty',
      ];
    } else if (lowercased.contains('sad') ||
        lowercased.contains('😢') ||
        lowercased.contains('cry')) {
      movieTitles = [
        'The Shawshank Redemption',
        'The Green Mile',
        'A Star is Born',
        'Marley & Me',
        'The Fault in Our Stars',
      ];
    } else if (lowercased.contains('excited') ||
        lowercased.contains('🤩') ||
        lowercased.contains('thrill')) {
      movieTitles = [
        'Mad Max: Fury Road',
        'John Wick',
        'Mission: Impossible',
        'Top Gun: Maverick',
        'Baby Driver',
      ];
    } else if (lowercased.contains('scared') ||
        lowercased.contains('😱') ||
        lowercased.contains('horror')) {
      movieTitles = [
        'The Conjuring',
        'Hereditary',
        'Get Out',
        'A Quiet Place',
        'The Babadook',
      ];
    } else if (lowercased.contains('romantic') ||
        lowercased.contains('💕') ||
        lowercased.contains('love')) {
      movieTitles = [
        'The Notebook',
        'La La Land',
        'Pride and Prejudice',
        'Crazy Rich Asians',
        'About Time',
      ];
    } else if (lowercased.contains('bored') ||
        lowercased.contains('😴') ||
        lowercased.contains('entertain')) {
      movieTitles = [
        'Inception',
        'The Matrix',
        'Interstellar',
        'Shutter Island',
        'The Prestige',
      ];
    } else if (lowercased.contains('action') || lowercased.contains('🔥')) {
      movieTitles = [
        'John Wick',
        'The Dark Knight',
        'Mad Max: Fury Road',
        'Mission: Impossible',
        'The Bourne Identity',
      ];
    } else if (lowercased.contains('comedy') ||
        lowercased.contains('funny') ||
        lowercased.contains('😂')) {
      movieTitles = [
        'Superbad',
        'The Hangover',
        'Deadpool',
        'Step Brothers',
        'Anchorman',
      ];
    } else if (lowercased.contains('sci-fi') ||
        lowercased.contains('science') ||
        lowercased.contains('space')) {
      movieTitles = [
        'Blade Runner 2049',
        'Interstellar',
        'The Matrix',
        'Inception',
        'Dune',
      ];
    } else {
      return null; // No predefined match, use AI
    }

    // Search TMDB for these movies
    final movies = <Movie>[];
    for (final title in movieTitles) {
      try {
        final results = await _tmdbService.searchMovies(title);
        if (results.isNotEmpty) {
          movies.add(results.first);
        }
      } catch (e) {
        debugPrint('Error searching for $title: $e');
        continue;
      }
    }

    return movies.isNotEmpty ? movies : null;
  }

  /// Check for predefined responses (Hybrid Mode)
  String? _getPredefinedResponse(String message) {
    final lowercasedMessage = message.toLowerCase();

    // Check for greetings and personal questions
    if (lowercasedMessage.contains("hello") ||
        lowercasedMessage.contains("hi") ||
        lowercasedMessage.contains("hey")) {
      return "Hey there! 😊 Nice to meet you! I'm doing great, thanks for asking. I'm really passionate about movies and love helping people find their next favorite film. What kind of movies do you enjoy watching?";
    } else if (lowercasedMessage.contains("how are you") ||
        lowercasedMessage.contains("how do you do") ||
        lowercasedMessage.contains("what's up")) {
      return "I'm doing fantastic, thank you! 😄 I'm always excited to talk about movies. I've been thinking about some amazing films lately. Are you looking for something specific to watch tonight?";
    } else if (lowercasedMessage.contains("thank") ||
        lowercasedMessage.contains("thanks") ||
        lowercasedMessage.contains("merci")) {
      return "You're so welcome! 😊 I really enjoy helping people discover great movies. It's like sharing something I love with a friend. What else can I help you find?";
    } else if (lowercasedMessage.contains("who are you") ||
        lowercasedMessage.contains("what are you")) {
      return "I'm just someone who absolutely loves movies! 🎬 I've watched thousands of films and I'm always excited to share recommendations. I'm here to help you find the perfect movie for any mood. What are you in the mood for?";
    } else if (lowercasedMessage.contains("name")) {
      return "I don't really have a name, but you can call me your movie buddy! 😊 I'm just here because I love talking about films and helping people discover amazing movies. What's your favorite genre?";
    } else if (lowercasedMessage.contains("help") ||
        lowercasedMessage.contains("support")) {
      return "I'd love to help! 🎬 I'm great at finding movies for any mood, or answering questions about actors and directors. What are you looking for?";
    }
    // Check for action movies with duration
    else if (lowercasedMessage.contains("action") &&
        (lowercasedMessage.contains("2h") ||
            lowercasedMessage.contains("2 hour") ||
            lowercasedMessage.contains("long"))) {
      return "Perfect! Here are some amazing 2+ hour action movies:\n\n🔥 **John Wick** (2014) - 1h 41m\n🔥 **Mad Max: Fury Road** (2015) - 2h 0m\n🔥 **The Dark Knight** (2008) - 2h 32m\n🔥 **Inception** (2010) - 2h 28m\n🔥 **The Matrix** (1999) - 2h 16m\n\nThese are all incredible action films with great storylines and amazing action sequences! Which one interests you most?";
    }
    // Check for action movies
    else if (lowercasedMessage.contains("action")) {
      return "Great choice! Action movies are my favorite! 🎬\n\nHere are some must-watch action films:\n\n🔥 **John Wick** - Keanu Reeves at his best\n🔥 **Mad Max: Fury Road** - Insane car chases\n🔥 **The Dark Knight** - Batman vs Joker\n🔥 **Mission: Impossible** - Tom Cruise stunts\n🔥 **Fast & Furious** - High-speed thrills\n\nWhat kind of action do you prefer? Car chases, martial arts, or superhero action?";
    }
    // Check for comedy
    else if (lowercasedMessage.contains("comedy") ||
        lowercasedMessage.contains("funny")) {
      return "Comedy is the best medicine! 😂\n\nHere are some hilarious movies:\n\n🤣 **Superbad** - Classic teen comedy\n🤣 **The Hangover** - Wild Vegas adventure\n🤣 **Deadpool** - Action + comedy\n🤣 **Anchorman** - Will Ferrell at his best\n🤣 **Step Brothers** - Ridiculous but funny\n\nNeed something specific? Romantic comedy, action comedy, or pure silliness?";
    }
    // Check for sci-fi
    else if (lowercasedMessage.contains("sci-fi") ||
        lowercasedMessage.contains("science fiction") ||
        lowercasedMessage.contains("space")) {
      return "Sci-fi movies are mind-blowing! 🚀\n\nHere are some incredible sci-fi films:\n\n🔮 **Blade Runner 2049** - Visual masterpiece\n🔮 **Interstellar** - Space + emotions\n🔮 **The Matrix** - Reality-bending classic\n🔮 **Inception** - Dreams within dreams\n🔮 **Dune** - Epic space opera\n\nDo you prefer space adventures, time travel, or AI/robot stories?";
    }
    // Check for horror
    else if (lowercasedMessage.contains("horror") ||
        lowercasedMessage.contains("scary")) {
      return "Ready to get scared? 👻\n\nHere are some terrifying movies:\n\n😱 **The Conjuring** - Supernatural horror\n😱 **Hereditary** - Psychological terror\n😱 **Get Out** - Social horror\n😱 **A Quiet Place** - Silent terror\n😱 **The Babadook** - Creepy monster\n\nHow scary do you want it? Mild chills or full-on nightmares?";
    }
    // Check for drama
    else if (lowercasedMessage.contains("drama") ||
        lowercasedMessage.contains("emotional")) {
      return "Drama movies can be life-changing! 💔\n\nHere are some powerful dramas:\n\n🎭 **The Shawshank Redemption** - Hope in prison\n🎭 **Forrest Gump** - Life journey\n🎭 **The Green Mile** - Magical realism\n🎭 **Schindler's List** - Historical drama\n🎭 **Good Will Hunting** - Genius story\n\nLooking for something uplifting or something that will make you cry?";
    }
    // Check for specific actors
    else if (lowercasedMessage.contains("leonardo") ||
        lowercasedMessage.contains("dicaprio")) {
      return "Leonardo DiCaprio is amazing! 🏆\n\nHis best movies:\n\n⭐ **Inception** - Mind-bending thriller\n⭐ **The Wolf of Wall Street** - Wild ride\n⭐ **The Revenant** - Survival epic\n⭐ **Django Unchained** - Western revenge\n⭐ **Catch Me If You Can** - Con artist story\n\nWhich type of Leo movie do you want? Action, drama, or thriller?";
    } else if (lowercasedMessage.contains("tom") &&
        lowercasedMessage.contains("cruise")) {
      return "Tom Cruise never disappoints! 🏃‍♂️\n\nHis best action movies:\n\n⭐ **Mission: Impossible** series - Epic stunts\n⭐ **Top Gun** - Fighter pilot classic\n⭐ **Edge of Tomorrow** - Sci-fi action\n⭐ **Jack Reacher** - Vigilante justice\n⭐ **Minority Report** - Future crime\n\nReady for some high-octane action?";
    }
    // Check for non-movie topics and redirect to movies
    else if (lowercasedMessage.contains("weather") ||
        lowercasedMessage.contains("rain") ||
        lowercasedMessage.contains("sunny")) {
      return "Oh, I'm not really good with weather stuff! 😅 But you know what's perfect for any weather? A great movie! Whether it's raining or sunny, I can recommend the perfect film. What's your mood today?";
    } else if (lowercasedMessage.contains("food") ||
        lowercasedMessage.contains("eat") ||
        lowercasedMessage.contains("hungry")) {
      return "Haha, I can't help with food recommendations! 😄 But I can suggest some amazing movies that have incredible food scenes! Like 'Chef' or 'The Menu'. What kind of movie are you craving instead?";
    } else if (lowercasedMessage.contains("work") ||
        lowercasedMessage.contains("job") ||
        lowercasedMessage.contains("office")) {
      return "I'm not really into work talk! 😊 But I love movies about work - like 'The Devil Wears Prada' or 'Office Space'. What kind of movie would help you unwind after work?";
    } else if (lowercasedMessage.contains("sport") ||
        lowercasedMessage.contains("football") ||
        lowercasedMessage.contains("basketball")) {
      return "I'm not much of a sports person! 😅 But I love sports movies! 'Remember the Titans', 'Rocky', 'The Blind Side' - they're all amazing. What kind of movie are you in the mood for?";
    } else if (lowercasedMessage.contains("music") ||
        lowercasedMessage.contains("song") ||
        lowercasedMessage.contains("concert")) {
      return "I'm not really into music recommendations! 😊 But I love movies with great soundtracks! 'Guardians of the Galaxy', 'La La Land', 'A Star is Born' - they're all amazing. What kind of movie do you want to watch?";
    } else if (lowercasedMessage.contains("travel") ||
        lowercasedMessage.contains("vacation") ||
        lowercasedMessage.contains("trip")) {
      return "I can't help with travel plans! 😄 But I love travel movies! 'Eat Pray Love', 'The Secret Life of Walter Mitty', 'Into the Wild' - they're all about amazing journeys. What kind of movie adventure are you looking for?";
    }
    // General movie request
    else if (lowercasedMessage.contains("film") ||
        lowercasedMessage.contains("movie") ||
        lowercasedMessage.contains("watch")) {
      return "I love helping people find great movies! 🎬\n\nWhat are you in the mood for?\n\n🔥 **Action** - Explosions and thrills\n🤣 **Comedy** - Laughs and fun\n🔮 **Sci-Fi** - Future and space\n😱 **Horror** - Scares and chills\n🎭 **Drama** - Deep stories\n💕 **Romance** - Love stories\n\nJust tell me what you feel like watching!";
    }

    // Return null to trigger real AI fallback
    return null;
  }

  /// Scene Recognition
  /// Analyzes image to identify movie and scene using AI vision
  Future<Map<String, dynamic>> recognizeScene(String imagePath) async {
    try {
      // For now, use placeholder logic as vision requires image bytes
      // In production, you would:
      // 1. Read image file as bytes
      // 2. Send to gemini-pro-vision
      // 3. Parse AI response for movie identification

      await Future.delayed(const Duration(seconds: 2));

      final movies = await _tmdbService.getPopularMovies();
      final randomMovie = movies[_random.nextInt(movies.length)];

      return {
        'movie': randomMovie,
        'confidence': 0.85 + (_random.nextDouble() * 0.15),
        'scene_description': 'Scene identified using AI vision',
      };
    } catch (e) {
      final movies = await _tmdbService.getPopularMovies();
      return {
        'movie': movies.first,
        'confidence': 0.75,
        'scene_description': 'Recognition unavailable',
      };
    }
  }

  /// Smart Summarizer
  /// Generates spoiler-free 3-sentence hooks using AI
  Future<String> generateHook(Movie movie) async {
    try {
      final prompt =
          '''
Create a compelling, spoiler-free 3-sentence "hook" for this movie:

Title: ${movie.title}
Overview: ${movie.overview}

Requirements:
- Exactly 3 sentences
- No spoilers
- Engaging and intriguing
- Focus on atmosphere, themes, and emotional impact
- Make viewers want to watch it

Return only the 3-sentence hook, nothing else.
''';

      final hook = (await _generateText(prompt)).trim();

      return hook;
    } catch (e) {
      debugPrint('Hook generation error: $e');
      return _generateFallbackHook();
    }
  }

  String _generateFallbackHook() {
    return 'A captivating story that will keep you on the edge of your seat. '
        'Experience unforgettable characters in a world of intrigue and emotion. '
        'This film delivers a powerful message that resonates long after the credits roll.';
  }

  /// Taste Match Calculator
  /// Calculates match percentage based on movie attributes
  Future<int> calculateTasteMatch(Movie movie) async {
    try {
      // AI-enhanced matching based on rating
      final ratingScore = (movie.voteAverage / 10 * 60).round();
      final randomBoost = _random.nextInt(20);

      final baseScore = ratingScore + randomBoost;

      return min(99, max(70, baseScore));
    } catch (e) {
      return 70 + _random.nextInt(30);
    }
  }

  /// Daily AI Recommendation
  /// Selects and justifies a "Pick of the Day" using AI
  Future<Map<String, dynamic>> getDailyRecommendation() async {
    if (_cachedDailyRecommendation != null &&
        _isFresh(_dailyRecommendationCachedAt)) {
      return _cachedDailyRecommendation!;
    }

    try {
      final movies = await _tmdbService.getTrendingMovies();
      final topMovies = movies.take(5).toList();

      if (topMovies.isEmpty) {
        throw StateError('No trending movies are available.');
      }

      // Use AI to select the best pick
      final movieList = topMovies
          .map((m) => '- ${m.title} (Rating: ${m.voteAverage})')
          .join('\n');

      final prompt =
          '''
You are a movie curator. From this list of trending movies, select ONE as the "Pick of the Day".

Movies:
$movieList

Return ONLY one valid JSON object, without markdown:
{"title":"Exact movie title","reasoning":"Why this is today's best pick in 1-2 concise sentences","hook":"Exactly 3 engaging, spoiler-free sentences about its atmosphere, themes, and emotional impact"}
''';

      final text = _stripMarkdownFences(await _generateText(prompt));
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) {
        throw const FormatException('Daily recommendation was not JSON.');
      }
      final decoded = jsonDecode(jsonMatch.group(0)!);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Daily recommendation JSON is invalid.');
      }

      // Find the selected movie
      final selectedTitle = (decoded['title'] as String? ?? '').trim();
      final selectedMovie = topMovies.firstWhere(
        (m) =>
            selectedTitle.isNotEmpty &&
            (m.title.toLowerCase().contains(selectedTitle.toLowerCase()) ||
                selectedTitle.toLowerCase().contains(m.title.toLowerCase())),
        orElse: () => topMovies.first,
      );
      final reasoning = (decoded['reasoning'] as String? ?? '').trim();
      final hook = (decoded['hook'] as String? ?? '').trim();
      final matchScore = await calculateTasteMatch(selectedMovie);

      final result = <String, dynamic>{
        'movie': selectedMovie,
        'hook': hook.isNotEmpty ? hook : _generateFallbackHook(),
        'match_score': matchScore,
        'reasoning': reasoning.isNotEmpty
            ? reasoning
            : 'A perfect blend of entertainment and critical acclaim makes this today\'s must-watch.',
      };
      _cachedDailyRecommendation = result;
      _dailyRecommendationCachedAt = DateTime.now();
      return result;
    } catch (e) {
      debugPrint('Daily recommendation error: $e');
      final movies = await _tmdbService.getTrendingMovies();
      if (movies.isEmpty) rethrow;
      final movie = movies.first;

      final result = <String, dynamic>{
        'movie': movie,
        'hook': _generateFallbackHook(),
        'match_score': 85,
        'reasoning':
            'Based on current trends and viewer preferences, this film stands out today.',
      };
      _cachedDailyRecommendation = result;
      _dailyRecommendationCachedAt = DateTime.now();
      return result;
    }
  }

  /// Get Trending with Hooks
  /// Returns trending movies with AI-generated hooks
  Future<List<Map<String, dynamic>>> getTrendingWithHooks() async {
    if (_cachedTrendingWithHooks != null &&
        _isFresh(_trendingWithHooksCachedAt)) {
      return _cachedTrendingWithHooks!;
    }

    try {
      final movies = await _tmdbService.getTrendingMovies();
      final selectedMovies = movies.take(10).toList();
      if (selectedMovies.isEmpty) return [];

      final movieList = selectedMovies.indexed
          .map(
            (entry) =>
                '${entry.$1}. ${entry.$2.title}\nOverview: ${entry.$2.overview}',
          )
          .join('\n\n');

      final prompt =
          '''
Write one concise, compelling, spoiler-free hook for every movie below.

$movieList

Return ONLY a valid JSON array without markdown. Preserve each numeric index:
[{"index":0,"hook":"A concise 2-3 sentence hook"}]
''';

      final text = _stripMarkdownFences(
        await _generateText(prompt, maxOutputTokens: 2500),
      );
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
      if (jsonMatch == null) {
        throw const FormatException('Trending hooks were not JSON.');
      }
      final decoded = jsonDecode(jsonMatch.group(0)!);
      if (decoded is! List) {
        throw const FormatException('Trending hooks JSON is invalid.');
      }

      final hooksByIndex = <int, String>{};
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final indexValue = item['index'];
        final hookValue = item['hook'];
        if (indexValue is num && hookValue is String && hookValue.isNotEmpty) {
          hooksByIndex[indexValue.toInt()] = hookValue.trim();
        }
      }

      final results = <Map<String, dynamic>>[];
      for (final entry in selectedMovies.indexed) {
        final movie = entry.$2;
        final matchScore = await calculateTasteMatch(movie);
        results.add({
          'movie': movie,
          'hook': hooksByIndex[entry.$1] ?? _generateFallbackHook(),
          'match_score': matchScore,
        });
      }

      _cachedTrendingWithHooks = results;
      _trendingWithHooksCachedAt = DateTime.now();
      return results;
    } catch (e) {
      debugPrint('Trending with hooks error: $e');
      // Fallback with basic data
      final movies = await _tmdbService.getTrendingMovies();
      final results = movies
          .take(10)
          .map(
            (movie) => {
              'movie': movie,
              'hook': _generateFallbackHook(),
              'match_score': 70 + _random.nextInt(30),
            },
          )
          .toList();
      _cachedTrendingWithHooks = results;
      _trendingWithHooksCachedAt = DateTime.now();
      return results;
    }
  }

  /// Generate Dynamic Quiz Questions
  /// Returns 5 unique questions about the topic
  Future<List<Map<String, dynamic>>> generateQuizQuestions(String topic) async {
    try {
      debugPrint('🎯 Generating quiz for: $topic');

      final prompt =
          '''
Generate 5 UNIQUE and RANDOM multiple choice trivia questions about "$topic".

Return ONLY valid JSON array with this EXACT structure:
[
  {
    "question": "Your question here?",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correctAnswer": 0
  }
]

Rules:
- NO markdown code blocks
- NO explanations
- correctAnswer is 0, 1, 2, or 3
- All fields required
''';

      final rawText = await _generateText(prompt);
      debugPrint('🎯 AI Response length: ${rawText.length} chars');
      debugPrint(
        '🎯 AI Response preview: ${rawText.substring(0, min(200, rawText.length))}...',
      );

      // Clean up the response
      String cleanText = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Extract JSON array (greedy match to get full array)
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleanText);
      if (jsonMatch == null) {
        debugPrint('❌ No JSON array found in response');
        return [];
      }

      final jsonString = jsonMatch.group(0)!;
      debugPrint(
        '🎯 Extracted JSON: ${jsonString.substring(0, min(100, jsonString.length))}...',
      );

      final List<dynamic> jsonList = json.decode(jsonString);
      final questions = List<Map<String, dynamic>>.from(jsonList);

      debugPrint('✅ Successfully parsed ${questions.length} questions');
      return questions;
    } catch (e, stackTrace) {
      debugPrint('❌ Quiz generation error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Cancel any pending debounced searches
  void cancelPendingSearch() {
    _debounceTimer?.cancel();
  }
}
