import 'package:flutter/material.dart';

class SageTheme {
  static const voidBlack = Color(0xFF020306);
  static const surface = Color(0xFF06101A);
  static const surfaceRaised = Color(0xFF0A1624);
  static const cyan = Color(0xFF17D8FF);
  static const blue = Color(0xFF3E66FF);
  static const violet = Color(0xFF8F4DFF);
  static const gold = Color(0xFFFFB833);
  static const success = Color(0xFF39E68A);
  static const failure = Color(0xFFFF5B43);
  static const textPrimary = Color(0xFFF0F7FF);
  static const textSecondary = Color(0xFF8191A6);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: voidBlack,
      colorScheme: scheme.copyWith(
        primary: cyan,
        secondary: violet,
        surface: surface,
        error: failure,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x2617D8FF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x2617D8FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x2617D8FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: cyan),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xF006101A),
        indicatorColor: Color(0x3320DFFF),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: voidBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x1AFFFFFF)),
    );
  }
}
