import 'package:flutter/material.dart';

class ArcanaLogo extends StatelessWidget {
  const ArcanaLogo({
    super.key,
    this.titleSize = 32,
    this.iconSize = 42,
  });

  final double titleSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, error, stackTrace) => const Icon(
            Icons.style,
            color: Color(0xFFCC55E8),
            size: 42,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Arcana Forge',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFCC86EC),
          ),
        ),
      ],
    );
  }
}
