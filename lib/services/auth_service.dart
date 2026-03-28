import 'dart:async';

/// Mock AuthService that simulates Firebase Auth locally.
/// User data is stored in memory — no real Firebase connection.
class AuthService {
  static String? _currentUserId;
  static String? _currentEmail;
  static final _authController = StreamController<MockUser?>.broadcast();

  // In-memory user store: email -> {password, uid}
  static final Map<String, Map<String, String>> _users = {};

  Stream<MockUser?> get authStateChanges => _authController.stream;
  String? get currentUserId => _currentUserId;
  String? get currentEmail => _currentEmail;

  Future<MockUser> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_users.containsKey(email)) {
      throw AuthException('email-already-in-use', 'An account already exists for that email.');
    }

    final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _users[email] = {'password': password, 'uid': uid};
    _currentUserId = uid;
    _currentEmail = email;

    final user = MockUser(uid: uid, email: email);
    _authController.add(user);
    return user;
  }

  Future<MockUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final stored = _users[email];
    if (stored == null) {
      throw AuthException('user-not-found', 'No account found with this email.');
    }
    if (stored['password'] != password) {
      throw AuthException('wrong-password', 'Incorrect password.');
    }

    _currentUserId = stored['uid'];
    _currentEmail = email;

    final user = MockUser(uid: _currentUserId!, email: email);
    _authController.add(user);
    return user;
  }

  Future<void> logout() async {
    _currentUserId = null;
    _currentEmail = null;
    _authController.add(null);
  }
}

class MockUser {
  final String uid;
  final String email;
  MockUser({required this.uid, required this.email});
}

class AuthException implements Exception {
  final String code;
  final String message;
  AuthException(this.code, this.message);

  @override
  String toString() => message;
}
