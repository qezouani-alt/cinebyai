import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_bottom_nav.dart';
import 'ai_page.dart';
import 'discover_page.dart';
import 'tv_shows_page.dart';
import 'collection_page.dart';
import 'settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AIPage(),
    DiscoverPage(),
    TVShowsPage(),
    CollectionPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Gradient Background (behind everything)
          const Positioned.fill(
            child: GradientBackground(child: SizedBox.expand()),
          ),

          // Current Page
          Positioned.fill(child: _pages[_currentIndex]),

          // Glass Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}
