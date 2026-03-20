import 'package:flutter/material.dart';

class AuthGlowCircle extends StatelessWidget {
  const AuthGlowCircle({
    super.key,
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
