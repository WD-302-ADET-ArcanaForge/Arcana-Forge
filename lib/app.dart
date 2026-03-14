import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/config/firebase_bootstrap.dart';
import 'package:arcana_forge/screens/discover_screen.dart';
import 'package:arcana_forge/screens/login_screen.dart';
import 'package:arcana_forge/screens/profile_screen.dart';
import 'package:arcana_forge/screens/signup_screen.dart';
import 'package:arcana_forge/services/auth_service.dart';
import 'package:flutter/material.dart';

class ArcanaForgeApp extends StatelessWidget {
  ArcanaForgeApp({
    super.key,
    required this.bootstrapResult,
  }) : _authService = bootstrapResult.firebaseReady ? FirebaseAuthService() : LocalAuthService();

  final FirebaseBootstrapResult bootstrapResult;
  final AuthService _authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A0B2E),
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.login:
            return MaterialPageRoute<void>(
              builder: (_) => LoginScreen(
                authService: _authService,
                bootstrapMessage: bootstrapResult.message,
              ),
            );
          case AppRoutes.signup:
            return MaterialPageRoute<void>(
              builder: (_) => SignupScreen(
                authService: _authService,
                bootstrapMessage: bootstrapResult.message,
              ),
            );
          case AppRoutes.discover:
            return MaterialPageRoute<void>(
              builder: (_) => const DiscoverScreen(),
            );
          case AppRoutes.profile:
            return MaterialPageRoute<void>(
              builder: (_) => ProfileScreen(authService: _authService),
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => LoginScreen(
                authService: _authService,
                bootstrapMessage: bootstrapResult.message,
              ),
            );
        }
      },
    );
  }
}
