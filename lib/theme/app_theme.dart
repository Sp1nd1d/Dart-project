import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
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
    textTheme: GoogleFonts.notoSansTextTheme(ThemeData.light().textTheme),
  );

  static ThemeData get darkTheme => ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      surface: const Color(0xFF2D2D2D),
      primary: const Color(0xFF6C63FF),
      secondary: const Color(0xFFFF6584),
      background: const Color(0xFF1A1A1A),
      onBackground: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
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
      fillColor: const Color(0xFF2D2D2D),
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
    textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
    cardColor: const Color(0xFF2D2D2D),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2D2D2D),
      selectedItemColor: Color(0xFF6C63FF),
      unselectedItemColor: Colors.white54,
    ),
    dialogBackgroundColor: const Color(0xFF2D2D2D),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: const Color(0xFF2D2D2D),
      hourMinuteTextColor: Colors.white,
      dialHandColor: const Color(0xFF6C63FF),
      dialBackgroundColor: const Color(0xFF1A1A1A),
      entryModeIconColor: const Color(0xFF6C63FF),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF2D2D2D),
      headerBackgroundColor: const Color(0xFF2D2D2D),
      dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF6C63FF);
        }
        return const Color(0xFF2D2D2D);
      }),
      todayBackgroundColor: MaterialStateProperty.resolveWith((states) {
        return const Color(0xFF6C63FF).withOpacity(0.5);
      }),
      dayForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return Colors.white70;
      }),
      todayForegroundColor: MaterialStateProperty.resolveWith((states) {
        return Colors.white;
      }),
      yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF6C63FF);
        }
        return const Color(0xFF2D2D2D);
      }),
      yearForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return Colors.white70;
      }),
    ),
  );
} 