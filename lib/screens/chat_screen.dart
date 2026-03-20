import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

part 'chat_screen_parts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final CollectionReference<Map<String, dynamic>> _conversationsRef =
      FirebaseFirestore.instance.collection('direct_conversations');

  String _conversationIdFor(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}__${sorted[1]}';
  }

  Future<void> _startConversation() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to message.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<_UserProfile>(
      context: context,
      backgroundColor: const Color(0xFF241340),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Direct Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('user_profiles')
                          .orderBy('displayName')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Unable to load users.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final users = snapshot.data!.docs
                            .map((doc) => _UserProfile.fromMap(doc.data()))
                            .where((profile) => profile.uid != currentUser.uid)
                            .toList();

                        if (users.isEmpty) {
                          return const Center(
                            child: Text(
                              'No other users found yet.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          itemCount: users.length,
                          separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return ListTile(
                              onTap: () => Navigator.of(context).pop(user),
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFAA00FF),
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.displayName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                user.email,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            );
                          },
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

    if (!mounted || selected == null) {
      return;
    }

    final currentName = currentUser.displayName?.trim();
    final safeCurrentName = (currentName != null && currentName.isNotEmpty)
        ? currentName
        : (currentUser.email ?? 'Adventurer');

    final conversationId = _conversationIdFor(currentUser.uid, selected.uid);

    await _conversationsRef.doc(conversationId).set({
      'participants': [currentUser.uid, selected.uid],
      'participantNames': {
        currentUser.uid: safeCurrentName,
        selected.uid: selected.displayName,
      },
      'participantEmails': {
        currentUser.uid: currentUser.email,
        selected.uid: selected.email,
      },
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    }, SetOptions(merge: true));

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DirectMessageScreen(
          conversationId: conversationId,
          peerUid: selected.uid,
          peerDisplayName: selected.displayName,
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 2) {
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.maps);
      return;
    }

    if (index == 0) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.discover);
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maps is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      bottomNavigationBar: DiscoverBottomNav(
        selected: 2,
        onTap: _handleBottomNavTap,
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
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Direct Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: currentUserUid == null
                    ? const Center(
                        child: Text(
                          'Sign in to use direct messages.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _conversationsRef
                            .where('participants', arrayContains: currentUserUid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'Unable to load conversations.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final conversations = List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(
                            snapshot.data!.docs,
                          )
                            ..sort((a, b) {
                              final aUpdated = a.data()['updatedAt'];
                              final bUpdated = b.data()['updatedAt'];

                              final aMillis = aUpdated is Timestamp
                                  ? aUpdated.millisecondsSinceEpoch
                                  : 0;
                              final bMillis = bUpdated is Timestamp
                                  ? bUpdated.millisecondsSinceEpoch
                                  : 0;

                              return bMillis.compareTo(aMillis);
                            });
                          if (conversations.isEmpty) {
                            return const Center(
                              child: Text(
                                'No conversations yet. Tap the button below to start one.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: conversations.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final data = conversations[index].data();
                              final names =
                                  (data['participantNames'] as Map<String, dynamic>?) ?? {};
                              final participants = ((data['participants'] as List<dynamic>?) ?? [])
                                  .whereType<String>()
                                  .toList();
                              final peerUid = participants.firstWhere(
                                (uid) => uid != currentUserUid,
                                orElse: () => currentUserUid,
                              );
                              final peerName = (names[peerUid] as String?) ?? 'Adventurer';
                              final lastMessage = (data['lastMessage'] as String?) ?? '';

                              return Material(
                                color: const Color(0xFF2D1B4E),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => _DirectMessageScreen(
                                          conversationId: conversations[index].id,
                                          peerUid: peerUid,
                                          peerDisplayName: peerName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFFAA00FF),
                                          child: Text(
                                            peerName.isNotEmpty
                                                ? peerName[0].toUpperCase()
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
                                                peerName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                lastMessage.isEmpty
                                                    ? 'No messages yet'
                                                    : lastMessage,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white70),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.white54),
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
              Container(
                color: const Color(0xFF12071F),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _startConversation,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFAA00FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('Start Conversation'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
