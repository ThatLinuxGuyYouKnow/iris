import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBackground = Colors.white;
const Color kSurface = Color(0xFFFFFFFF);
const Color kCard = Colors.white;
const Color kPrimaryAccent = Color(0xFF0D5AFF);
const Color kSecondaryAccent = Color(0xFF0D5AFF);
const Color kTertiaryAccent = Color(0xFF00E5A0);
const Color kTextPrimary = Color(0xFF001F54);
const Color kTextSecondary = Color(0xFF1A3B66);
const Color kDivider = Color(0xFFE5E7EB);

const LinearGradient kAccentGradient = LinearGradient(
  colors: [kPrimaryAccent, kSecondaryAccent],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kSubtleGradient = LinearGradient(
  colors: [Color(0xFFF5F7FA), Color(0xFFE8EBF2)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const FontWeight kDefaultFontWeight = FontWeight.w500;

ThemeData buildAppTheme({FontWeight fontWeight = kDefaultFontWeight}) {
  final baseTextTheme = GoogleFonts.interTextTheme();

  return ThemeData.light().copyWith(
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.light(
      primary: kPrimaryAccent,
      secondary: kSecondaryAccent,
      surface: kSurface,
      onPrimary: kBackground,
      onSecondary: Colors.white,
      onSurface: kTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
      ),
      iconTheme: IconThemeData(color: kPrimaryAccent),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kSurface,
      selectedItemColor: kPrimaryAccent,
      unselectedItemColor: kTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: kCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: kDivider,
    textTheme: baseTextTheme.copyWith(
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: fontWeight,
        color: kTextPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: kTextSecondary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: kTextPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: kTextPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: kTextSecondary,
        letterSpacing: 0.8,
      ),
    ),
  );
}

BoxDecoration kGlassDecoration({
  double opacity = 0.7,
  double borderRadius = 16,
  Color? borderColor,
}) {
  return BoxDecoration(
    color: kPrimaryAccent.withValues(alpha: opacity * 0.15),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: borderColor ?? kDivider,
      width: 1,
    ),
  );
}
