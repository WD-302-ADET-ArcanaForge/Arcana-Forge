import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/services/auth_service.dart';
import 'package:arcana_forge/widgets/arcana_logo.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningOut = false;

  void _handleBottomNavTap(int index) {
    if (index == 3) {
      return;
    }

    if (index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.discover);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This section is coming soon.')),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out right now.')),
      );
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: DiscoverBottomNav(
        selected: 3,
        onTap: _handleBottomNavTap,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7A2BD2),
              Color(0xFF6221BA),
              Color(0xFF2B154D),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    const ArcanaLogo(titleSize: 28, iconSize: 32),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1652).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF9D74D8).withValues(alpha: 0.5)),
                  ),
                  child: const Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Color(0xFFAA00FF),
                        child: Icon(Icons.person, size: 52, color: Colors.white),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Adventurer Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your account and session access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE32F95), Color(0xFF9F3EF0)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDF3A9E).withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _isSigningOut ? null : _handleSignOut,
                      child: Center(
                        child: _isSigningOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
