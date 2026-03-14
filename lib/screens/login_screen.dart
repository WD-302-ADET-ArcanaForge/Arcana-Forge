import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/services/auth_service.dart';
import 'package:arcana_forge/widgets/auth_text_field.dart';
import 'package:arcana_forge/widgets/info_banner.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authService,
    this.bootstrapMessage,
  });

  final AuthService authService;
  final String? bootstrapMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await widget.authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.discover);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? 'Unable to sign in.')),
    );
  }

  double _titleSizeForWidth(double width) {
    if (width <= 380) {
      return 48;
    }
    return 58;
  }

  Widget _buildHero({
    required double width,
    required bool compact,
  }) {
    final logoSize = compact ? 200.0 : 260.0;
    final subtitleSize = compact ? 27.0 : 34.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: const Image(
            image: AssetImage('assets/logo.png'),
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: compact ? 10 : 16),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [Color(0xFF9C7BDF), Color(0xFFF173B8)],
            ).createShader(bounds);
          },
          child: Text(
            'Arcana Forge',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: _titleSizeForWidth(width),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Find your Match',
          style: TextStyle(
            color: Colors.white,
            fontSize: subtitleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required bool compact,
  }) {
    final verticalGap = compact ? 10.0 : 12.0;
    final buttonHeight = compact ? 50.0 : 54.0;
    final buttonFont = compact ? 24.0 : 30.0;

    return Container(
      margin: EdgeInsets.fromLTRB(18, compact ? 10 : 16, 18, compact ? 12 : 20),
      padding: EdgeInsets.fromLTRB(18, compact ? 12 : 16, 18, compact ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1652).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF9D74D8).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF090313).withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (widget.bootstrapMessage != null) ...[
              InfoBanner(message: widget.bootstrapMessage!),
              SizedBox(height: verticalGap + 2),
            ],
            AuthTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: verticalGap),
            AuthTextField(
              label: 'Password',
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: compact ? 12 : 16),
            Container(
              width: double.infinity,
              height: buttonHeight,
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
                  onTap: _isSubmitting ? null : _submit,
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Log In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: buttonFont,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.white60),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signup),
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompactHeight = constraints.maxHeight <= 780;

              return Stack(
                children: [
                  Positioned(
                    top: -80,
                    left: -70,
                    child: _GlowCircle(
                      diameter: 230,
                      color: const Color(0xFFDD80FF).withValues(alpha: 0.15),
                    ),
                  ),
                  Positioned(
                    top: 220,
                    right: -90,
                    child: _GlowCircle(
                      diameter: 250,
                      color: const Color(0xFFE95DB5).withValues(alpha: 0.16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Expanded(
                          flex: isCompactHeight ? 44 : 48,
                          child: Center(
                            child: _buildHero(
                              width: constraints.maxWidth,
                              compact: isCompactHeight,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: isCompactHeight ? 56 : 52,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: _buildFormCard(compact: isCompactHeight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.diameter,
    required this.color,
  });

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
