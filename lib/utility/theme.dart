import 'package:flutter/material.dart';
import '../responsive/font_scale.dart';

/// 🎨 SINGLE SOURCE OF TRUTH — Color Scheme
final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,

  primary: const Color(0xFF448AFF),
  onPrimary: Colors.white,

  secondary: const Color(0xFF90CAF9),
  onSecondary: Colors.black,

  surface: Colors.white,
  onSurface: const Color(0xFF0F172A),

  error: const Color(0xFFD32F2F),
  onError: Colors.white,

  outline: const Color(0xFFBDBDBD),
  shadow: Colors.black,
  surfaceTint: const Color(0xFF448AFF),
);

/// 🔤 Base Text Theme (NO scaling here)
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

/// 🔍 Responsive Text Scaling
TextTheme scaledTextTheme(BuildContext context) {
  final scale = fontScaleFactor(context);
  return _baseTextTheme.apply(fontSizeFactor: scale);
}

/// 🎯 FINAL THEME DATA
ThemeData lightTheme(BuildContext context) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,

    scaffoldBackgroundColor: lightColorScheme.surface,

    appBarTheme: AppBarTheme(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      elevation: 2,
      centerTitle: false,
    ),

    textTheme: scaledTextTheme(context).apply(
      bodyColor: lightColorScheme.onSurface,
      displayColor: lightColorScheme.onSurface,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightColorScheme.surface,

      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),

      labelStyle: TextStyle(
        color: lightColorScheme.onSurface.withOpacity(0.7),
      ),

      floatingLabelStyle: TextStyle(
        color: lightColorScheme.primary,
        fontWeight: FontWeight.w600,
      ),

      hintStyle: TextStyle(
        color: lightColorScheme.onSurface.withOpacity(0.5),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: lightColorScheme.outline,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: lightColorScheme.primary,
          width: 1.6,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: lightColorScheme.error,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
