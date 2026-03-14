import 'package:flutter/material.dart';

class DiscoverStatCard extends StatelessWidget {
  const DiscoverStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFF3D1A6E) : const Color(0xFF2D1B4E),
          borderRadius: BorderRadius.circular(14),
          border: highlighted
              ? Border.all(color: const Color(0xFFAA00FF), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(icon, color: Colors.white54, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
