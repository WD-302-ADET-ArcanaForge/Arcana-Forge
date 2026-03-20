part of 'discover_screen.dart';

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
    required this.venueType,
    required this.province,
    this.createdByUid,
    required this.joinedUids,
    this.maxPlayers,
    required this.isActive,
  });

  final String? id;
  final String gameType;
  final String sessionType;
  final String name;
  final String host;
  final String date;
  final String players;
  final String venue;
  final String venueType;
  final String province;
  final String? createdByUid;
  final List<String> joinedUids;
  final int? maxPlayers;
  final bool isActive;

  factory _SessionItem.fromMap(String id, Map<String, dynamic> json) {
    final playersText = (json['players'] as String?) ?? 'Players TBD';
    final maxPlayers = (json['maxPlayers'] as int?) ?? _parseMaxPlayers(playersText);

    return _SessionItem(
      id: id,
      gameType: (json['gameType'] as String?) ?? 'Unknown',
      sessionType: (json['sessionType'] as String?) ?? 'Session',
      name: (json['name'] as String?) ?? 'Untitled Session',
      host: (json['host'] as String?) ?? 'Unknown Host',
      date: (json['date'] as String?) ?? 'Date TBD',
      players: playersText,
      venue: (json['venue'] as String?) ?? 'Venue TBD',
      venueType: (json['venueType'] as String?) ?? 'in_person',
      province: (json['province'] as String?) ?? '',
      createdByUid: json['createdByUid'] as String?,
      joinedUids: ((json['joinedUids'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      maxPlayers: maxPlayers,
      isActive: (json['isActive'] as bool?) ?? true,
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
      'venueType': venueType,
      'province': province,
      'joinedUids': joinedUids,
      'maxPlayers': maxPlayers,
      'isActive': isActive,
    };
  }

  static int? _parseMaxPlayers(String playersText) {
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
}

enum _JoinSessionResult {
  joined,
  alreadyJoined,
  full,
  notFound,
  failed,
}

class _UserProfileItem {
  const _UserProfileItem({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.province,
    required this.favoriteGames,
  });

  final String? uid;
  final String displayName;
  final String email;
  final String bio;
  final String province;
  final List<String> favoriteGames;

  factory _UserProfileItem.fromMap(String docId, Map<String, dynamic> json) {
    final displayName = (json['displayName'] as String?)?.trim();
    final email = (json['email'] as String?)?.trim();
    final bio = (json['bio'] as String?)?.trim();
    final province = (json['province'] as String?)?.trim();
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
      province: province ?? '',
      favoriteGames: favoriteGames,
    );
  }
}

enum _SearchScope {
  all,
  profiles,
  sessions,
}

enum _VenueType {
  inPerson,
  online,
  hybrid,
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
    required this.venueType,
    required this.province,
  });

  final String gameType;
  final String sessionType;
  final String name;
  final String host;
  final String date;
  final String players;
  final String venue;
  final String venueType;
  final String province;

  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType,
      'sessionType': sessionType,
      'name': name,
      'host': host,
      'date': date,
      'players': players,
      'venue': venue,
      'venueType': venueType,
      'province': province,
    };
  }
}

class _DiscoverFilterDraft {
  const _DiscoverFilterDraft({
    required this.gameTypes,
    required this.sessionTypes,
    required this.venueTypes,
    required this.onlyJoinable,
  });

  final Set<String> gameTypes;
  final Set<String> sessionTypes;
  final Set<String> venueTypes;
  final bool onlyJoinable;
}
