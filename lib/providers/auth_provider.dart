import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ValueNotifier<bool> authStateNotifier = ValueNotifier(false);

  AuthProvider() {
    _user = _authService.currentUser;
    authStateNotifier.value = isLoggedIn;
    _subscription = _authService.authStateChanges.listen((user) {
      _user = user;
      authStateNotifier.value = isLoggedIn;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    authStateNotifier.dispose();
    super.dispose();
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.register(email, password);
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
    } finally {
      authStateNotifier.value = isLoggedIn;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Login failed. Please try again.';
    } finally {
      authStateNotifier.value = isLoggedIn;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Failed to send reset email. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    authStateNotifier.value = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
