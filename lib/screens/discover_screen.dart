import 'dart:async';

import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/widgets/arcana_logo.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:arcana_forge/widgets/discover_session_card.dart';
import 'package:arcana_forge/widgets/discover_stat_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _selectedNav = 0;

  final List<_SessionItem> _sessions = [];
  final List<_UserProfileItem> _profiles = [];
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _SearchScope _searchScope = _SearchScope.all;

  final CollectionReference<Map<String, dynamic>> _sessionsRef =
      FirebaseFirestore.instance.collection('sessions');
  final CollectionReference<Map<String, dynamic>> _profilesRef =
      FirebaseFirestore.instance.collection('user_profiles');

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _profilesSub;
  bool _isLoadingSessions = true;
  bool _isLoadingProfiles = true;
  String? _sessionsError;
  String? _profilesError;

  @override
  void initState() {
    super.initState();
    _listenToSessions();
    _listenToProfiles();
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
                snapshot.docs.map((doc) => _SessionItem.fromMap(doc.id, doc.data())),
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

  void _listenToProfiles() {
    _profilesSub = _profilesRef
        .orderBy('displayName')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) {
            return;
          }

          setState(() {
            _profiles
              ..clear()
              ..addAll(
                snapshot.docs.map((doc) => _UserProfileItem.fromMap(doc.id, doc.data())),
              );
            _isLoadingProfiles = false;
            _profilesError = null;
          });
        }, onError: (_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _isLoadingProfiles = false;
            _profilesError = 'Unable to load profiles from Firebase.';
          });
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sessionsSub?.cancel();
    _profilesSub?.cancel();
    super.dispose();
  }

  int get _activeSessionCount => _sessions.length;

  String? get _currentUserUid => FirebaseAuth.instance.currentUser?.uid;

  String get _normalizedSearchQuery => _searchQuery.trim().toLowerCase();

  bool get _isSearching => _normalizedSearchQuery.isNotEmpty;

  int get _nearbyPlayersCount {
    final currentUid = _currentUserUid;
    return _profiles.where((profile) => profile.uid != null && profile.uid != currentUid).length;
  }

  List<_SessionItem> get _visibleSessions {
    if (!_isSearching) {
      return _sessions;
    }

    final query = _normalizedSearchQuery;
    return _sessions.where((session) {
      return _matchesSearch(session.gameType, query) ||
          _matchesSearch(session.sessionType, query) ||
          _matchesSearch(session.name, query) ||
          _matchesSearch(session.host, query) ||
          _matchesSearch(session.date, query) ||
          _matchesSearch(session.players, query) ||
          _matchesSearch(session.venue, query);
    }).toList();
  }

  List<_UserProfileItem> get _visibleProfiles {
    final currentUid = _currentUserUid;
    final profiles = _profiles.where((profile) => profile.uid != null && profile.uid != currentUid);
    if (!_isSearching) {
      return profiles.toList();
    }

    final query = _normalizedSearchQuery;
    return profiles.where((profile) {
      return _matchesSearch(profile.displayName, query) ||
          _matchesSearch(profile.email, query) ||
          _matchesSearch(profile.bio, query) ||
          profile.favoriteGames.any((game) => _matchesSearch(game, query));
    }).toList();
  }

  bool _matchesSearch(String value, String query) {
    return value.toLowerCase().contains(query);
  }

  String _conversationIdFor(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  bool get _shouldShowProfilesInSearch {
    return _searchScope == _SearchScope.all || _searchScope == _SearchScope.profiles;
  }

  bool get _shouldShowSessionsInSearch {
    return _searchScope == _SearchScope.all || _searchScope == _SearchScope.sessions;
  }

  bool get _isSearchLoading {
    if (_searchScope == _SearchScope.profiles) {
      return _isLoadingProfiles;
    }

    if (_searchScope == _SearchScope.sessions) {
      return _isLoadingSessions;
    }

    return _isLoadingProfiles || _isLoadingSessions;
  }

  bool get _hasSearchResults {
    if (_searchScope == _SearchScope.profiles) {
      return _visibleProfiles.isNotEmpty;
    }

    if (_searchScope == _SearchScope.sessions) {
      return _visibleSessions.isNotEmpty;
    }

    return _visibleProfiles.isNotEmpty || _visibleSessions.isNotEmpty;
  }

  String get _searchEmptyMessage {
    if (_searchScope == _SearchScope.profiles) {
      return 'No profiles match your search.';
    }

    if (_searchScope == _SearchScope.sessions) {
      return 'No sessions match your search.';
    }

    return 'No profiles or sessions match your search.';
  }

  Future<void> _startConversationWithProfile(_UserProfileItem profile) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to start a direct message.')),
      );
      return;
    }

    if (profile.uid == null || profile.uid == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start a message with this profile.')),
      );
      return;
    }

    final currentName = currentUser.displayName?.trim();
    final safeCurrentName = (currentName != null && currentName.isNotEmpty)
        ? currentName
        : (currentUser.email ?? 'Adventurer');

    final conversationId = _conversationIdFor(currentUser.uid, profile.uid!);

    try {
      await FirebaseFirestore.instance.collection('direct_conversations').doc(conversationId).set({
        'participants': [currentUser.uid, profile.uid],
        'participantNames': {
          currentUser.uid: safeCurrentName,
          profile.uid: profile.displayName,
        },
        'participantEmails': {
          currentUser.uid: currentUser.email,
          profile.uid: profile.email,
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamed(AppRoutes.chat);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation with ${profile.displayName} started.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to start direct message.')),
      );
    }
  }

  void _openProfilePreview(_UserProfileItem profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF241340),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFAA00FF),
                    child: Text(
                      profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          profile.email,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (profile.bio.isNotEmpty) ...[
                const Text(
                  'Bio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.bio,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Favorite Games',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (profile.favoriteGames.isEmpty)
                const Text(
                  'No favorite games listed yet.',
                  style: TextStyle(color: Colors.white70),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.favoriteGames
                      .map(
                        (game) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D1B4E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFAA00FF).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            game,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  List<_SessionItem> get _mySessions {
    final uid = _currentUserUid;
    if (uid == null) {
      return const [];
    }
    return _sessions.where((session) => session.createdByUid == uid).toList();
  }

  int get _uniqueVenueCount {
    return _sessions.map((session) => session.venue.toLowerCase().trim()).toSet().length;
  }

  Future<void> _openCreateSessionDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a session.')),
      );
      return;
    }

    final createdSession = await showDialog<_SessionItemDraft>(
      context: context,
      builder: (_) => const _CreateSessionDialog(),
    );

    if (!mounted || createdSession == null) {
      return;
    }

    try {
      await _sessionsRef.add({
        ...createdSession.toJson(),
        'createdByUid': currentUser.uid,
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

  Future<void> _openManageSessionsDialog() async {
    if (_currentUserUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to manage your sessions.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF241340),
      builder: (sheetContext) {
        final sessions = _mySessions;
        if (sessions.isEmpty) {
          return const _StatSheetEmptyState(
            title: 'Manage Sessions',
            message: 'You have no sessions yet. Create one first.',
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage Sessions',
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
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _editSession(session);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _deleteSession(session);
                            },
                          ),
                        ],
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

  Future<void> _editSession(_SessionItem session) async {
    if (session.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to edit this session.')), 
      );
      return;
    }

    final updated = await showDialog<_SessionItemDraft>(
      context: context,
      builder: (_) => _CreateSessionDialog(
        title: 'Edit Session',
        submitLabel: 'Save',
        initialSession: session,
      ),
    );

    if (!mounted || updated == null) {
      return;
    }

    try {
      await _sessionsRef.doc(session.id).update(updated.toJson());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session "${updated.name}" updated.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to update session.')),
      );
    }
  }

  Future<void> _deleteSession(_SessionItem session) async {
    if (session.id == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241340),
        title: const Text('Delete Session', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${session.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    try {
      await _sessionsRef.doc(session.id).delete();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session "${session.name}" deleted.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to delete session.')),
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
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12),
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
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12),
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
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SegmentedButton<_SearchScope>(
                          segments: const [
                            ButtonSegment<_SearchScope>(
                              value: _SearchScope.all,
                              label: Text('All'),
                              icon: Icon(Icons.grid_view_rounded, size: 16),
                            ),
                            ButtonSegment<_SearchScope>(
                              value: _SearchScope.profiles,
                              label: Text('Profiles'),
                              icon: Icon(Icons.person_outline, size: 16),
                            ),
                            ButtonSegment<_SearchScope>(
                              value: _SearchScope.sessions,
                              label: Text('Sessions'),
                              icon: Icon(Icons.event_note_outlined, size: 16),
                            ),
                          ],
                          selected: {_searchScope},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _searchScope = selection.first;
                            });
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              return Colors.white70;
                            }),
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFFAA00FF);
                              }
                              return const Color(0xFF2D1B4E);
                            }),
                            side: WidgetStateProperty.all(
                              const BorderSide(color: Color(0xFFAA00FF), width: 1),
                            ),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D1B4E),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search games, events, players...',
                                hintStyle: TextStyle(color: Colors.white54),
                                prefixIcon: Icon(Icons.search, color: Colors.white54),
                                suffixIcon: _searchQuery.trim().isEmpty
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        icon: const Icon(Icons.close, color: Colors.white54),
                                      ),
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
                        DiscoverStatCard(
                          label: 'Nearby Players',
                          value: '$_nearbyPlayersCount',
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
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _openCreateSessionDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Create Session'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFAA00FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openManageSessionsDialog,
                            icon: const Icon(Icons.edit_calendar_outlined),
                            label: const Text('Manage Sessions'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFAA00FF)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    if (_isSearching)
                      ...[
                        if (_profilesError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _profilesError!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        if (_isSearchLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (!_hasSearchResults)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _searchEmptyMessage,
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else ...[
                          if (_shouldShowProfilesInSearch && _visibleProfiles.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Profiles',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ..._visibleProfiles.map(
                              (profile) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D1B4E),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFAA00FF),
                                      child: Text(
                                        profile.displayName.isNotEmpty
                                            ? profile.displayName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            profile.email,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (profile.bio.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                profile.bio,
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          if (profile.favoriteGames.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                'Games: ${profile.favoriteGames.join(', ')}',
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () => _openProfilePreview(profile),
                                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                                label: const Text('View'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(color: Color(0xFFAA00FF)),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              FilledButton.icon(
                                                onPressed: () => _startConversationWithProfile(profile),
                                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                                label: const Text('Message'),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: const Color(0xFFAA00FF),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_shouldShowSessionsInSearch && _visibleSessions.isNotEmpty)
                              const SizedBox(height: 10),
                          ],
                          if (_shouldShowSessionsInSearch && _visibleSessions.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Sessions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ..._visibleSessions.map(
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
                          ],
                        ],
                      ]
                    else ...[
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
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            DiscoverBottomNav(
              selected: _selectedNav,
              onTap: (i) {
                if (i == 1) {
                  Navigator.of(context).pushNamed(AppRoutes.maps);
                  return;
                }
                if (i == 2) {
                  Navigator.of(context).pushNamed(AppRoutes.chat);
                  return;
                }
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
    this.id,
    required this.gameType,
    required this.sessionType,
    required this.name,
    required this.host,
    required this.date,
    required this.players,
    required this.venue,
    this.createdByUid,
  });

  final String? id;
  final String gameType;
  final String sessionType;
  final String name;
  final String host;
  final String date;
  final String players;
  final String venue;
  final String? createdByUid;

  factory _SessionItem.fromMap(String id, Map<String, dynamic> json) {
    return _SessionItem(
      id: id,
      gameType: (json['gameType'] as String?) ?? 'Unknown',
      sessionType: (json['sessionType'] as String?) ?? 'Session',
      name: (json['name'] as String?) ?? 'Untitled Session',
      host: (json['host'] as String?) ?? 'Unknown Host',
      date: (json['date'] as String?) ?? 'Date TBD',
      players: (json['players'] as String?) ?? 'Players TBD',
      venue: (json['venue'] as String?) ?? 'Venue TBD',
      createdByUid: json['createdByUid'] as String?,
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

class _UserProfileItem {
  const _UserProfileItem({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.favoriteGames,
  });

  final String? uid;
  final String displayName;
  final String email;
  final String bio;
  final List<String> favoriteGames;

  factory _UserProfileItem.fromMap(String docId, Map<String, dynamic> json) {
    final displayName = (json['displayName'] as String?)?.trim();
    final email = (json['email'] as String?)?.trim();
    final bio = (json['bio'] as String?)?.trim();
    final favoriteGames = (json['favoriteGames'] as List<dynamic>?)
            ?.whereType<String>()
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty)
            .toList() ??
        const [];

    return _UserProfileItem(
      uid: (json['uid'] as String?) ?? docId,
      displayName: (displayName != null && displayName.isNotEmpty) ? displayName : 'Adventurer',
      email: (email != null && email.isNotEmpty) ? email : 'No email available',
      bio: bio ?? '',
      favoriteGames: favoriteGames,
    );
  }
}

enum _SearchScope {
  all,
  profiles,
  sessions,
}

class _SessionItemDraft {
  const _SessionItemDraft({
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
  const _CreateSessionDialog({
    this.title = 'Create Session',
    this.submitLabel = 'Create',
    this.initialSession,
  });

  final String title;
  final String submitLabel;
  final _SessionItem? initialSession;

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _dateController;
  late final TextEditingController _playersController;
  late final TextEditingController _venueController;

  late String _selectedGameType;
  late String _selectedSessionType;

  @override
  void initState() {
    super.initState();
    _selectedGameType = widget.initialSession?.gameType ?? 'DND';
    _selectedSessionType = widget.initialSession?.sessionType ?? 'Campaign';
    _nameController = TextEditingController(text: widget.initialSession?.name ?? '');
    _hostController = TextEditingController(text: widget.initialSession?.host ?? '');
    _dateController = TextEditingController(text: widget.initialSession?.date ?? '');
    _playersController = TextEditingController(text: widget.initialSession?.players ?? '');
    _venueController = TextEditingController(text: widget.initialSession?.venue ?? '');
  }

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
      title: Text(
        widget.title,
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedGameType,
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
                initialValue: _selectedSessionType,
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
              _SessionItemDraft(
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
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
