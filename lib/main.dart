import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/newmood.dart';
import 'screens/history.dart';
import 'screens/settings.dart';
import 'theme/app_theme.dart';
import 'models/mood_entry.dart';

void main() => runApp(const MoodTrackerApp());

class MoodTrackerApp extends StatelessWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      locale: const Locale('ru', 'RU'),
      theme: AppTheme.theme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<MoodEntry> _moodHistory = [];

  void _addMoodEntry(double value, String comment, DateTime dateTime) {
    setState(() {
      _moodHistory.add(MoodEntry(value: value, comment: comment, date: dateTime));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MoodTrackerScreen(onSave: _addMoodEntry),
          MoodHistoryScreen(history: _moodHistory),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF6C63FF),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_emotions_outlined),
          activeIcon: Icon(Icons.emoji_emotions),
          label: 'Настроение',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'История',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Настройки',
        ),
      ],
    );
  }
}