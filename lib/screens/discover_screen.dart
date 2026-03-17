import 'dart:async';

import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/widgets/arcana_logo.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:arcana_forge/widgets/discover_session_card.dart';
import 'package:arcana_forge/widgets/discover_stat_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _selectedNav = 0;

  final List<_SessionItem> _sessions = [];
  final CollectionReference<Map<String, dynamic>> _sessionsRef =
      FirebaseFirestore.instance.collection('sessions');

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;
  bool _isLoadingSessions = true;
  String? _sessionsError;

  @override
  void initState() {
    super.initState();
    _listenToSessions();
  }

  void _listenToSessions() {
    _sessionsSub = _sessionsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) {
            return;
          }

          setState(() {
            _sessions
              ..clear()
              ..addAll(
                snapshot.docs.map((doc) => _SessionItem.fromMap(doc.data())),
              );
            _isLoadingSessions = false;
            _sessionsError = null;
          });
        }, onError: (_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isLoadingSessions = false;
            _sessionsError = 'Unable to load sessions from Firebase.';
          });
        });
  }

  @override
  void dispose() {
    _sessionsSub?.cancel();
    super.dispose();
  }

  int get _activeSessionCount => _sessions.length;

  int get _uniqueVenueCount {
    return _sessions.map((session) => session.venue.toLowerCase().trim()).toSet().length;
  }

  Future<void> _openCreateSessionDialog() async {
    final createdSession = await showDialog<_SessionItem>(
      context: context,
      builder: (_) => const _CreateSessionDialog(),
    );

    if (!mounted || createdSession == null) {
      return;
    }

    try {
      await _sessionsRef.add({
        ...createdSession.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session "${createdSession.name}" created.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.message ?? 'Unable to save session to Firebase.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showActiveSessionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF241340),
      builder: (context) {
        if (_sessions.isEmpty) {
          return const _StatSheetEmptyState(
            title: 'Active Sessions',
            message: 'No active sessions yet. Create one to get started.',
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Sessions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        session.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${session.gameType} • ${session.date} • ${session.venue}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGameVenuesSheet() {
    final venues = <String, int>{};
    for (final session in _sessions) {
      final venue = session.venue.trim();
      venues[venue] = (venues[venue] ?? 0) + 1;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF241340),
      builder: (context) {
        if (venues.isEmpty) {
          return const _StatSheetEmptyState(
            title: 'Game Venues',
            message: 'No venues yet. Create a session to add one.',
          );
        }

        final venueEntries = venues.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Game Venues',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: venueEntries.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final venue = venueEntries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined, color: Colors.white70),
                      title: Text(
                        venue.key,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        '${venue.value} session${venue.value == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                    Row(
                      children: [
                        DiscoverStatCard(
                          label: 'Active Sessions',
                          value: '$_activeSessionCount',
                          icon: Icons.calendar_today_outlined,
                          highlighted: true,
                          onTap: _showActiveSessionsSheet,
                        ),
                        const SizedBox(width: 10),
                        const DiscoverStatCard(
                          label: 'Nearby Players',
                          value: '24',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(width: 10),
                        DiscoverStatCard(
                          label: 'Game Venues',
                          value: '$_uniqueVenueCount',
                          icon: Icons.location_on_outlined,
                          onTap: _showGameVenuesSheet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openCreateSessionDialog,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create Session'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFAA00FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Divider(color: Colors.white12, height: 24),
                    if (_sessionsError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _sessionsError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if (_isLoadingSessions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_isLoadingSessions && _sessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No sessions yet. Create one to get started.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ..._sessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DiscoverSessionCard(
                          gameType: session.gameType,
                          sessionType: session.sessionType,
                          name: session.name,
                          host: session.host,
                          date: session.date,
                          players: session.players,
                          venue: session.venue,
                        ),
                      ),
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

class _SessionItem {
  const _SessionItem({
    required this.gameType,
    required this.sessionType,
    required this.name,
    required this.host,
    required this.date,
    required this.players,
    required this.venue,
  });

  final String gameType;
  final String sessionType;
  final String name;
  final String host;
  final String date;
  final String players;
  final String venue;

  factory _SessionItem.fromMap(Map<String, dynamic> json) {
    return _SessionItem(
      gameType: (json['gameType'] as String?) ?? 'Unknown',
      sessionType: (json['sessionType'] as String?) ?? 'Session',
      name: (json['name'] as String?) ?? 'Untitled Session',
      host: (json['host'] as String?) ?? 'Unknown Host',
      date: (json['date'] as String?) ?? 'Date TBD',
      players: (json['players'] as String?) ?? 'Players TBD',
      venue: (json['venue'] as String?) ?? 'Venue TBD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'sessionType': sessionType,
      'name': name,
      'host': host,
      'date': date,
      'players': players,
      'venue': venue,
    };
  }
}

class _StatSheetEmptyState extends StatelessWidget {
  const _StatSheetEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog();

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _dateController = TextEditingController();
  final _playersController = TextEditingController();
  final _venueController = TextEditingController();

  String _selectedGameType = 'DND';
  String _selectedSessionType = 'Campaign';

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _dateController.dispose();
    _playersController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF2D1B4E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFAA00FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF241340),
      title: const Text(
        'Create Session',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedGameType,
                dropdownColor: const Color(0xFF2D1B4E),
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Game Type'),
                items: const [
                  DropdownMenuItem(value: 'DND', child: Text('DND')),
                  DropdownMenuItem(value: 'MTG', child: Text('MTG')),
                  DropdownMenuItem(value: 'Warhammer', child: Text('Warhammer')),
                  DropdownMenuItem(value: 'Board Games', child: Text('Board Games')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGameType = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSessionType,
                dropdownColor: const Color(0xFF2D1B4E),
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Session Type'),
                items: const [
                  DropdownMenuItem(value: 'Campaign', child: Text('Campaign')),
                  DropdownMenuItem(value: 'One Shot', child: Text('One Shot')),
                  DropdownMenuItem(value: 'Casual', child: Text('Casual')),
                  DropdownMenuItem(value: 'Competitive', child: Text('Competitive')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSessionType = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Session Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a session name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _hostController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Host Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a host name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Date and Time'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter date and time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _playersController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Players (e.g. 3-5 players)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter player range';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _venueController,
                style: const TextStyle(color: Colors.white),
                decoration: _dialogInputDecoration('Venue'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter venue';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              _SessionItem(
                gameType: _selectedGameType,
                sessionType: _selectedSessionType,
                name: _nameController.text.trim(),
                host: _hostController.text.trim(),
                date: _dateController.text.trim(),
                players: _playersController.text.trim(),
                venue: _venueController.text.trim(),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
