import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'newmood.dart';
import 'history.dart';
import 'settings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Future<void> _signOut() async {
    try {
      debugPrint('MainScreen: Начало процесса выхода');
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      await _authService.signOut();
      
      debugPrint('MainScreen: Выход успешно выполнен');
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('MainScreen: Ошибка при выходе: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выходе: $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addMoodEntry(double value, String? comment, DateTime dateTime) async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestoreService.updateUserMood(userId, value, comment, dateTime);
        await _firestoreService.addMoodToHistory(userId, value, comment, dateTime);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при сохранении: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MoodTrackerScreen(onSave: _addMoodEntry),
          if (userId != null) MoodHistoryScreen(userId: userId),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: theme.brightness == Brightness.dark 
          ? const Color(0xFF2D2D2D) 
          : Colors.white,
      selectedItemColor: const Color(0xFF6C63FF),
      unselectedItemColor: theme.brightness == Brightness.dark 
          ? Colors.white54 
          : Colors.grey,
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