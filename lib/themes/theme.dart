import 'package:flutter/material.dart';

const _kDefaultBodyStyle = TextStyle(
  color: Colors.black,
  fontFamily: 'Jakarta',
);

const kHeaderStyle = TextStyle(color: Colors.blue, fontFamily: 'Jakarta');

const _primaryColor = Colors.blue;

const _secondaryColor = Colors.lightBlue;

const _surfaceColor = Colors.white;

final theme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: _primaryColor,
    secondary: _secondaryColor,
    surface: _surfaceColor,
  ),
  textTheme: TextTheme(
    bodyMedium: _kDefaultBodyStyle.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),

    titleLarge: _kDefaultBodyStyle.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  ),
);
