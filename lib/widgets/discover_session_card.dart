import 'package:flutter/material.dart';

class DiscoverSessionCard extends StatelessWidget {
  const DiscoverSessionCard({
    super.key,
    required this.gameType,
    required this.sessionType,
    required this.name,
    required this.host,
    required this.date,
    required this.players,
    required this.venue,
    this.onJoin,
    this.joinLabel = 'Join Session >',
    this.isJoinEnabled = true,
  });

  final String gameType;
  final String sessionType;
  final String name;
  final String host;
  final String date;
  final String players;
  final String venue;
  final VoidCallback? onJoin;
  final String joinLabel;
  final bool isJoinEnabled;

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
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Hosted by $host',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFAA00FF), size: 14),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        venue,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(players, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AA55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Beginner Friendly',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const _Tag(label: 'RP', color: Color(0xFF5B2D8E)),
              const SizedBox(width: 8),
              const Text(
                'New Players Welcome',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAA00FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: isJoinEnabled ? onJoin : null,
                child: Text(
                  joinLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
