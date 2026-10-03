import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';

class AIQuizScreen extends StatefulWidget {
  const AIQuizScreen({super.key});

  @override
  State<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends State<AIQuizScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _currentQuestions = [];
  int _currentQuizIndex = -1;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isQuizCompleted = false;
  bool _isAnswerSelected = false;
  int? _selectedAnswerIndex;
  bool _showCorrectAnswer = false;

  final List<Map<String, dynamic>> _quizzes = [
    {
      'title': '🎬 Classic Movies',
      'icon': Icons.movie_creation_outlined,
      'color': const Color(0xFFFF6B6B),
      'questions': [
        {
          'question':
              'Which movie features the famous line "Here\'s looking at you, kid"?',
          'options': [
            'Gone with the Wind',
            'Casablanca',
            'Citizen Kane',
            'The Maltese Falcon',
          ],
          'correctAnswer': 1,
        },
        {
          'question': 'Who directed the movie "Psycho" (1960)?',
          'options': [
            'Stanley Kubrick',
            'Alfred Hitchcock',
            'Orson Welles',
            'Billy Wilder',
          ],
          'correctAnswer': 1,
        },
        {
          'question':
              'In "The Godfather", what does Al Pacino\'s character find on his pillow?',
          'options': ['A gun', 'A rose', 'A horse head', 'A letter'],
          'correctAnswer': 2,
        },
      ],
    },
    {
      'title': '🌟 Hollywood Stars',
      'icon': Icons.star_border_rounded,
      'color': const Color(0xFF4ECDC4),
      'questions': [
        {
          'question': 'Which actor played the Joker in "The Dark Knight"?',
          'options': [
            'Joaquin Phoenix',
            'Jack Nicholson',
            'Heath Ledger',
            'Jared Leto',
          ],
          'correctAnswer': 2,
        },
        {
          'question':
              'Who won the Academy Award for Best Actor for "Forrest Gump"?',
          'options': [
            'Tom Hanks',
            'Robin Williams',
            'Kevin Costner',
            'Denzel Washington',
          ],
          'correctAnswer': 0,
        },
      ],
    },
    {
      'title': '🏆 Oscar Trivia',
      'icon': Icons.emoji_events_outlined,
      'color': const Color(0xFFFFD700),
      'questions': [
        {
          'question': 'Which movie won Best Picture in 2020?',
          'options': [
            '1917',
            'Joker',
            'Parasite',
            'Once Upon a Time in Hollywood',
          ],
          'correctAnswer': 2,
        },
        {
          'question': 'Who has won the most Academy Awards for acting?',
          'options': [
            'Meryl Streep',
            'Katharine Hepburn',
            'Jack Nicholson',
            'Daniel Day-Lewis',
          ],
          'correctAnswer': 1,
        },
      ],
    },
  ];

  Future<void> _selectQuiz(int index) async {
    setState(() {
      _currentQuizIndex = index;
      _isLoading = true;
      _currentQuestionIndex = 0;
      _score = 0;
      _isQuizCompleted = false;
      _isAnswerSelected = false;
      _selectedAnswerIndex = null;
      _showCorrectAnswer = false;
    });

    try {
      final quizTitle = _quizzes[index]['title'] as String;
      // Remove emoji for cleaner prompt
      final topic = quizTitle.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      debugPrint('🎲 Selecting quiz: $topic');

      final questions = await _aiService.generateQuizQuestions(topic);
      debugPrint('🎲 Received ${questions.length} questions from AI');

      if (!mounted) return;

      setState(() {
        if (questions.isNotEmpty) {
          _currentQuestions = questions;
          debugPrint('✅ Using AI questions');
        } else {
          _currentQuestions =
              (_quizzes[index]['questions'] as List<Map<String, dynamic>>);
          debugPrint('⚠️ AI list empty, using fallback');
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error in _selectQuiz: $e');
      if (!mounted) return;
      // Fallback to static
      setState(() {
        _currentQuestions =
            (_quizzes[index]['questions'] as List<Map<String, dynamic>>);
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int answerIndex) async {
    if (_isAnswerSelected) return;

    setState(() {
      _isAnswerSelected = true;
      _selectedAnswerIndex = answerIndex;
    });

    final currentQuestion = _currentQuestions[_currentQuestionIndex];
    final isCorrect = answerIndex == currentQuestion['correctAnswer'];

    if (isCorrect) {
      setState(() => _score++);
    }

    setState(() => _showCorrectAnswer = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswerSelected = false;
        _selectedAnswerIndex = null;
        _showCorrectAnswer = false;
      });
    } else {
      setState(() => _isQuizCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          _currentQuizIndex == -1
              ? 'Movie Trivia'
              : _quizzes[_currentQuizIndex]['title'],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (_currentQuizIndex != -1) {
              setState(() => _currentQuizIndex = -1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: _currentQuizIndex == -1
              ? _buildQuizList()
              : _isLoading
              ? _buildLoadingState()
              : _buildQuizContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.vibrantPurple),
          const SizedBox(height: 24),
          Text(
            'Generating Quiz...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Creating 5 unique questions just for you',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return GestureDetector(
          onTap: () => _selectQuiz(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (quiz['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(quiz['icon'], color: quiz['color'], size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5 Questions • Infinite Replay',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizContent() {
    if (_isQuizCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Quiz Completed!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You scored $_score / ${_currentQuestions.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => setState(() => _currentQuizIndex = -1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepIndigo,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Back to Quizzes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final quiz = _quizzes[_currentQuizIndex];
    final question = _currentQuestions[_currentQuestionIndex];
    final options = List<String>.from(question['options']);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _currentQuestions.length,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(quiz['color']),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 32),
          Text(
            'Question ${_currentQuestionIndex + 1}',
            style: TextStyle(
              color: quiz['color'],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question['question'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(options.length, (index) {
            final isSelected = _selectedAnswerIndex == index;
            final isCorrect = index == question['correctAnswer'];
            final showColor = _showCorrectAnswer && (isSelected || isCorrect);

            Color borderColor = Colors.white.withValues(alpha: 0.1);
            Color bgColor = Colors.transparent;

            if (showColor) {
              if (isCorrect) {
                borderColor = Colors.green;
                bgColor = Colors.green.withValues(alpha: 0.2);
              } else if (isSelected) {
                borderColor = Colors.red;
                bgColor = Colors.red.withValues(alpha: 0.2);
              }
            } else if (isSelected) {
              borderColor = quiz['color'];
              bgColor = (quiz['color'] as Color).withValues(alpha: 0.1);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _selectAnswer(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected || showColor ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                          color: showColor && isCorrect
                              ? Colors.green
                              : Colors.transparent,
                        ),
                        child: showColor && isCorrect
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(color: borderColor),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          options[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
