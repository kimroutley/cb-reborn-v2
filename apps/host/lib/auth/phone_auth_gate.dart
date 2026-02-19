import 'dart:async';

import 'package:cb_comms/cb_comms.dart';
import 'package:app_links/app_links.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cb_models/cb_models.dart';

class PhoneAuthGate extends StatefulWidget {
  const PhoneAuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<PhoneAuthGate> createState() => _PhoneAuthGateState();
}

class _PhoneAuthGateState extends State<PhoneAuthGate> {
  static const _pendingEmailKey = 'host_email_link_pending_email';

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  StreamSubscription<Uri>? _authLinkSubscription;

  bool _isSendingLink = false;
  bool _isCompletingLink = false;
  bool _isLinkSent = false;
  bool _isSavingUsername = false;
  GameStyle? _selectedStyle;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initEmailLinkHandling();
  }

  @override
  void dispose() {
    _authLinkSubscription?.cancel();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  ActionCodeSettings _buildActionCodeSettings() {
    return ActionCodeSettings(
      url: 'https://cb-reborn.web.app/email-link-signin?app=host',
      handleCodeInApp: true,
      androidPackageName: 'com.clubblackout.cb_host',
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: 'com.clubblackout.cbHost',
    );
  }

  Future<void> _initEmailLinkHandling() async {
    final appLinks = AppLinks();

    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      await _tryCompleteEmailLink(initialUri.toString());
    }

    _authLinkSubscription = appLinks.uriLinkStream.listen((uri) {
      _tryCompleteEmailLink(uri.toString());
    });

    await _tryCompleteEmailLink(Uri.base.toString());
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

  Future<void> _tryCompleteEmailLink(String link) async {
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
        isHost: true,
        preferredStyle: _selectedStyle?.name,
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
      _selectedStyle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null || user.email == null) {
          if (_selectedStyle == null) {
            return _buildStyleSelection(context);
          }

          final currentLink = Uri.base.toString();
          final isSignInLink =
              FirebaseAuth.instance.isSignInWithEmailLink(currentLink);

          return Scaffold(
            appBar: AppBar(
              title: const Text('HOST COMMAND'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: CBNeonBackground(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CBFadeSlide(
                        key: const ValueKey('host_login_header'),
                        child: Column(
                          children: [
                            Icon(Icons.vpn_key_rounded,
                                color: scheme.primary, size: 64),
                            const SizedBox(height: 24),
                            Text(
                              'ESTABLISH IDENTITY',
                              style: textTheme.displaySmall!.copyWith(
                                color: scheme.primary,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w900,
                                shadows: CBColors.textGlow(scheme.primary),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'SECURE SIGN-IN REQUIRED FOR ${_selectedStyle!.label}',
                              style: textTheme.labelSmall!.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.4),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      CBFadeSlide(
                        key: const ValueKey('host_login_form'),
                        delay: const Duration(milliseconds: 200),
                        child: CBPanel(
                          borderColor: scheme.primary.withValues(alpha: 0.4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CBTextField(
                                controller: _emailController,
                                hintText: 'SECURE EMAIL ADDRESS',
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: scheme.primary),
                                ),
                              ),
                              const SizedBox(height: 24),
                              CBPrimaryButton(
                                label: _isSendingLink
                                    ? 'SENDING ENCRYPTED LINK...'
                                    : (_isLinkSent
                                        ? 'RESEND ACCESS LINK'
                                        : 'SEND SIGN-IN LINK'),
                                onPressed: (_isSendingLink || _isCompletingLink)
                                    ? null
                                    : _sendEmailLink,
                              ),
                              if (isSignInLink) ...[
                                const SizedBox(height: 16),
                                CBGhostButton(
                                  label: 'COMPLETE AUTHENTICATION',
                                  onPressed: _isCompletingLink
                                      ? null
                                      : () => _completeEmailLinkSignIn(
                                          currentLink, _emailController.text),
                                  color: scheme.tertiary,
                                ),
                              ],
                              if (_isLinkSent) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'SIGN-IN LINK SENT. CHECK YOUR EMAIL AND OPEN IT HERE.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall!.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall!
                                      .copyWith(color: scheme.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      CBFadeSlide(
                        key: const ValueKey('host_login_back'),
                        delay: const Duration(milliseconds: 400),
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _selectedStyle = null),
                          child: Text(
                            "CHANGE HOSTING PERSONALITY",
                            style: textTheme.labelSmall!.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.3),
                              letterSpacing: 1.0,
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

        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return Scaffold(
                body: CBNeonBackground(
                  child: Center(child: CBBreathingSpinner()),
                ),
              );
            }

            final profile = profileSnapshot.data;
            final username = (profile?['username'] as String?)?.trim();
            if (username != null && username.isNotEmpty) {
              return widget.child;
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('IDENTITY REGISTRATION'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: CBNeonBackground(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: CBPanel(
                      borderColor: scheme.secondary,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('WELCOME, AGENT',
                              style: textTheme.headlineSmall!
                                  .copyWith(color: scheme.secondary)),
                          const SizedBox(height: 16),
                          Text(
                            'CHOOSE YOUR HOST MONIKER. THIS WILL BE YOUR PUBLIC IDENTITY IN THE CLUB.',
                            style: textTheme.bodySmall!.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 32),
                          CBTextField(
                            controller: _usernameController,
                            hintText: 'HOST USERNAME',
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline,
                                  color: scheme.secondary),
                            ),
                          ),
                          const SizedBox(height: 32),
                          CBPrimaryButton(
                            label: _isSavingUsername
                                ? 'ENCRYPTING...'
                                : 'SAVE IDENTITY',
                            onPressed: _isSavingUsername
                                ? null
                                : () => _saveUsername(user),
                          ),
                          const SizedBox(height: 12),
                          CBGhostButton(
                            label: 'USE DIFFERENT ACCOUNT',
                            onPressed: _signOut,
                            color: scheme.tertiary,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall!
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

  Widget _buildStyleSelection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: CBNeonBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CBFadeSlide(
                  key: const ValueKey('style_header'),
                  child: Column(
                    children: [
                      const CBRoleAvatar(
                          color: CBColors.neonPurple, size: 80, pulsing: true),
                      const SizedBox(height: 24),
                      Text(
                        'SELECT HOSTING PERSONALITY',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall!.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          shadows: CBColors.textGlow(scheme.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'YOUR CHOICE INFLUENCES THE NARRATIVE STYLE OF THE GAME.',
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                CBFadeSlide(
                  key: const ValueKey('style_options'),
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: GameStyle.values
                        .map((style) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: CBGlassTile(
                                isSelected: _selectedStyle == style,
                                onTap: () =>
                                    setState(() => _selectedStyle = style),
                                child: ListTile(
                                  title: Text(style.label),
                                  subtitle: Text(style.description),
                                ),
                              ),
                            ))
                        .toList(),
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
