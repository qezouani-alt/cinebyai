import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AIPlannerScreen extends StatefulWidget {
  const AIPlannerScreen({super.key});

  @override
  State<AIPlannerScreen> createState() => _AIPlannerScreenState();
}

class _AIPlannerScreenState extends State<AIPlannerScreen> {
  final _timeController = TextEditingController();
  final _timeFocusNode = FocusNode();
  final _resultKey = GlobalKey();

  String? _selectedGenre;
  _PlannerPick? _suggestion;
  String? _validationMessage;
  int _suggestionIndex = 0;

  static const _quickDurations = [60, 90, 120, 150, 180];
  static const _genres = [
    _Genre('Action', Icons.bolt_rounded, Color(0xFFFF766C)),
    _Genre('Comedy', Icons.sentiment_very_satisfied_rounded, Color(0xFFFFC96A)),
    _Genre('Drama', Icons.theater_comedy_rounded, Color(0xFFA88BFF)),
    _Genre('Sci-Fi', Icons.rocket_launch_rounded, Color(0xFF6DCBFF)),
    _Genre('Horror', Icons.nightlight_round, Color(0xFFFF8098)),
    _Genre('Thriller', Icons.visibility_rounded, Color(0xFF7EE0C2)),
    _Genre('Romance', Icons.favorite_rounded, Color(0xFFFF8BAD)),
  ];

  static const _picks = [
    _PlannerPick(
      title: 'The Menu',
      genre: 'Thriller',
      minutes: 107,
      accent: Color(0xFF7EE0C2),
      label: 'A razor-sharp evening',
      description:
          'Tense, stylish and deliciously unpredictable. A complete experience that never wastes a minute.',
    ),
    _PlannerPick(
      title: 'Palm Springs',
      genre: 'Comedy',
      minutes: 90,
      accent: Color(0xFFFFC96A),
      label: 'A bright escape',
      description:
          'Funny, romantic and effortlessly breezy. It is ideal when you want a memorable film without a heavy commitment.',
    ),
    _PlannerPick(
      title: 'Game Night',
      genre: 'Comedy',
      minutes: 100,
      accent: Color(0xFFFFC96A),
      label: 'A clever crowd-pleaser',
      description:
          'A sharp, fast-moving comedy with enough mystery to keep the whole room leaning in.',
    ),
    _PlannerPick(
      title: 'The Nice Guys',
      genre: 'Comedy',
      minutes: 116,
      accent: Color(0xFFFFC96A),
      label: 'A stylish laugh',
      description:
          'Smart, playful and packed with chemistry. A great choice for a more grown-up comic escape.',
    ),
    _PlannerPick(
      title: 'Ex Machina',
      genre: 'Sci-Fi',
      minutes: 108,
      accent: Color(0xFF6DCBFF),
      label: 'A precise mind-bender',
      description:
          'Sleek, intimate and quietly unsettling. Every scene builds toward a conversation you will keep thinking about.',
    ),
    _PlannerPick(
      title: 'Whiplash',
      genre: 'Drama',
      minutes: 107,
      accent: Color(0xFFA88BFF),
      label: 'Pure momentum',
      description:
          'An electrifying story of ambition and obsession, paced like a final performance.',
    ),
    _PlannerPick(
      title: 'The Farewell',
      genre: 'Drama',
      minutes: 100,
      accent: Color(0xFFA88BFF),
      label: 'Quietly unforgettable',
      description:
          'Tender, funny and beautifully observed—an intimate story that stays with you long after it ends.',
    ),
    _PlannerPick(
      title: 'Arrival',
      genre: 'Sci-Fi',
      minutes: 116,
      accent: Color(0xFF6DCBFF),
      label: 'A luminous mystery',
      description:
          'Thoughtful science fiction with real emotional weight and one of cinema’s most rewarding final acts.',
    ),
    _PlannerPick(
      title: 'Source Code',
      genre: 'Sci-Fi',
      minutes: 93,
      accent: Color(0xFF6DCBFF),
      label: 'A compact puzzle',
      description:
          'A tightly built, high-concept thriller that delivers a full adventure in a short window.',
    ),
    _PlannerPick(
      title: 'Mad Max: Fury Road',
      genre: 'Action',
      minutes: 120,
      accent: Color(0xFFFF766C),
      label: 'Maximum velocity',
      description:
          'A bold, visual rush with almost no downtime. This is the pick when your night needs energy.',
    ),
    _PlannerPick(
      title: 'Baby Driver',
      genre: 'Action',
      minutes: 113,
      accent: Color(0xFFFF766C),
      label: 'Velocity with style',
      description:
          'Music, motion and immaculate timing turn this action ride into a genuinely cool night in.',
    ),
    _PlannerPick(
      title: 'John Wick',
      genre: 'Action',
      minutes: 101,
      accent: Color(0xFFFF766C),
      label: 'Clean, focused action',
      description:
          'Lean storytelling and iconic set pieces make this a perfect choice when you want instant momentum.',
    ),
    _PlannerPick(
      title: 'The Invisible Man',
      genre: 'Horror',
      minutes: 124,
      accent: Color(0xFFFF8098),
      label: 'A polished chill',
      description:
          'Intelligent suspense with a strong emotional core. It earns every moment of its slow-burn tension.',
    ),
    _PlannerPick(
      title: 'Get Out',
      genre: 'Horror',
      minutes: 104,
      accent: Color(0xFFFF8098),
      label: 'Smart, unnerving suspense',
      description:
          'A brilliantly controlled thriller with humour, tension and an unforgettable point of view.',
    ),
    _PlannerPick(
      title: 'A Quiet Place',
      genre: 'Horror',
      minutes: 90,
      accent: Color(0xFFFF8098),
      label: 'A hush of tension',
      description:
          'Minimal dialogue, maximum tension. It makes every quiet minute feel electric.',
    ),
    _PlannerPick(
      title: 'About Time',
      genre: 'Romance',
      minutes: 123,
      accent: Color(0xFFFF8BAD),
      label: 'A warm afterglow',
      description:
          'Tender, funny and deeply human. A beautiful choice when you want to leave the evening lighter than you started.',
    ),
    _PlannerPick(
      title: 'Set It Up',
      genre: 'Romance',
      minutes: 105,
      accent: Color(0xFFFF8BAD),
      label: 'Easy chemistry',
      description:
          'A bright, modern romantic comedy with plenty of charm and a wonderfully easy pace.',
    ),
    _PlannerPick(
      title: 'Run Lola Run',
      genre: 'Thriller',
      minutes: 81,
      accent: Color(0xFF7EE0C2),
      label: 'A fast pulse',
      description:
          'A compact, exhilarating ride that turns a short window into a full cinematic event.',
    ),
    _PlannerPick(
      title: 'Searching',
      genre: 'Thriller',
      minutes: 102,
      accent: Color(0xFF7EE0C2),
      label: 'A digital-age mystery',
      description:
          'Inventive and gripping from the first scene, with a mystery that keeps tightening its hold.',
    ),
  ];

  @override
  void dispose() {
    _timeController.dispose();
    _timeFocusNode.dispose();
    super.dispose();
  }

  int? get _minutes => int.tryParse(_timeController.text.trim());

  void _selectDuration(int minutes) {
    HapticFeedback.selectionClick();
    setState(() {
      _timeController.text = '$minutes';
      _validationMessage = null;
      _suggestion = null;
      _suggestionIndex = 0;
    });
  }

  void _adjustDuration(int delta) {
    final currentMinutes = _minutes ?? 90;
    _selectDuration((currentMinutes + delta).clamp(45, 360));
  }

  void _findMovie({bool anotherSuggestion = false}) {
    FocusScope.of(context).unfocus();
    final minutes = _minutes;
    if (minutes == null || minutes < 45) {
      setState(() => _validationMessage = 'Choose at least 45 minutes.');
      _timeFocusNode.requestFocus();
      return;
    }
    if (_selectedGenre == null) {
      setState(() => _validationMessage = 'Choose a genre to shape the mood.');
      return;
    }

    final choices = _picks
        .where((pick) => pick.genre == _selectedGenre)
        .toList();
    choices.sort((first, next) {
      final firstFits = first.minutes <= minutes;
      final nextFits = next.minutes <= minutes;
      if (firstFits != nextFits) return firstFits ? -1 : 1;
      return (minutes - first.minutes).abs().compareTo(
        (minutes - next.minutes).abs(),
      );
    });
    final suggestionIndex = anotherSuggestion
        ? (_suggestionIndex + 1) % choices.length
        : 0;

    HapticFeedback.mediumImpact();
    setState(() {
      _suggestion = choices[suggestionIndex];
      _suggestionIndex = suggestionIndex;
      _validationMessage = null;
    });
    _scrollToSuggestion();
  }

  void _scrollToSuggestion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultContext = _resultKey.currentContext;
      if (!mounted || resultContext == null) return;
      Scrollable.ensureVisible(
        resultContext,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedGenre = _genres.cast<_Genre?>().firstWhere(
      (genre) => genre?.name == _selectedGenre,
      orElse: () => null,
    );
    final selectedMinutes = _minutes;

    return Scaffold(
      backgroundColor: AppTheme.deepCharcoal,
      body: Stack(
        children: [
          const _PlannerBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _PlannerHeader(onBack: () => Navigator.maybePop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'A better movie night,\nplanned around you.',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Outfit',
                            fontSize: 32,
                            height: 1.1,
                            letterSpacing: -1.05,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tell us your time and the feeling you want to take with you.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _SectionLabel(
                          index: '01',
                          title: 'Your available time',
                          subtitle: 'We will find a film that fits the moment.',
                        ),
                        const SizedBox(height: 12),
                        _FrostedPanel(
                          child: TextField(
                            controller: _timeController,
                            focusNode: _timeFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              setState(() {
                                _validationMessage = null;
                                _suggestion = null;
                                _suggestionIndex = 0;
                              });
                            },
                            onSubmitted: (_) => _findMovie(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 18, right: 13),
                                child: Icon(
                                  Icons.timer_outlined,
                                  color: AppTheme.sunsetOrange,
                                  size: 24,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 56,
                              ),
                              hintText: 'How many minutes?',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.30),
                                fontFamily: 'Outfit',
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Decrease by 5 minutes',
                                    onPressed: () => _adjustDuration(-5),
                                    icon: const Icon(Icons.remove_rounded),
                                    color: Colors.white.withValues(alpha: 0.68),
                                  ),
                                  Text(
                                    'MIN',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.38,
                                      ),
                                      fontFamily: 'Outfit',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Increase by 5 minutes',
                                    onPressed: () => _adjustDuration(5),
                                    icon: const Icon(Icons.add_rounded),
                                    color: const Color(0xFFA88BFF),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickDurations.map((duration) {
                            final isSelected = selectedMinutes == duration;
                            return _QuickDuration(
                              minutes: duration,
                              selected: isSelected,
                              onTap: () => _selectDuration(duration),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),
                        _SectionLabel(
                          index: '02',
                          title: 'Choose the mood',
                          subtitle:
                              'Pick a genre and let the night take shape.',
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _genres.map((genre) {
                            final isSelected = genre.name == _selectedGenre;
                            return _GenreChip(
                              genre: genre,
                              selected: isSelected,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedGenre = genre.name;
                                  _validationMessage = null;
                                  _suggestion = null;
                                  _suggestionIndex = 0;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        if (_validationMessage != null) ...[
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppTheme.sunsetOrange,
                                size: 17,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  _validationMessage!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.68),
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 30),
                        _FindButton(
                          selectedGenre: selectedGenre,
                          onPressed: _findMovie,
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.06),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: _suggestion == null
                              ? const SizedBox(key: ValueKey('no-suggestion'))
                              : KeyedSubtree(
                                  key: ValueKey(
                                    '${_suggestion!.title}-$_suggestionIndex',
                                  ),
                                  child: Padding(
                                    key: _resultKey,
                                    padding: const EdgeInsets.only(top: 24),
                                    child: _RecommendationCard(
                                      pick: _suggestion!,
                                      availableMinutes:
                                          selectedMinutes ??
                                          _suggestion!.minutes,
                                      onTryAnother: () =>
                                          _findMovie(anotherSuggestion: true),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerBackdrop extends StatelessWidget {
  const _PlannerBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF101A32),
                    Color(0xFF080C16),
                    Color(0xFF05060A),
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: -150,
            right: -100,
            child: _Glow(
              color: const Color(0xFF7655F7).withValues(alpha: 0.22),
              size: 330,
            ),
          ),
          Positioned(
            top: 260,
            left: -180,
            child: _Glow(
              color: const Color(0xFFFF765E).withValues(alpha: 0.10),
              size: 330,
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: const SizedBox(),
    ),
  );
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'MOVIE PLANNER',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Outfit',
                fontSize: 13,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFA88BFF),
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  'CURATED',
                  style: TextStyle(
                    color: Color(0xFFD5C9FF),
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.index,
    required this.title,
    required this.subtitle,
  });
  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        index,
        style: const TextStyle(
          color: Color(0xFFB49EFF),
          fontFamily: 'Outfit',
          fontSize: 11,
          letterSpacing: 1.7,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Outfit',
          fontSize: 20,
          letterSpacing: -0.35,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.49),
          fontFamily: 'Outfit',
          fontSize: 13,
        ),
      ),
    ],
  );
}

class _FrostedPanel extends StatelessWidget {
  const _FrostedPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF18233A).withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      ),
    ),
  );
}

class _QuickDuration extends StatelessWidget {
  const _QuickDuration({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });
  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$minutes minutes',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF7256E8).withValues(alpha: 0.26)
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFA88BFF)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Text(
            '$minutes min',
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.60),
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.genre,
    required this.selected,
    required this.onTap,
  });
  final _Genre genre;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: genre.name,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? genre.color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? genre.color.withValues(alpha: 0.80)
                  : Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                genre.icon,
                color: selected
                    ? genre.color
                    : Colors.white.withValues(alpha: 0.55),
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                genre.name,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.62),
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FindButton extends StatelessWidget {
  const _FindButton({required this.selectedGenre, required this.onPressed});
  final _Genre? selectedGenre;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Find your movie',
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedGenre == null
              ? const [Color(0xFF4D3D8F), Color(0xFF7450BC)]
              : [
                  const Color(0xFF5B45DE),
                  selectedGenre!.color.withValues(alpha: 0.90),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (selectedGenre?.color ?? const Color(0xFF805BFF)).withValues(
              alpha: 0.28,
            ),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 19),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 19),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Find my perfect fit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Outfit',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.pick,
    required this.availableMinutes,
    required this.onTryAnother,
  });
  final _PlannerPick pick;
  final int availableMinutes;
  final VoidCallback onTryAnother;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          pick.accent.withValues(alpha: 0.20),
          const Color(0xFF151A28).withValues(alpha: 0.94),
        ],
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: pick.accent.withValues(alpha: 0.45)),
      boxShadow: [
        BoxShadow(
          color: pick.accent.withValues(alpha: 0.14),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: pick.accent.withValues(alpha: 0.17),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: pick.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'YOUR CURATED PICK',
                style: TextStyle(
                  color: pick.accent,
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${pick.minutes} MIN',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.56),
                fontFamily: 'Outfit',
                fontSize: 11,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          pick.title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Outfit',
            fontSize: 27,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pick.label,
          style: TextStyle(
            color: pick.accent,
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          pick.description,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontFamily: 'Outfit',
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              color: Colors.white.withValues(alpha: 0.48),
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                pick.minutes <= availableMinutes
                    ? '${availableMinutes - pick.minutes} minutes left for the perfect snack.'
                    : '${pick.minutes - availableMinutes} minutes over your target, but worth the time.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.48),
                  fontFamily: 'Outfit',
                  fontSize: 12,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onTryAnother,
              icon: Icon(Icons.refresh_rounded, color: pick.accent, size: 17),
              label: Text(
                'Refresh pick',
                style: TextStyle(
                  color: pick.accent,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Genre {
  const _Genre(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

class _PlannerPick {
  const _PlannerPick({
    required this.title,
    required this.genre,
    required this.minutes,
    required this.accent,
    required this.label,
    required this.description,
  });
  final String title;
  final String genre;
  final int minutes;
  final Color accent;
  final String label;
  final String description;
}
