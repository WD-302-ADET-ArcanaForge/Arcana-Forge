import 'package:arcana_forge/config/app_routes.dart';
import 'package:arcana_forge/services/auth_service.dart';
import 'package:arcana_forge/widgets/arcana_logo.dart';
import 'package:arcana_forge/widgets/discover_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _favoriteGamesController = TextEditingController();

  bool _isSigningOut = false;
  bool _isProfileLoading = true;
  bool _isSavingProfile = false;
  String? _profileError;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _favoriteGamesController.dispose();
    super.dispose();
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) {
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.maps);
      return;
    }

    if (index == 2) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.chat);
      return;
    }

    if (index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.discover);
      return;
    }
  }

  Future<void> _loadProfile() async {
    final user = _currentUser;
    if (user == null) {
      setState(() {
        _isProfileLoading = false;
        _profileError = 'Sign in to view your profile.';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).get();
      final data = doc.data();

      final displayName = (data?['displayName'] as String?)?.trim();
      final bio = (data?['bio'] as String?)?.trim();
      final favoriteGames = (data?['favoriteGames'] as List<dynamic>?)
          ?.whereType<String>()
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList();

      _displayNameController.text = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : ((user.displayName?.trim().isNotEmpty == true)
                ? user.displayName!.trim()
                : (user.email ?? 'Adventurer'));
      _bioController.text = bio ?? '';
      _favoriteGamesController.text = favoriteGames == null ? '' : favoriteGames.join(', ');

      setState(() {
        _isProfileLoading = false;
        _profileError = null;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _isProfileLoading = false;
        _profileError = e.message ?? 'Unable to load profile.';
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();
    final favoriteGames = _favoriteGamesController.text
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required.')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'bio': bio,
        'favoriteGames': favoriteGames,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user.updateDisplayName(displayName);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to save profile.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await widget.authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign out right now.')),
      );
      setState(() => _isSigningOut = false);
    }
  }

  Widget _buildMySessionsSection() {
    final user = _currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('createdByUid', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Unable to load your sessions.',
            style: TextStyle(color: Colors.white70),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;
        final hostedCount = docs.length;

        final cards = docs
            .map((doc) {
              final data = doc.data();
              final name = (data['name'] as String?) ?? 'Untitled Session';
              final date = (data['date'] as String?) ?? 'Date TBD';
              final venue = (data['venue'] as String?) ?? 'Venue TBD';
              return _SessionSummary(name: name, date: date, venue: venue);
            })
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'My Sessions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAA00FF).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFAA00FF).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '$hostedCount hosted',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const Text(
                'No hosted sessions yet.',
                style: TextStyle(color: Colors.white70),
              )
            else
              ...cards.map(
                (session) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1B4E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session.date} • ${session.venue}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      bottomNavigationBar: DiscoverBottomNav(
        selected: 3,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    const ArcanaLogo(titleSize: 28, iconSize: 32),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _isProfileLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D1652).withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFF9D74D8).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: const Color(0xFFAA00FF),
                                          child: Text(
                                            (_displayNameController.text.isNotEmpty
                                                    ? _displayNameController.text[0]
                                                    : 'A')
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _displayNameController.text.isEmpty
                                                    ? 'Adventurer Profile'
                                                    : _displayNameController.text,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                user?.email ?? 'No email',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_profileError != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Text(
                                          _profileError!,
                                          style: const TextStyle(color: Colors.redAccent),
                                        ),
                                      ),
                                    TextField(
                                      controller: _displayNameController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('Display Name'),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _bioController,
                                      maxLines: 3,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('Bio'),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _favoriteGamesController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration('Favorite Games (comma separated)'),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _isSavingProfile ? null : _saveProfile,
                                        icon: _isSavingProfile
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.save_outlined),
                                        label: Text(_isSavingProfile ? 'Saving...' : 'Save Profile'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFFAA00FF),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D1652).withValues(alpha: 0.68),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: _buildMySessionsSection(),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                ),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE32F95), Color(0xFF9F3EF0)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDF3A9E).withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _isSigningOut ? null : _handleSignOut,
                      child: Center(
                        child: _isSigningOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
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
}

class _SessionSummary {
  const _SessionSummary({
    required this.name,
    required this.date,
    required this.venue,
  });

  final String name;
  final String date;
  final String venue;
}
