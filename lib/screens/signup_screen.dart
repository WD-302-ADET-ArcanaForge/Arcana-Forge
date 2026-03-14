import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/services/auth_service.dart';
import 'package:arcana_forge/widgets/auth_text_field.dart';
import 'package:arcana_forge/widgets/info_banner.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.authService,
    this.bootstrapMessage,
  });

  final AuthService authService;
  final String? bootstrapMessage;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _retypePasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _retypePasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await widget.authService.signUp(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.discover, (route) => false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.errorMessage ?? 'Unable to create account.')),
    );
  }

  double _titleSizeForWidth(double width) {
    if (width <= 380) {
      return 52;
    }
    return 62;
  }

  Widget _buildHero(double width) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const SizedBox(
          width: 220,
          height: 220,
          child: Image(
            image: AssetImage('assets/logo.png'),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 10),
        const Text(
          'Join the Circle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
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
              const SizedBox(height: 14),
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
            const SizedBox(height: 12),
            AuthTextField(
              label: 'Username',
              controller: _usernameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            AuthTextField(
              label: 'Retype Password',
              controller: _retypePasswordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please retype your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
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
                        : const Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.white60),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Login'),
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
                  SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          _buildHero(constraints.maxWidth),
                          const SizedBox(height: 24),
                          _buildFormCard(),
                        ],
                      ),
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
