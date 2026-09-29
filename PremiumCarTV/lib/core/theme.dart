import 'package:flutter/material.dart';

/// OtoTV tasarım dili: gece siyahı zemin, şampanya altını vurgu.
abstract final class AppColors {
  static const background = Color(0xFF09090B);
  static const surface = Color(0xFF141417);
  static const surfaceHigh = Color(0xFF1D1D22);
  static const stroke = Color(0x1FFFFFFF);
  static const gold = Color(0xFFD9B26F);
  static const goldLight = Color(0xFFF3DDAE);
  static const goldDeep = Color(0xFF9C7535);
  static const textPrimary = Color(0xFFF5F2EC);
  static const textSecondary = Color(0xFF9D9A94);
  static const live = Color(0xFFE5484D);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDeep],
  );
}

abstract final class AppRadius {
  static const card = 18.0;
  static const sheet = 28.0;
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.gold,
    onPrimary: Color(0xFF1A1206),
    secondary: AppColors.goldLight,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.live,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          titleLarge: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.gold,
      textColor: AppColors.textPrimary,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
