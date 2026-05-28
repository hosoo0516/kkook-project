import 'package:flutter/material.dart';

class KkookColors {
  static const Color background = Color(0xFFF4F7FB);
  static const Color primary = Color(0xFF4A7FD4);
  static const Color primaryDark = Color(0xFF3D6BB8);
  static const Color label = Color(0xFF6B7280);
  static const Color hint = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardShadow = Color(0x1A4A7FD4);
}

class KkookTheme {
  static ThemeData get light {
    const primary = KkookColors.primary;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: KkookColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: KkookColors.label,
          height: 1.5,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KkookColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KkookColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: KkookColors.hint, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
