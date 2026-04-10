import 'package:flutter/material.dart';
import 'package:xelex_esp/core/theme/app_colors.dart';
import '../responsive/font_scale.dart';

/// Color Scheme — built from AppColors
final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,

  primary: AppColors.primary,
  onPrimary: Colors.white,

  secondary: AppColors.primaryLight,
  onSecondary: AppColors.text,

  surface: AppColors.surface,
  onSurface: AppColors.text,

  error: AppColors.error,
  onError: Colors.white,

  outline: AppColors.border,
  shadow: Colors.black,
  surfaceTint: AppColors.primary,
);

/// Base Text Theme (NO scaling here)
const TextTheme _baseTextTheme = TextTheme(
  bodyLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  ),
  bodyMedium: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  ),
  titleLarge: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  ),
  titleMedium: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  ),
  titleSmall: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  ),
  headlineMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600
  ),
  headlineSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600
  ),
);

/// Responsive Text Scaling
TextTheme scaledTextTheme(BuildContext context) {
  final scale = fontScaleFactor(context);
  return _baseTextTheme.apply(fontSizeFactor: scale);
}

/// FINAL THEME DATA
ThemeData lightTheme(BuildContext context) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,

    scaffoldBackgroundColor: AppColors.bg,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    textTheme: scaledTextTheme(context).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,

      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),

      labelStyle: TextStyle(
        color: AppColors.text.withOpacity(0.7),
      ),

      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),

      hintStyle: const TextStyle(
        color: AppColors.textHint,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.6,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
