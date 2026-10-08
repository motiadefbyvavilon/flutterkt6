import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Поток состояния авторизации
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Вход по email и паролю
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // успех
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e);
    }
  }

  /// Регистрация нового аккаунта
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e);
    }
  }

  /// Выход из аккаунта
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'weak-password':
        return 'Пароль должен содержать минимум 6 символов';
      case 'invalid-email':
        return 'Неверный формат email';
      default:
        return e.message ?? 'Произошла ошибка';
    }
  }
}
