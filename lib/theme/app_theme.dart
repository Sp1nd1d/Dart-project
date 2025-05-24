import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      surface: Colors.white,
      primary: const Color(0xFF6C63FF),
      secondary: const Color(0xFFFF6584),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFF2D3142)),
      titleTextStyle: TextStyle(
        color: Color(0xFF2D3142),
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
      ),
      contentPadding: const EdgeInsets.all(20),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3142),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF4F5665),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF4F5665),
      ),
    ),
  );
} 