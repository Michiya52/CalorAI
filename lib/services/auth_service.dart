import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

/// AuthService handles user authentication via Firebase Auth.
class AuthService {
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Stream of auth state changes, mapping Firebase User to AppUser.
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser != null) {
        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
        );
      }
      return null;
    });
  }

  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  String? get currentEmail => _firebaseAuth.currentUser?.email;
  AppUser? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
    );
  }

  Future<AppUser> register(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AppUser(
        uid: credential.user!.uid,
        email: credential.user!.email!,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Registration failed.');
    }
  }

  Future<AppUser> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AppUser(
        uid: credential.user!.uid,
        email: credential.user!.email!,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Login failed.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Failed to send password reset email.');
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  /// Reauthenticates with the current user's email + [password].
  /// Required by Firebase before sensitive operations like account deletion.
  Future<void> reauthenticate(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException('no-user', 'No signed-in user.');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Incorrect password.');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _firebaseAuth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'Account deletion failed.');
    }
  }
}

/// Generic User class used throughout the app.
class AppUser {
  final String uid;
  final String email;
  AppUser({required this.uid, required this.email});
}

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, this.message);

  @override
  String toString() => message;
}
