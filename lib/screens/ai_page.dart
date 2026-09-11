import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie_model.dart';
import '../services/ai_service.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import 'movie_details_page.dart';
import 'ai_chat_screen.dart';
import 'ai_planner_screen.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _searchController = TextEditingController();
  final AIService _aiService = AIService.instance;

  Map<String, dynamic>? _dailyPick;
  List<Map<String, dynamic>> _trendingWithHooks = [];
  List<Movie> _searchResults = [];

  bool _isLoadingDaily = true;
  bool _isLoadingTrending = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadDailyRecommendation();
    _loadTrendingWithHooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyRecommendation() async {
    setState(() => _isLoadingDaily = true);
    try {
      final daily = await _aiService.getDailyRecommendation();
      setState(() {
        _dailyPick = daily;
        _isLoadingDaily = false;
      });
    } catch (e) {
      setState(() => _isLoadingDaily = false);
    }
  }

  Future<void> _loadTrendingWithHooks() async {
    setState(() => _isLoadingTrending = true);
    try {
      final trending = await _aiService.getTrendingWithHooks();
      setState(() {
        _trendingWithHooks = trending;
        _isLoadingTrending = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _searchByMood(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    // Debouncing is handled in AIService
    final results = await _aiService.searchByMood(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF060609),
      child: Stack(
        children: [
          const _AiAmbientBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Editorial header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 1,
                              color: const Color(0xFFB89B5E),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'CINEBY  /  CURATED INTELLIGENCE',
                              style: TextStyle(
                                color: Color(0xFFB89B5E),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.7,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your next\nobsession.',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 38,
                            height: 0.95,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Thoughtful recommendations, tuned to your mood.',
                          style: TextStyle(
                            color: CupertinoColors.white.withValues(
                              alpha: 0.58,
                            ),
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            title: 'Ask Cine AI',
                            subtitle: 'Your film concierge',
                            icon: CupertinoIcons.sparkles,
                            accent: const Color(0xFFAC8CFF),
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const AIChatScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            title: 'Plan tonight',
                            subtitle: 'Build a perfect queue',
                            icon: CupertinoIcons.calendar,
                            accent: const Color(0xFFE7A86D),
                            onTap: () => Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const AIPlannerScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Daily AI Recommendation
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 38),
                        _buildSectionHeading(
                          overline: 'THE DAILY EDIT',
                          title: 'Pick of the day',
                        ),
                        const SizedBox(height: 14),
                        _isLoadingDaily
                            ? _buildDailyPickSkeleton()
                            : _buildDailyPickCard(),
                      ],
                    ),
                  ),
                ),

                // Semantic Mood Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 38, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeading(
                          overline: 'DISCOVER BY FEELING',
                          title: 'Set the mood',
                        ),
                        const SizedBox(height: 14),
                        _buildMoodSearchField(),
                        const SizedBox(height: 12),
                        // Error message
                        if (_aiService.hasRecentError &&
                            _aiService.lastError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.sunsetOrange.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.sunsetOrange.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.info_circle,
                                    color: AppTheme.sunsetOrange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _aiService.lastError!,
                                      style: const TextStyle(
                                        color: AppTheme.sunsetOrange,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _buildMoodGrid(), // Replaced chips with grid
                      ],
                    ),
                  ),
                ),

                // Search Results
                if (_searchResults.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._searchResults
                              .take(5)
                              .map(
                                (movie) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildSearchResultCard(movie),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),

                // Smart Summarizer - Trending
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeading(
                          overline: 'CURATED FOR YOU',
                          title: 'Beyond the trailer',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Trending movies with spoiler-free hooks',
                          style: TextStyle(
                            color: CupertinoColors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 320,
                    child: _isLoadingTrending
                        ? _buildTrendingSkeletonList()
                        : _buildTrendingList(),
                  ),
                ),

                // Bottom Padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String overline,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overline,
          style: TextStyle(
            color: CupertinoColors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.45,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPickCard() {
    if (_dailyPick == null) return const SizedBox();

    final Movie movie = _dailyPick!['movie'];
    final String hook = _dailyPick!['hook'];
    final int matchScore = _dailyPick!['match_score'];
    final String reasoning = _dailyPick!['reasoning'];

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => MovieDetailsPage(movieId: movie.id),
          ),
        );
      },
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1C1731), const Color(0xFF100F1D)],
          ),
          border: Border.all(
            color: const Color(0xFFB89B5E).withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C5CC4).withValues(alpha: 0.15),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 108,
                  height: 162,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: const Color(0xFF29253C)),
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB89B5E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '$matchScore% MATCH',
                          style: const TextStyle(
                            color: Color(0xFFD7C18B),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    // Hook
                    Text(
                      hook,
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.62),
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Reasoning
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.sparkles,
                            color: Color(0xFFD7C18B),
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reasoning,
                              style: TextStyle(
                                color: CupertinoColors.white.withValues(
                                  alpha: 0.52,
                                ),
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyPickSkeleton() {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 108,
            height: 162,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonLine(width: 70, height: 8),
                const SizedBox(height: 16),
                _buildSkeletonLine(width: 150, height: 22),
                const SizedBox(height: 12),
                _buildSkeletonLine(width: double.infinity, height: 10),
                const SizedBox(height: 8),
                _buildSkeletonLine(width: 120, height: 10),
                const Spacer(),
                _buildSkeletonLine(width: double.infinity, height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }

  Widget _buildMoodSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF9A7BFF).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Color(0xFFB8A2FF),
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              placeholder: 'Describe your mood or vibe...',
              placeholderStyle: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
              ),
              decoration: null,
              onSubmitted: _searchByMood,
            ),
          ),
          if (_isSearching)
            const CupertinoActivityIndicator(
              radius: 10,
              color: AppTheme.vibrantPurple,
            )
          else
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _searchByMood(_searchController.text),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFB89B5E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.search,
                  color: Color(0xFF17130D),
                  size: 17,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 144,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.11),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accent, size: 21),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.95),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.43),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodGrid() {
    final moods = [
      {'name': 'Happy', 'emoji': '😊', 'color': const Color(0xFFFFD700)},
      {'name': 'Sad', 'emoji': '😢', 'color': const Color(0xFF4A90E2)},
      {'name': 'Excited', 'emoji': '🤩', 'color': const Color(0xFFFF6B6B)},
      {'name': 'Scared', 'emoji': '😱', 'color': const Color(0xFF6C5CE7)},
      {'name': 'Romantic', 'emoji': '💕', 'color': const Color(0xFFFF9A9E)},
      {'name': 'Bored', 'emoji': '😴', 'color': const Color(0xFF74B9FF)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: moods.length,
      itemBuilder: (context, index) {
        final mood = moods[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final query = '${mood['name']} ${mood['emoji']} movie';
            _searchController.text = query;
            _searchByMood(query);
          },
          child: Container(
            decoration: BoxDecoration(
              color: (mood['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (mood['color'] as Color).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mood['emoji'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  mood['name'] as String,
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultCard(Movie movie) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => MovieDetailsPage(movieId: movie.id),
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: movie.posterUrl,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: AppTheme.sunsetOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _trendingWithHooks.length,
      itemBuilder: (context, index) {
        final item = _trendingWithHooks[index];
        final Movie movie = item['movie'];
        final String hook = item['hook'];
        final int matchScore = item['match_score'];

        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildTrendingCard(movie, hook, matchScore),
        );
      },
    );
  }

  Widget _buildTrendingCard(Movie movie, String hook, int matchScore) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => MovieDetailsPage(movieId: movie.id),
          ),
        );
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster with Match Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: movie.posterUrl,
                    width: 260,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.neonGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.heart_fill,
                          color: AppTheme.neonGreen,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$matchScore%',
                          style: const TextStyle(
                            color: AppTheme.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hook,
                    style: TextStyle(
                      color: CupertinoColors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSkeletonList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AiAmbientBackground extends StatelessWidget {
  const _AiAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -180,
              right: -120,
              child: Container(
                width: 400,
                height: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x262D245B), Color(0x00060609)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 430,
              left: -180,
              child: Container(
                width: 340,
                height: 340,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x161B6B68), Color(0x00060609)],
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
