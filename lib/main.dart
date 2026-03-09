import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A0B2E),
      ),
      home: const DiscoverPage(),
    );
  }
}

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  int _selectedFilter = 0;
  int _selectedNav = 0;

  final List<String> _filters = ['All', 'MTG', 'DND', 'Warhammer'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Image.network(
                          'https://img.icons8.com/color/48/000000/playing-card.png',
                          width: 40,
                          height: 40,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.style,
                            color: Colors.deepPurpleAccent,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Arcana Forge',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D1B4E),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const TextField(
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search games, events, players...',
                                hintStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(Icons.search, color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFAA00FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.filter_alt, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _StatCard(
                          label: 'Active Sessions',
                          value: '67',
                          icon: Icons.calendar_today_outlined,
                          highlighted: true,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Nearby Players',
                          value: '24',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          label: 'Game Venues',
                          value: '13',
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_filters.length, (i) {
                          final selected = _selectedFilter == i;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFilter = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFAA00FF)
                                      : const Color(0xFF2D1B4E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _filters[i],
                                  style: TextStyle(
                                    color: selected ? Colors.white : Colors.white70,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Divider(color: Colors.white12, height: 24),
                    const _SessionCard(
                      gameType: 'DND',
                      sessionType: 'Campaign',
                      name: 'Lost Souls',
                      host: 'JP',
                      date: '3-26-2026 at 19:00',
                      players: '3-5 players',
                      venue: "Dragon's Lair Games",
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _BottomNav(
              selected: _selectedNav,
              onTap: (i) => setState(() => _selectedNav = i),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
  });

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
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Icon(icon, color: Colors.white54, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String gameType;
  final String sessionType;
  final String name;
  final String host;
  final String date;
  final String players;
  final String venue;

  const _SessionCard({
    required this.gameType,
    required this.sessionType,
    required this.name,
    required this.host,
    required this.date,
    required this.players,
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D1B4E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(label: gameType, color: const Color(0xFF5B2D8E)),
              const SizedBox(width: 6),
              _Tag(label: sessionType, color: const Color(0xFFCC0000)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Hosted by $host',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFFAA00FF), size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        venue,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Date
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(date,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(players,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AA55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Beginner Friendly',
                    style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Tag(label: 'RP', color: const Color(0xFF5B2D8E)),
              const SizedBox(width: 8),
              const Text('New Players Welcome',
                  style: TextStyle(fontSize: 11, color: Colors.white54)),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAA00FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () {},
                child: const Text('Join Session >',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selected, required this.onTap});

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
                Icon(items[i].icon,
                    color: active
                        ? const Color(0xFFAA00FF)
                        : Colors.white38,
                    size: 26),
                const SizedBox(height: 4),
                Text(items[i].label,
                    style: TextStyle(
                        fontSize: 11,
                        color: active
                            ? const Color(0xFFAA00FF)
                            : Colors.white38)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
