import 'package:flutter/material.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF64449B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
