import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  const AuthResult({
    required this.success,
    this.errorMessage,
  });

  final bool success;
  final String? errorMessage;
}

abstract class AuthService {
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  Future<AuthResult> signUp({
    required String email,
    required String username,
    required String password,
  });

  Future<void> signOut();
}

class LocalAuthService implements AuthService {
  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const AuthResult(success: true);
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const AuthResult(success: true);
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: e.message ?? 'Login failed.');
    } catch (_) {
      return const AuthResult(success: false, errorMessage: 'Unexpected login error.');
    }
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(username);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: e.message ?? 'Sign up failed.');
    } catch (_) {
      return const AuthResult(success: false, errorMessage: 'Unexpected sign up error.');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
