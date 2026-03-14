import 'package:flutter/material.dart';

class DiscoverBottomNav extends StatelessWidget {
  const DiscoverBottomNav({
    super.key,
    required this.selected,
    required this.onTap,
  });

  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.search, label: 'Discover'),
      (icon: Icons.map_outlined, label: 'Maps'),
      (icon: Icons.chat_bubble_outline, label: 'Chat'),
      (icon: Icons.person_outline, label: 'Profile'),
    ];

    return Container(
      color: const Color(0xFF12071F),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = selected == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[i].icon,
                  color: active ? const Color(0xFFAA00FF) : Colors.white38,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  items[i].label,
                  style: TextStyle(
                    fontSize: 11,
                    color: active ? const Color(0xFFAA00FF) : Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
