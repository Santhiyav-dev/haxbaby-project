import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PipColors {
  // Day palette
  static const Color cream = Color(0xFFFFF7F2);
  static const Color berryPink = Color(0xFF963A72);
  static const Color softPink = Color(0xFFF5D7E8);
  static const Color brown = Color(0xFF56364F);

  // Night palette
  static const Color nightBg = Color(0xFF21182F);
  static const Color nightMid = Color(0xFF38264B);
  static const Color nightCard = Color(0xFF30243F);

  // Accent
  static const Color goldenGlow = Color(0xFFFFC963);
  static const Color starYellow = Color(0xFFFFE58A);
  static const Color lavender = Color(0xFFC8B2E6);
  static const Color mintGlow = Color(0xFF7FDBCA);
  static const Color peach = Color(0xFFFFD6BE);

  // Transparent overlays
  static Color nightOverlay = nightBg.withOpacity(0.85);
  static Color cardDay = const Color(0xFFFFFCFA).withOpacity(0.88);
  static Color cardNight = nightCard.withOpacity(0.92);
}

class AppTheme {
  static ThemeData dayTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: PipColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PipColors.berryPink,
      brightness: Brightness.light,
      surface: PipColors.cream,
      primary: PipColors.berryPink,
      secondary: PipColors.goldenGlow,
    ),
    textTheme: _buildTextTheme(PipColors.brown),
    cardTheme: CardThemeData(
      color: PipColors.cardDay,
      elevation: 8,
      shadowColor: PipColors.berryPink.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PipColors.berryPink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 6,
        shadowColor: PipColors.berryPink.withOpacity(0.5),
      ),
    ),
  );

  static ThemeData nightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PipColors.nightBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PipColors.goldenGlow,
      brightness: Brightness.dark,
      surface: PipColors.nightCard,
      primary: PipColors.goldenGlow,
      secondary: PipColors.lavender,
    ),
    textTheme: _buildTextTheme(Colors.white),
    cardTheme: CardThemeData(
      color: PipColors.cardNight,
      elevation: 12,
      shadowColor: PipColors.goldenGlow.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PipColors.goldenGlow,
        foregroundColor: PipColors.nightBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 8,
        shadowColor: PipColors.goldenGlow.withOpacity(0.5),
      ),
    ),
  );

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.nunito(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      displaySmall: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor.withOpacity(0.9),
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor.withOpacity(0.8),
        height: 1.5,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
