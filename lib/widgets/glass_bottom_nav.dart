import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient Border Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CupertinoColors.white.withValues(alpha: 0.2),
                          CupertinoColors.white.withValues(alpha: 0.0),
                          CupertinoColors.white.withValues(alpha: 0.2),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: SafeArea(
                    top: false,
                    bottom:
                        false, // Fix: Remove default bottom padding to center content
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          icon: CupertinoIcons.sparkles,
                          label: 'AI',
                          isActive: currentIndex == 0,
                          onTap: () => onTap(0),
                        ),
                        _NavItem(
                          icon: CupertinoIcons.compass,
                          label: 'Discover',
                          isActive: currentIndex == 1,
                          onTap: () => onTap(1),
                        ),
                        _NavItem(
                          icon: CupertinoIcons.tv,
                          label: 'TV Shows',
                          isActive: currentIndex == 2,
                          onTap: () => onTap(2),
                        ),
                        _NavItem(
                          icon: CupertinoIcons.bookmark,
                          label: 'Collection',
                          isActive: currentIndex == 3,
                          onTap: () => onTap(3),
                        ),
                        _NavItem(
                          icon: CupertinoIcons.settings,
                          label: 'Settings',
                          isActive: currentIndex == 4,
                          onTap: () => onTap(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 64, // Fixed width for uniform look
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: isActive
            ? BoxDecoration(
                color: AppTheme.neonRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonRed.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              )
            : BoxDecoration(
                color: const Color(0x00000000), // Transparent
                borderRadius: BorderRadius.circular(20),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppTheme.neonRed
                  : CupertinoColors.white.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppTheme.neonRed
                    : CupertinoColors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
