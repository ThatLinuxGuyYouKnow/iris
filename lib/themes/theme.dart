import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _primaryColor = Colors.blue;
const _secondaryColor = Colors.lightBlue;
const _surfaceColor = Colors.white;

/// The default app font weight.
///
/// Defaults to [FontWeight.w500] (Ubuntu Medium) for good readability.
const FontWeight kDefaultFontWeight = FontWeight.w500;

/// Creates the app theme using the Ubuntu font family.
///
/// The default [fontWeight] is [FontWeight.w500] (Ubuntu Medium), but it can
/// be configured to any other weight such as [FontWeight.w300] (light),
/// [FontWeight.w400] (regular), or [FontWeight.w700] (bold).
ThemeData buildAppTheme({FontWeight fontWeight = kDefaultFontWeight}) {
  return ThemeData(
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: _surfaceColor,
    ),
    textTheme: TextTheme(
      bodyMedium: GoogleFonts.ubuntu(
        fontSize: 15,
        fontWeight: fontWeight,
        color: Colors.black,
      ),
      titleLarge: GoogleFonts.ubuntu(
        fontSize: 18,
        fontWeight: fontWeight,
        color: Colors.blue,
      ),
    ),
  );
}

/// Default header style using Ubuntu with the configured font weight.
TextStyle kHeaderStyle({FontWeight fontWeight = kDefaultFontWeight}) {
  return GoogleFonts.ubuntu(
    color: Colors.blue,
    fontWeight: fontWeight,
  );
}
