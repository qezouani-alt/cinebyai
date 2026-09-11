import 'dart:ui';

class AppTheme {
  // 2026 Glassmorphism Color Palette
  static const deepCharcoal = Color(0xFF0B0F1A); // Requested dark cinematic
  // Darker, subtler gradient colors
  static const transformativeTeal = Color(0xFF151A25);
  static const hazeBlue = Color(0xFF1C2436);

  static const neonRed = Color(0xFFFF4040); // Replaced neonRed with neonRed
  // Replaced neonLime with neonRed as requested (No green stars)
  static const neonLime = neonRed;
  static const sunsetOrange = Color(0xFFFF8540);
  static const neonGreen = Color(0xFF39FF14);
  static const deepIndigo = Color(0xFF4F46E5);
  static const vibrantPurple = Color(0xFF8B5CF6);
  static const darkSlate = Color(0xFF1F2937);
  static const darkBackground = deepCharcoal;

  // Glass Properties
  static const glassOpacity = 0.08; // Slightly more transparent
  static const glassBorderColor = Color(0x1AFFFFFF); // white10
  static const glassBlurSigma = 24.0; // Increased blur
  static const glassRadius = 24.0;

  // Typography (SF Pro is default on iOS)
  static const String fontFamily = '.SF Pro Text';

  // Gradients
  static const meshGradientColors = [
    deepCharcoal,
    transformativeTeal,
    hazeBlue,
  ];

  static const meshGradientStops = [0.0, 0.6, 1.0]; // Adjusted stops
}
