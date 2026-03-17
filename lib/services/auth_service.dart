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

  String _messageForAuthCode(
    String code, {
    required bool signup,
    String? firebaseMessage,
  }) {
    switch (code) {
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Console.';
      case 'invalid-api-key':
        return 'Firebase API key is invalid. Re-run flutterfire configure.';
      case 'app-not-authorized':
        return 'This app is not authorized for Firebase Auth. Check your Firebase app configuration.';
      case 'configuration-not-found':
        return 'Firebase Auth configuration is missing for this app. Verify your Firebase project setup.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already in use. Try logging in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        final action = signup ? 'create account' : 'sign in';
        final details = firebaseMessage == null || firebaseMessage.isEmpty
            ? code
            : '$code: $firebaseMessage';
        return 'Unable to $action right now ($details).';
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        errorMessage: _messageForAuthCode(
          e.code,
          signup: false,
          firebaseMessage: e.message,
        ),
      );
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
      return AuthResult(
        success: false,
        errorMessage: _messageForAuthCode(
          e.code,
          signup: true,
          firebaseMessage: e.message,
        ),
      );
    } catch (_) {
      return const AuthResult(success: false, errorMessage: 'Unexpected sign up error.');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
