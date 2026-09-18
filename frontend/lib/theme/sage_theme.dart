import 'package:flutter/material.dart';

class SageTheme {
  static ThemeData dark() {
    const background = Color(0xFF07090D);
    const surface = Color(0xFF10141B);
    const accent = Color(0xFFB8FF6A);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        surface: surface,
      ),
      useMaterial3: true,
      cardTheme: const CardThemeData(color: surface, margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
