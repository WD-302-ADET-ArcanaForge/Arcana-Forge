import 'package:arcana_forge/config/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

part 'account_security_parts.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _isProcessing = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  bool get _hasPasswordProvider {
    final user = _currentUser;
    if (user == null) {
      return false;
    }

    return user.providerData.any((provider) => provider.providerId == 'password');
  }

  String _authMessageForCode(String code, String fallback) {
    switch (code) {
      case 'requires-recent-login':
        return 'Please log in again, then retry this security action.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Your current password is incorrect.';
      case 'email-already-in-use':
        return 'That email is already in use by another account.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return fallback;
    }
  }

  Future<void> _reauthenticateIfNeeded(String password) async {
    final user = _currentUser;
    if (user == null || !_hasPasswordProvider) {
      return;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'This account does not have an email address.',
      );
    }

    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _showChangeEmailDialog() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final newEmailController = TextEditingController();
    final currentPasswordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241340),
        title: const Text('Change Email', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newEmailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'New email',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            if (_hasPasswordProvider) ...[
              const SizedBox(height: 10),
              TextField(
                controller: currentPasswordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update Email'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final newEmail = newEmailController.text.trim();
    final currentPassword = currentPasswordController.text;

    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New email is required.')),
      );
      return;
    }

    if (_hasPasswordProvider && currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password is required.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _reauthenticateIfNeeded(currentPassword);
      await user.updateEmail(newEmail);

      await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).set({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated successfully.')),
      );
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authMessageForCode(e.code, e.message ?? 'Unable to update email.'),
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to update email.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    if (!_hasPasswordProvider) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changes are unavailable for this sign-in method.')),
      );
      return;
    }

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241340),
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All password fields are required.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirmation do not match.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _reauthenticateIfNeeded(currentPassword);
      await _currentUser!.updatePassword(newPassword);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authMessageForCode(e.code, e.message ?? 'Unable to update password.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final currentPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241340),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account and profile. Type DELETE to confirm.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Type DELETE',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            if (_hasPasswordProvider) ...[
              const SizedBox(height: 10),
              TextField(
                controller: currentPasswordController,
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final confirmation = confirmController.text.trim();
    final currentPassword = currentPasswordController.text;

    if (confirmation != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type DELETE to confirm.')),
      );
      return;
    }

    if (_hasPasswordProvider && currentPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password is required.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _reauthenticateIfNeeded(currentPassword);
      await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).delete();
      await user.delete();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authMessageForCode(e.code, e.message ?? 'Unable to delete account.'),
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to delete account.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _signOutCurrentDevice() async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseAuth.instance.signOut();
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
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      appBar: AppBar(
        title: const Text('Account & Security'),
        backgroundColor: const Color(0xFF2B154D),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1652).withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signed in email',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'No email available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SecurityActionTile(
                icon: Icons.alternate_email,
                title: 'Change Email',
                subtitle: 'Update your sign-in email address.',
                onTap: _isProcessing ? null : _showChangeEmailDialog,
              ),
              _SecurityActionTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: _hasPasswordProvider
                    ? 'Update your password.'
                    : 'Unavailable for this sign-in method.',
                onTap: (_isProcessing || !_hasPasswordProvider)
                    ? null
                    : _showChangePasswordDialog,
              ),
              _SecurityActionTile(
                icon: Icons.logout,
                title: 'Sign Out Current Device',
                subtitle: 'Sign out from this device now.',
                onTap: _isProcessing ? null : _signOutCurrentDevice,
              ),
              _SecurityActionTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account and profile data.',
                titleColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: _isProcessing ? null : _showDeleteAccountDialog,
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
