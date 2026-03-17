import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  Future<void> _openNavigation(BuildContext context, String venue) async {
    final encodedVenue = Uri.encodeComponent(venue);
    final googleNavUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$encodedVenue');

    if (await canLaunchUrl(googleNavUri)) {
      await launchUrl(googleNavUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open maps on this device.')),
      );
    }
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    if (index == 1) {
      return;
    }

    if (index == 0) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.discover);
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.chat);
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      bottomNavigationBar: DiscoverBottomNav(
        selected: 1,
        onTap: (index) => _handleBottomNavTap(context, index),
      ),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Navigation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap a venue to open turn-by-turn directions.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('sessions')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Unable to load venues right now.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      final venueMap = <String, int>{};

                      for (final doc in docs) {
                        final data = doc.data();
                        final venue = (data['venue'] as String?)?.trim() ?? '';
                        if (venue.isEmpty) {
                          continue;
                        }
                        venueMap[venue] = (venueMap[venue] ?? 0) + 1;
                      }

                      final venues = venueMap.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      if (venues.isEmpty) {
                        return const Center(
                          child: Text(
                            'No venues yet. Create a session first.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: venues.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final venue = venues[index];
                          return Material(
                            color: const Color(0xFF2D1B4E),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openNavigation(context, venue.key),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFFAA00FF)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            venue.key,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${venue.value} session${venue.value == 1 ? '' : 's'} nearby',
                                            style: const TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.navigation_outlined, color: Colors.white70),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
