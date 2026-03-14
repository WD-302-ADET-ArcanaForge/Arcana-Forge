import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.firebaseReady,
    this.message,
  });

  final bool firebaseReady;
  final String? message;
}

class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      await Firebase.initializeApp();
      return const FirebaseBootstrapResult(firebaseReady: true);
    } on FirebaseException {
      return const FirebaseBootstrapResult(
        firebaseReady: false,
        message: 'Firebase is not configured yet. Run flutterfire configure and add platform files.',
      );
    } catch (_) {
      return const FirebaseBootstrapResult(
        firebaseReady: false,
        message: 'Firebase initialization skipped. Configure Firebase before enabling auth.',
      );
    }
  }
}
