import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../services/ad_service.dart';
import '../services/ad_navigation_service.dart';
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
  final Set<int> _visitedTabs = {0};

  final List<Widget> _pages = const [
    AIPage(),
    DiscoverPage(),
    TVShowsPage(),
    CollectionPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    final ads = AdService();
    // The splash preloads every format and handles the cold-start ad.
    // Listen for App Open ads on later foreground events.
    ads.startAppOpenForegroundListener();
  }

  Future<void> _onItemTapped(int index) async {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    await AdNavigationService.runAfterInterstitial(context, () {
      setState(() {
        _currentIndex = index;
        _visitedTabs.add(index);
      });
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
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                for (var index = 0; index < _pages.length; index++)
                  _visitedTabs.contains(index)
                      ? TickerMode(
                          enabled: index == _currentIndex,
                          child: _pages[index],
                        )
                      : const SizedBox.shrink(),
              ],
            ),
          ),

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
