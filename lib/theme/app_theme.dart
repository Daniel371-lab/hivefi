import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Paleta
  static const Color _honey = Color(0xFFF1C40F);
  static const Color _darkBrown = Color(0xFF3E2723);
  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF1E1E1E);
  static const Color _cardDark = Color(0xFF2C2C2C);
  static const Color _textDark = Color(0xFFE0E0E0);
  static const Color _textSecondaryDark = Color(0xFF9E9E9E);

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: _honey,
          onPrimary: _darkBrown,
          secondary: _darkBrown,
          onSecondary: _bgLight,
          surface: _bgLight,
          onSurface: _darkBrown,
          surfaceContainerHighest: const Color(0xFFF5F5F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        fontFamily: 'Poppins',

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: _darkBrown),
          titleTextStyle: TextStyle(
            color: _darkBrown,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: _bgLight,
          elevation: 4,
          shadowColor: _darkBrown.withOpacity(0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // Texto
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: _darkBrown, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: _darkBrown, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: _darkBrown, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: _darkBrown, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: _darkBrown, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: _darkBrown, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: _darkBrown),
          bodyMedium: TextStyle(color: _darkBrown),
          bodySmall: TextStyle(color: Color(0xFF6D4C41)),
          labelLarge: TextStyle(color: _darkBrown, fontWeight: FontWeight.w600),
        ),

        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFF8E1),
          labelStyle: const TextStyle(color: Color(0xFF6D4C41)),
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7CCC8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7CCC8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _honey, width: 2),
          ),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _honey,
            foregroundColor: _darkBrown,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ProgressIndicator
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _honey,
          linearTrackColor: Color(0xFFE0E0E0),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEEEEEE),
          thickness: 1,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: _honey,
          onPrimary: _darkBrown,
          secondary: _honey,
          onSecondary: _darkBrown,
          surface: _cardDark,
          onSurface: _textDark,
          surfaceContainerHighest: const Color(0xFF3A3A3A),
        ),
        scaffoldBackgroundColor: _bgDark,
        fontFamily: 'Poppins',

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: _textDark),
          titleTextStyle: TextStyle(
            color: _textDark,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: _cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
		
        // Texto
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: _textDark, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: _textDark),
          bodyMedium: TextStyle(color: _textDark),
          bodySmall: TextStyle(color: _textSecondaryDark),
          labelLarge: TextStyle(color: _textDark, fontWeight: FontWeight.w600),
        ),

        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3A3A3A),
          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          hintStyle: const TextStyle(color: Color(0xFF757575)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF424242)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF424242)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _honey, width: 2),
          ),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _honey,
            foregroundColor: _darkBrown,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ProgressIndicator
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _honey,
          linearTrackColor: Color(0xFF424242),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFF3A3A3A),
          thickness: 1,
        ),
      );
}