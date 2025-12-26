import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color frenchFuchsia = Color(0xFFF23D91);
  static const Color softFuchsia = Color(0xFFE85A9C);
  static const Color darkNavy = Color(0xFF1F1E40);
  static const Color softBlue = Color(0xFF5B6AD9);
  static const Color periwinkleBlue = Color(0xFF7B78D9);
  static const Color chinoBeige = Color(0xFFD9CBA3);
  static const Color warmTaupe = Color(0xFFA89F8A);
  static const Color ashGray = Color(0xFF2B2D31);

  // Light ColorScheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: frenchFuchsia,
    onPrimary: Colors.white,
    secondary: softBlue,
    onSecondary: Colors.white,
    tertiary: warmTaupe,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: Colors.white,
    onSurface: darkNavy,
  );

  // Dark ColorScheme
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: softFuchsia,
    onPrimary: Colors.white,
    secondary: periwinkleBlue,
    onSecondary: Colors.white,
    tertiary: chinoBeige,
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: ashGray,
    onSurface: Color(0xFFE8E8E8),
  );
}