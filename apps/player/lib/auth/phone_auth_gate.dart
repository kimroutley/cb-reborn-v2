import 'package:cb_theme/cb_theme.dart';
import 'package:cb_comms/cb_comms_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneAuthGate extends StatefulWidget {
  const PhoneAuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<PhoneAuthGate> createState() => _PhoneAuthGateState();
}

class _PhoneAuthGateState extends State<PhoneAuthGate> {
  static const _pendingEmailKey = 'player_email_link_pending_email';

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSendingLink = false;
  bool _isCompletingLink = false;
  bool _isLinkSent = false;
  bool _isSavingUsername = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryCompleteEmailLinkFromCurrentUrl();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  ActionCodeSettings _buildActionCodeSettings() {
    return ActionCodeSettings(
      url: 'https://cb-reborn.web.app/email-link-signin?app=player',
      handleCodeInApp: true,
      androidPackageName: 'com.clubblackout.cb_player',
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: 'com.clubblackout.cbPlayer',
    );
  }

  Future<void> _persistPendingEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, email);
  }

  Future<String?> _loadPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingEmailKey);
  }

  Future<void> _clearPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);
  }

  Future<void> _sendEmailLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _isSendingLink = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: _buildActionCodeSettings(),
      );
      await _persistPendingEmail(email);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLinkSent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Failed to send sign-in link.');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLink = false;
        });
      }
    }
  }

  Future<void> _tryCompleteEmailLinkFromCurrentUrl() async {
    final link = Uri.base.toString();
    if (!FirebaseAuth.instance.isSignInWithEmailLink(link)) {
      return;
    }

    final pendingEmail = await _loadPendingEmail();
    if (pendingEmail == null || pendingEmail.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Enter your email to complete sign-in.';
      });
      return;
    }

    await _completeEmailLinkSignIn(link, pendingEmail);
  }

  Future<void> _completeEmailLinkSignIn(String link, String email) async {
    setState(() {
      _isCompletingLink = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailLink(
        email: email.trim(),
        emailLink: link,
      );
      await _clearPendingEmail();
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message ?? 'Failed to complete sign-in link.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingLink = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _loadProfile(User user) async {
    final snap = await FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(user.uid)
        .get();
    return snap.data();
  }

  Future<void> _saveUsername(User user) async {
    final username = _usernameController.text.trim();
    if (username.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters.');
      return;
    }

    setState(() {
      _isSavingUsername = true;
      _error = null;
    });

    try {
      final repository =
          ProfileRepository(firestore: FirebaseFirestore.instance);
      final isAvailable = await repository.isUsernameAvailable(
        username,
        excludingUid: user.uid,
      );

      if (!isAvailable) {
        setState(() => _error = 'Username is already taken.');
        return;
      }

      await repository.upsertBasicProfile(
        uid: user.uid,
        username: username,
        email: user.email,
        isHost: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingUsername = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await _clearPendingEmail();
    if (!mounted) {
      return;
    }
    setState(() {
      _error = null;
      _emailController.clear();
      _isLinkSent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null || user.email == null) {
          final currentLink = Uri.base.toString();
          final isSignInLink =
              FirebaseAuth.instance.isSignInWithEmailLink(currentLink);

          return Scaffold(
            appBar: AppBar(
              title: const Text('PLAYER LOGIN'),
            ),
            body: CBNeonBackground(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: CBPanel(
                    borderColor: scheme.primary,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Player Sign In',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'ll email you a secure sign-in link.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CBTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        CBPrimaryButton(
                          label: _isSendingLink
                              ? 'Sending Link...'
                              : (_isLinkSent
                                  ? 'Resend Link'
                                  : 'Send Sign-In Link'),
                          onPressed: (_isSendingLink || _isCompletingLink)
                              ? null
                              : _sendEmailLink,
                        ),
                        if (isSignInLink) ...[
                          const SizedBox(height: 8),
                          CBTextButton(
                            label: _isCompletingLink
                                ? 'Completing Sign-In...'
                                : 'Complete Sign-In With This Link',
                            onPressed: _isCompletingLink
                                ? null
                                : () {
                                    final email = _emailController.text.trim();
                                    if (email.isEmpty || !email.contains('@')) {
                                      setState(() {
                                        _error =
                                            'Enter your email to complete sign-in.';
                                      });
                                      return;
                                    }
                                    _completeEmailLinkSignIn(
                                        currentLink, email);
                                  },
                          ),
                        ],
                        if (_isLinkSent) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Check your inbox and open the sign-in link on this device.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: scheme.onSurface
                                          .withAlpha((255 * 0.75).round()),
                                    ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(color: scheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            final username = (profile?['username'] as String?)?.trim();
            if (username != null && username.isNotEmpty) {
              return widget.child;
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('CREATE USERNAME'),
              ),
              body: CBNeonBackground(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: CBPanel(
                      borderColor: scheme.secondary,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              'Welcome ${ProfileRepository.maskEmail(user.email)}',
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a unique username linked to this account.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          CBTextField(
                            controller: _usernameController,
                            hintText: 'Username',
                          ),
                          const SizedBox(height: 12),
                          CBPrimaryButton(
                            label: _isSavingUsername
                                ? 'Saving...'
                                : 'Save Username',
                            onPressed: _isSavingUsername
                                ? null
                                : () => _saveUsername(user),
                          ),
                          const SizedBox(height: 8),
                          CBTextButton(
                            label: 'Use different account',
                            onPressed: _signOut,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(color: scheme.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
