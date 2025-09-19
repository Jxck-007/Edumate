import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A237E); // Dark Indigo
  static const Color secondaryColor = Color(0xFF0D47A1); // Dark Blue
  static const Color accentColor = Color(0xFF42A5F5); // Light Blue
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Grey
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color successColor = Color(0xFF388E3C); // Green
  
  // Text colors
  static const Color primaryTextColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color lightTextColor = Colors.white;
  
  // Gradient colors
  static const List<Color> backgroundGradient = [
    Color(0xFF1A237E),
    Color(0xFF0D47A1),
    Color(0xFF1976D2),
  ];
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      // fontFamily: 'Poppins', // Uncomment when font is available
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: lightTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextColor,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: primaryTextColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: primaryTextColor,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightTextColor,
        ),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: lightTextColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
    );
  }
  
  // Chat bubble decorations
  static BoxDecoration userMessageDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration botMessageDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Animation durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}