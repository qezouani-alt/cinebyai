import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Assuming AppTheme is defined in your project, otherwise we can import it.
// Since I don't have the exact path for AppTheme handy, I'll use hardcoded values matching the "Pro" aesthetic
// seen in other files (Electric Cyan, etc.) or import main if possible.
// Actually, I'll define necessary styles locally to be safe, but try to match the existing vibe.

class PremiumAccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onWatchAd;
  final VoidCallback onCancel;

  const PremiumAccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onWatchAd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(
                0xFF1E1E2C,
              ).withValues(alpha: 0.95), // Deep Dark Blue/Grey
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(
                  0xFF00FFD1,
                ).withValues(alpha: 0.3), // Electric Cyan border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFD1).withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Image / Icon
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2B32B2), // Deep purple-ish blue
                            Color(0xFF1488CC), // Bright blue
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.play_circle_fill,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Icon(
                              CupertinoIcons.star_fill,
                              size: 24,
                              color: const Color(
                                0xFFFFD700,
                              ).withValues(alpha: 0.8), // Gold
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: '.SF Pro Display', // iOS Default
                              decoration: TextDecoration.none,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 15,
                              height: 1.5,
                              fontFamily: '.SF Pro Text',
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Watch Ad Button
                          GestureDetector(
                            onTap: onWatchAd,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00FFD1), // Electric Cyan
                                    Color(0xFF008C7A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00FFD1,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.play_arrow_solid,
                                    color:
                                        Colors.black, // Dark text/icon on cyan
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Watch Ad to Unlock',
                                    style: TextStyle(
                                      color: Colors.black, // Dark text on cyan
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Cancel Button
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: onCancel,
                            minimumSize: Size(0, 0),
                            child: Text(
                              'Maybe Later',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
