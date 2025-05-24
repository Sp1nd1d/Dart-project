import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('AuthService: Начало процесса выхода');
      
      // Очищаем все данные пользователя перед выходом
      await Future.wait([
        _auth.signOut(),
        // Здесь можно добавить очистку других данных, если необходимо
        // например, очистку SharedPreferences и т.д.
      ]);
      
      debugPrint('AuthService: Выход успешно завершен');
    } catch (e, stackTrace) {
      debugPrint('AuthService: Ошибка при выходе: $e');
      debugPrint('AuthService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Пароль слишком слабый';
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-email':
        return 'Неверный формат email';
      default:
        return 'Произошла ошибка: ${e.message}';
    }
  }
} 