import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../main_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Показываем индикатор загрузки при инициализации
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Показываем ошибку, если она есть
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Произошла ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Перезагружаем состояние
                    },
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            ),
          );
        }

        // Если пользователь авторизован, показываем главный экран
        if (snapshot.hasData && snapshot.data != null) {
          debugPrint('AuthWrapper: Пользователь авторизован');
          return const MainScreen();
        }

        // Если пользователь не авторизован, показываем экран входа/регистрации
        debugPrint('AuthWrapper: Пользователь не авторизован');
        return _showLogin
            ? LoginScreen(onRegisterPressed: _toggleView)
            : RegisterScreen(onLoginPressed: _toggleView);
      },
    );
  }
} 