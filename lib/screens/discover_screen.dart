import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/widgets/arcana_logo.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:arcana_forge/widgets/discover_session_card.dart';
import 'package:arcana_forge/widgets/discover_stat_card.dart';
import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
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
                    const ArcanaLogo(titleSize: 44),
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
                    const Row(
                      children: [
                        DiscoverStatCard(
                          label: 'Active Sessions',
                          value: '67',
                          icon: Icons.calendar_today_outlined,
                          highlighted: true,
                        ),
                        SizedBox(width: 10),
                        DiscoverStatCard(
                          label: 'Nearby Players',
                          value: '24',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(width: 10),
                        DiscoverStatCard(
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
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFFAA00FF) : const Color(0xFF2D1B4E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _filters[i],
                                  style: TextStyle(
                                    color: selected ? Colors.white : Colors.white70,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
                    const DiscoverSessionCard(
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
            DiscoverBottomNav(
              selected: _selectedNav,
              onTap: (i) {
                if (i == 3) {
                  Navigator.of(context).pushNamed(AppRoutes.profile);
                  return;
                }
                setState(() => _selectedNav = i);
              },
            ),
          ],
        ),
      ),
    );
  }
}
