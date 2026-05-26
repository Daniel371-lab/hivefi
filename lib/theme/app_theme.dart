import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Paleta
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _brownDark = Color(0xFF78350F);
  static const Color _bgLight = Color(0xFFFAFAFA);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _textLight = Color(0xFF1C1917);
  static const Color _textSecondaryLight = Color(0xFF78716C);

  static const Color _bgDark = Color(0xFF1C1917);
  static const Color _surfaceDark = Color(0xFF292524);
  static const Color _textDark = Color(0xFFFAFAF9);
  static const Color _textSecondaryDark = Color(0xFFA8A29E);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.light(
          primary: _amber,
          onPrimary: _brownDark,
          secondary: _brownDark,
          onSecondary: _surfaceLight,
          surface: _surfaceLight,
          onSurface: _textLight,
          surfaceContainerHighest: Color(0xFFF5F5F4),
        ),
        scaffoldBackgroundColor: _bgLight,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: _textLight),
          titleTextStyle: TextStyle(
            color: _textLight,
            fontFamily: 'sans-serif',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        cardTheme: CardThemeData(
          color: _surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFFE7E5E4), width: 1),
          ),
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(color: _textLight, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          displayMedium: TextStyle(color: _textLight, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineLarge: TextStyle(color: _textLight, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: _textLight, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: _textLight, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: _textLight, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: _textLight),
          bodyMedium: TextStyle(color: _textLight),
          bodySmall: TextStyle(color: _textSecondaryLight),
          labelLarge: TextStyle(color: _textLight, fontWeight: FontWeight.w600),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceLight,
          labelStyle: const TextStyle(color: _textSecondaryLight),
          hintStyle: const TextStyle(color: Color(0xFFA8A29E)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _amber, width: 2),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _amber,
            foregroundColor: _brownDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'sans-serif',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _amber,
          linearTrackColor: Color(0xFFE7E5E4),
        ),

        dividerTheme: const DividerThemeData(
          color: Color(0xFFE7E5E4),
          thickness: 1,
        ),

        listTileTheme: const ListTileThemeData(
          iconColor: _textSecondaryLight,
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: _textLight,
          contentTextStyle: const TextStyle(color: _textDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: _amber,
          onPrimary: _brownDark,
          secondary: _amber,
          onSecondary: _brownDark,
          surface: _surfaceDark,
          onSurface: _textDark,
          surfaceContainerHighest: Color(0xFF3C3836),
        ),
        scaffoldBackgroundColor: _bgDark,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: _textDark),
          titleTextStyle: TextStyle(
            color: _textDark,
            fontFamily: 'sans-serif',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        cardTheme: CardThemeData(
          color: _surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFF3C3836), width: 1),
          ),
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          displayMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: _textDark),
          bodyMedium: TextStyle(color: _textDark),
          bodySmall: TextStyle(color: _textSecondaryDark),
          labelLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3C3836),
          labelStyle: const TextStyle(color: _textSecondaryDark),
          hintStyle: const TextStyle(color: Color(0xFF78716C)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3C3836)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3C3836)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _amber, width: 2),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _amber,
            foregroundColor: _brownDark,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'sans-serif',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _amber,
          linearTrackColor: Color(0xFF3C3836),
        ),

        dividerTheme: const DividerThemeData(
          color: Color(0xFF3C3836),
          thickness: 1,
        ),

        listTileTheme: const ListTileThemeData(
          iconColor: _textSecondaryDark,
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: _surfaceDark,
          contentTextStyle: const TextStyle(color: _textDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}