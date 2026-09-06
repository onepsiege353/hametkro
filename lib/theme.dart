import 'package:flutter/material.dart';

/// Palette & style Hametkro — identité « Côte d'Ivoire 🇨🇮 ».
/// Orange + Vert + Blanc (couleurs du drapeau ivoirien).
/// Orange = énergie du marché & action, Vert = seconde main & écologie.
class AppColors {
  // Drapeau CI
  static const ivoireOrange = Color(0xFFFF7A00); // orange CI
  static const ivoireGreen = Color(0xFF009A44); // vert CI
  static const ivoireWhite = Color(0xFFFFFFFF);

  static const primary = ivoireGreen; // vert : éco / seconde main
  static const primaryDark = Color(0xFF007A36);
  static const accent = ivoireOrange; // orange : appels à l'action
  static const accentDark = Color(0xFFE06A00);
  static const danger = Color(0xFFE6453C);
  static const gold = Color(0xFFFFC145);
  static const bg = Color(0xFFF7F6F2);
  static const surface = Colors.white;
  static const text = Color(0xFF16171A);
  static const textLight = Color(0xFF6C6F78);
  static const border = Color(0xFFE9E6DE);

  /// Bandeau décoratif aux couleurs du drapeau ivoirien.
  static List<Color> flag = const [
    ivoireOrange,
    ivoireWhite,
    ivoireGreen,
  ];
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.text,
        titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.text),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerColor: AppColors.border,
    );
  }
}
