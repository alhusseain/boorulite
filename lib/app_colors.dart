import 'package:flutter/material.dart';

class AppColors {
  static const Color frenchFuchsia = Color(0xFFF23D91);
  static const Color darkNavy = Color(0xFF1F1E40);
  static const Color brightBlue = Color(0xFF353FF2);
  static const Color periwinkleBlue = Color(0xFF5D58F2);
  static const Color chinoBeige = Color(0xFFD9CBA3);

  // Light ColorScheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: frenchFuchsia,
    onPrimary: Colors.white,
    secondary: brightBlue,
    onSecondary: Colors.white,
    tertiary: periwinkleBlue,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Color(0xFFFFF8F0),
    onSurface: darkNavy,
  );

  // Dark ColorScheme
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: frenchFuchsia,
    onPrimary: Colors.white,
    secondary: periwinkleBlue,
    onSecondary: Colors.white,
    tertiary: chinoBeige,
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Color(0xFF2A2955),
    onSurface: Colors.white,
  );
}

