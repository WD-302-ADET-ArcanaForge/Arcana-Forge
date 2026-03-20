import 'dart:async';
import 'dart:convert';

import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/widgets/arcana_logo.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:arcana_forge/widgets/discover_session_card.dart';
import 'package:arcana_forge/widgets/discover_stat_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

part 'discover_models.dart';
part 'discover_dialogs.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _selectedNav = 0;

  final List<_SessionItem> _sessions = [];
  final List<_SessionItem> _endedSessions = [];
  final List<_UserProfileItem> _profiles = [];
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _SearchScope _searchScope = _SearchScope.all;
  Set<String> _selectedGameTypeFilters = {};
  Set<String> _selectedSessionTypeFilters = {};
  Set<String> _selectedVenueTypeFilters = {};
  bool _onlyJoinableSessions = false;

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

          final allSessions = snapshot.docs
              .map((doc) => _SessionItem.fromMap(doc.id, doc.data()))
              .toList();

          setState(() {
            _sessions
              ..clear()
              ..addAll(
                allSessions.where((session) => session.isActive),
              );
            _endedSessions
              ..clear()
              ..addAll(
                allSessions.where((session) => !session.isActive),
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

  int get _activeFilterCount {
    final joinableCount = _onlyJoinableSessions ? 1 : 0;
    return _selectedGameTypeFilters.length +
        _selectedSessionTypeFilters.length +
        _selectedVenueTypeFilters.length +
        joinableCount;
  }

  bool get _hasActiveFilters => _activeFilterCount > 0;

  List<String> get _availableGameTypeFilters {
    final values = _sessions
        .map((session) => session.gameType.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<String> get _availableSessionTypeFilters {
    final values = _sessions
        .map((session) => session.sessionType.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<String> get _availableVenueTypeFilters {
    final values = _sessions
        .map((session) => session.venueType.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  String _labelForVenueType(String type) {
    switch (type) {
      case 'online':
        return 'Online';
      case 'hybrid':
        return 'Hybrid';
      case 'in_person':
      default:
        return 'In-Person';
    }
  }

  bool _sessionMatchesFilters(_SessionItem session) {
    if (_selectedGameTypeFilters.isNotEmpty &&
        !_selectedGameTypeFilters.contains(session.gameType)) {
      return false;
    }

    if (_selectedSessionTypeFilters.isNotEmpty &&
        !_selectedSessionTypeFilters.contains(session.sessionType)) {
      return false;
    }

    if (_selectedVenueTypeFilters.isNotEmpty &&
        !_selectedVenueTypeFilters.contains(session.venueType)) {
      return false;
    }

    if (_onlyJoinableSessions) {
      if (!_isJoinEnabledFor(session)) {
        return false;
      }
    }

    return true;
  }

  List<_SessionItem> get _visibleSessions {
    final filteredSessions = _sessions.where(_sessionMatchesFilters).toList();

    if (!_isSearching) {
      return filteredSessions;
    }

    final query = _normalizedSearchQuery;
    return filteredSessions.where((session) {
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

  String _normalizeProvince(String value) {
    return value.trim().toLowerCase();
  }

  String? get _currentUserProvince {
    final uid = _currentUserUid;
    if (uid == null) {
      return null;
    }

    for (final profile in _profiles) {
      if (profile.uid != uid) {
        continue;
      }

      final province = profile.province.trim();
      if (province.isEmpty) {
        return null;
      }
      return province;
    }

    return null;
  }

  List<_SessionItem> get _sessionsInCurrentProvince {
    final province = _currentUserProvince;
    if (province == null) {
      return const [];
    }

    final normalizedProvince = _normalizeProvince(province);
    return _sessions.where((session) {
      final sessionProvince = _normalizeProvince(session.province);
      if (sessionProvince.isEmpty) {
        return false;
      }
      return sessionProvince == normalizedProvince;
    }).toList();
  }

  String _conversationIdFor(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  int? _extractMaxPlayers(String playersText) {
    final matches = RegExp(r'\d+').allMatches(playersText);
    if (matches.isEmpty) {
      return null;
    }

    final values = matches
        .map((match) => int.tryParse(match.group(0) ?? ''))
        .whereType<int>()
        .toList();

    if (values.isEmpty) {
      return null;
    }

    values.sort();
    return values.last;
  }

  bool _isJoinedByCurrentUser(_SessionItem session) {
    final uid = _currentUserUid;
    if (uid == null) {
      return false;
    }
    return session.joinedUids.contains(uid);
  }

  bool _isSessionFull(_SessionItem session) {
    final maxPlayers = session.maxPlayers;
    if (maxPlayers == null) {
      return false;
    }
    return session.joinedUids.length >= maxPlayers;
  }

  String _playersLabelFor(_SessionItem session) {
    final maxPlayers = session.maxPlayers;
    if (maxPlayers == null) {
      return session.players;
    }

    return '${session.joinedUids.length}/$maxPlayers players';
  }

  String _venueLabelFor(_SessionItem session) {
    switch (session.venueType) {
      case 'online':
        return 'Online: ${session.venue}';
      case 'hybrid':
        return 'Hybrid: ${session.venue}';
      case 'in_person':
      default:
        return session.venue;
    }
  }

  String _joinButtonLabelFor(_SessionItem session) {
    if (_isJoinedByCurrentUser(session)) {
      return 'Joined';
    }

    if (_isSessionFull(session)) {
      return 'Session Full';
    }

    return 'Join Session >';
  }

  bool _isJoinEnabledFor(_SessionItem session) {
    final uid = _currentUserUid;
    if (uid == null) {
      return false;
    }

    return !_isJoinedByCurrentUser(session) && !_isSessionFull(session);
  }

  Future<void> _joinSession(_SessionItem session) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to join a session.')),
      );
      return;
    }

    final sessionId = session.id;
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to join this session.')),
      );
      return;
    }

    _JoinSessionResult result = _JoinSessionResult.failed;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final sessionDoc = _sessionsRef.doc(sessionId);
        final snapshot = await transaction.get(sessionDoc);

        if (!snapshot.exists) {
          result = _JoinSessionResult.notFound;
          return;
        }

        final data = snapshot.data() ?? <String, dynamic>{};
        final joinedUids = ((data['joinedUids'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<String>()
            .toList();

        if (joinedUids.contains(currentUser.uid)) {
          result = _JoinSessionResult.alreadyJoined;
          return;
        }

        final playersText = (data['players'] as String?) ?? '';
        final maxPlayers = (data['maxPlayers'] as int?) ?? _extractMaxPlayers(playersText);

        if (maxPlayers != null && joinedUids.length >= maxPlayers) {
          result = _JoinSessionResult.full;
          return;
        }

        joinedUids.add(currentUser.uid);
        transaction.update(sessionDoc, {
          'joinedUids': joinedUids,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        result = _JoinSessionResult.joined;
      });
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to join session.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    switch (result) {
      case _JoinSessionResult.joined:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You joined "${session.name}".')),
        );
        break;
      case _JoinSessionResult.alreadyJoined:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already joined this session.')),
        );
        break;
      case _JoinSessionResult.full:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This session is full.')),
        );
        break;
      case _JoinSessionResult.notFound:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session no longer exists.')),
        );
        break;
      case _JoinSessionResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to join session.')),
        );
        break;
    }
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

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_DiscoverFilterDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF241340),
      builder: (_) => _DiscoverFilterSheet(
        selectedGameTypes: _selectedGameTypeFilters,
        selectedSessionTypes: _selectedSessionTypeFilters,
        selectedVenueTypes: _selectedVenueTypeFilters,
        onlyJoinableSessions: _onlyJoinableSessions,
        availableGameTypes: _availableGameTypeFilters,
        availableSessionTypes: _availableSessionTypeFilters,
        availableVenueTypes: _availableVenueTypeFilters,
        venueTypeLabelBuilder: _labelForVenueType,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedGameTypeFilters = result.gameTypes;
      _selectedSessionTypeFilters = result.sessionTypes;
      _selectedVenueTypeFilters = result.venueTypes;
      _onlyJoinableSessions = result.onlyJoinable;
    });
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

  List<_SessionItem> get _myEndedSessions {
    final uid = _currentUserUid;
    if (uid == null) {
      return const [];
    }
    return _endedSessions.where((session) => session.createdByUid == uid).toList();
  }

  int get _uniqueVenueCount {
    return _sessionsInCurrentProvince
        .map((session) => session.venue.toLowerCase().trim())
        .toSet()
        .length;
  }

  List<String> get _knownVenueSuggestions {
    final seen = <String>{};
    final suggestions = <String>[];

    for (final session in [..._sessions, ..._endedSessions]) {
      final venue = session.venue.trim();
      if (venue.isEmpty) {
        continue;
      }

      final key = venue.toLowerCase();
      if (seen.add(key)) {
        suggestions.add(venue);
      }
    }

    suggestions.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return suggestions;
  }

  String _displayNameForUid(String uid) {
    for (final profile in _profiles) {
      if (profile.uid == uid) {
        return profile.displayName;
      }
    }
    return 'Player';
  }

  Future<void> _kickPlayerFromSession({
    required _SessionItem session,
    required String playerUid,
  }) async {
    final currentUserUid = _currentUserUid;
    if (currentUserUid == null || session.createdByUid != currentUserUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the host can manage players.')),
      );
      return;
    }

    if (session.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update this session.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final sessionDoc = _sessionsRef.doc(session.id);
        final snapshot = await transaction.get(sessionDoc);
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data() ?? <String, dynamic>{};
        final hostUid = data['createdByUid'] as String?;
        if (hostUid != currentUserUid) {
          return;
        }

        final joinedUids = ((data['joinedUids'] as List<dynamic>?) ?? const <dynamic>[])
            .whereType<String>()
            .toList();

        if (playerUid == hostUid) {
          return;
        }

        if (!joinedUids.contains(playerUid)) {
          return;
        }

        joinedUids.remove(playerUid);

        transaction.update(sessionDoc, {
          'joinedUids': joinedUids,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_displayNameForUid(playerUid)} was removed.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to remove player.')),
      );
    }
  }

  void _openManagePlayersSheet(_SessionItem session) {
    final currentUserUid = _currentUserUid;
    if (currentUserUid == null || session.createdByUid != currentUserUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the host can manage players.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF241340),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSession = _sessions.firstWhere(
              (item) => item.id == session.id,
              orElse: () => session,
            );

            final removablePlayers = currentSession.joinedUids
                .where((uid) => uid != currentSession.createdByUid)
                .toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Players: ${currentSession.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (removablePlayers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No joined players to remove.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: removablePlayers.length,
                        separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final playerUid = removablePlayers[index];
                          final displayName = _displayNameForUid(playerUid);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFAA00FF),
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              playerUid,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: TextButton.icon(
                              onPressed: () async {
                                final shouldKick = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF241340),
                                    title: const Text(
                                      'Remove Player',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      'Remove $displayName from this session?',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldKick != true) {
                                  return;
                                }

                                await _kickPlayerFromSession(
                                  session: currentSession,
                                  playerUid: playerUid,
                                );

                                if (!mounted) {
                                  return;
                                }

                                setModalState(() {});
                              },
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              label: const Text(
                                'Kick',
                                style: TextStyle(color: Colors.redAccent),
                              ),
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
      },
    );
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
      builder: (_) => _CreateSessionDialog(
        venueSuggestions: _knownVenueSuggestions,
      ),
    );

    if (!mounted || createdSession == null) {
      return;
    }

    try {
      final maxPlayers = _extractMaxPlayers(createdSession.players);

      await _sessionsRef.add({
        ...createdSession.toJson(),
        'maxPlayers': maxPlayers,
        'joinedUids': [currentUser.uid],
        'isActive': true,
        'province': createdSession.province,
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
                    final joinedCount = session.joinedUids.length;
                    final capacityLabel = session.maxPlayers == null
                        ? '$joinedCount joined'
                        : '$joinedCount/${session.maxPlayers} joined';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        session.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${session.gameType} • ${session.date} • ${_venueLabelFor(session)}\n$capacityLabel',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.group_outlined, color: Colors.white70),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _openManagePlayersSheet(session);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _editSession(session);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await _endSession(session);
                            },
                            tooltip: 'End Session',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openEndedSessionsSheet();
                  },
                  icon: const Icon(Icons.history, color: Colors.white70),
                  label: Text(
                    _myEndedSessions.isEmpty
                        ? 'View Ended Sessions'
                        : 'View Ended Sessions (${_myEndedSessions.length})',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEndedSessionsSheet() {
    final endedSessions = _myEndedSessions;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF241340),
      builder: (_) {
        if (endedSessions.isEmpty) {
          return const _StatSheetEmptyState(
            title: 'Ended Sessions',
            message: 'You have not ended any sessions yet.',
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ended Sessions',
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
                  itemCount: endedSessions.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                  itemBuilder: (context, index) {
                    final session = endedSessions[index];
                    final joinedCount = session.joinedUids.length;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                      title: Text(
                        session.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${session.gameType} • ${session.date} • ${_venueLabelFor(session)}\n$joinedCount joined',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      isThreeLine: true,
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
        venueSuggestions: _knownVenueSuggestions,
      ),
    );

    if (!mounted || updated == null) {
      return;
    }

    try {
      await _sessionsRef.doc(session.id).update({
        ...updated.toJson(),
        'maxPlayers': _extractMaxPlayers(updated.players),
        'province': updated.province,
      });
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

  Future<void> _endSession(_SessionItem session) async {
    if (session.id == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241340),
        title: const Text('End Session', style: TextStyle(color: Colors.white)),
        content: Text(
          'End "${session.name}"? This hides it from active discover lists.',
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
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    try {
      await _sessionsRef.doc(session.id).update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session "${session.name}" ended.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to end session.')),
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
                        '${session.gameType} • ${session.date} • ${_venueLabelFor(session)}',
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
    for (final session in _sessionsInCurrentProvince) {
      final venue = session.venue.trim();
      venues[venue] = (venues[venue] ?? 0) + 1;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF241340),
      builder: (context) {
        final province = _currentUserProvince;
        if (province == null) {
          return const _StatSheetEmptyState(
            title: 'Nearby Venues',
            message: 'Set your province in your profile to see nearby venues.',
          );
        }

        if (venues.isEmpty) {
          return _StatSheetEmptyState(
            title: 'Nearby Venues',
            message: 'No venues found in $province yet.',
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
                'Nearby Venues',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Province: $province',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: _hasActiveFilters
                                  ? const Color(0xFFD62EEA)
                                  : const Color(0xFFAA00FF),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _openFilterSheet,
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.filter_alt, color: Colors.white),
                                ),
                              ),
                            ),
                            if (_activeFilterCount > 0)
                              Positioned(
                                right: -4,
                                top: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$_activeFilterCount',
                                    style: const TextStyle(
                                      color: Color(0xFF4F1A7C),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                          label: 'Nearby Venues',
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
                                  players: _playersLabelFor(session),
                                  venue: _venueLabelFor(session),
                                  onJoin: () => _joinSession(session),
                                  joinLabel: _joinButtonLabelFor(session),
                                  isJoinEnabled: _isJoinEnabledFor(session),
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
                      if (!_isLoadingSessions && _visibleSessions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No sessions match your current filters. Try adjusting them.',
                            style: TextStyle(color: Colors.white70),
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
                            players: _playersLabelFor(session),
                            venue: _venueLabelFor(session),
                            onJoin: () => _joinSession(session),
                            joinLabel: _joinButtonLabelFor(session),
                            isJoinEnabled: _isJoinEnabledFor(session),
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
