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
  static const Duration _completeLinkTimeout = Duration(seconds: 15);

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  StreamSubscription<Uri>? _authLinkSubscription;

  bool _isSendingLink = false;
  bool _isCompletingLink = false;
  bool _isLinkSent = false;
  bool _isSavingUsername = false;
  GameStyle? _selectedStyle;
  String? _error;
  String? _latestAuthLink;

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
      _latestAuthLink = initialUri.toString();
      await _tryCompleteEmailLink(initialUri.toString());
    }

    _authLinkSubscription = appLinks.uriLinkStream.listen((uri) {
      _latestAuthLink = uri.toString();
      _tryCompleteEmailLink(uri.toString());
    });

    final baseLink = Uri.base.toString();
    _latestAuthLink ??= baseLink;
    await _tryCompleteEmailLink(baseLink);
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
      setState(() => _error = 'ENTER A VALID EMAIL ADDRESS.');
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
      setState(() => _error = e.message?.toUpperCase() ?? 'FAILED TO SEND SIGN-IN LINK.');
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
        _error = 'ENTER YOUR EMAIL TO COMPLETE SIGN-IN.';
      });
      return;
    }

    await _completeEmailLinkSignIn(link, pendingEmail);
  }

  Future<void> _completeEmailLinkSignIn(String link, String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      setState(() {
        _error = 'ENTER THE SAME EMAIL USED TO REQUEST THE SIGN-IN LINK.';
      });
      return;
    }

    setState(() {
      _isCompletingLink = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance
          .signInWithEmailLink(
            email: normalizedEmail,
            emailLink: link,
          )
          .timeout(_completeLinkTimeout);
      await _clearPendingEmail();
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message?.toUpperCase() ?? 'FAILED TO COMPLETE SIGN-IN LINK.';
      });
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            'SIGN-IN CONFIRMATION TIMED OUT. RE-OPEN THE EMAIL LINK AND TRY AGAIN.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            'COULD NOT COMPLETE SIGN-IN. RE-OPEN THE LATEST EMAIL LINK AND RETRY.';
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
      setState(() => _error = 'USERNAME MUST BE AT LEAST 3 CHARACTERS.');
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
        setState(() => _error = 'USERNAME IS ALREADY TAKEN.');
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

          final currentLink = _latestAuthLink ?? Uri.base.toString();
          final isSignInLink =
              FirebaseAuth.instance.isSignInWithEmailLink(currentLink);

          return CBPrismScaffold(
            title: 'HOST COMMAND',
            body: Center(
              child: SingleChildScrollView(
                padding: CBInsets.panel,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    CBFadeSlide(
                        key: const ValueKey('host_login_header'),
                        child: Column(
                          children: [
                            Icon(Icons.vpn_key_rounded,
                                color: scheme.primary, size: 64),
                            const SizedBox(height: CBSpace.x6),
                            Text(
                              'ESTABLISH IDENTITY',
                              style: textTheme.displaySmall!.copyWith(
                                color: scheme.primary,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w900,
                                shadows: CBColors.textGlow(scheme.primary),
                              ),
                            ),
                            const SizedBox(height: CBSpace.x2),
                            Text(
                              'SECURE SIGN-IN REQUIRED FOR ${_selectedStyle!.label.toUpperCase()}',
                              style: textTheme.labelSmall!.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.4),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: CBSpace.x12),
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
                                prefixIcon: Icons.email_outlined,
                              ),
                              const SizedBox(height: CBSpace.x6),
                              CBPrimaryButton(
                                label: _isSendingLink
                                    ? 'SENDING ENCRYPTED LINK...'
                                    : (_isLinkSent
                                        ? 'RESEND ACCESS LINK'
                                        : 'SEND SIGN-IN LINK'),
                                onPressed: (_isSendingLink || _isCompletingLink)
                                    ? null
                                    : () {
                                        HapticService.medium();
                                        _sendEmailLink();
                                      },
                              ),
                              if (isSignInLink) ...[
                                const SizedBox(height: CBSpace.x4),
                                CBGhostButton(
                                  label: 'COMPLETE AUTHENTICATION',
                                  onPressed: _isCompletingLink
                                      ? null
                                      : () {
                                          HapticService.heavy();
                                          _completeEmailLinkSignIn(currentLink, _emailController.text);
                                        },
                                  color: scheme.tertiary,
                                ),
                              ],
                              if (_isLinkSent) ...[
                                const SizedBox(height: CBSpace.x4),
                                Text(
                                  'SIGN-IN LINK SENT. CHECK YOUR EMAIL AND OPEN IT HERE.',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall!.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: CBSpace.x4),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall!
                                      .copyWith(
                                        color: scheme.error,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: CBSpace.x8),
                      CBFadeSlide(
                        key: const ValueKey('host_login_back'),
                        delay: const Duration(milliseconds: 400),
                        child: CBTextButton(
                          label: 'CHANGE HOSTING PERSONALITY',
                          onPressed: () {
                            HapticService.light();
                            setState(() => _selectedStyle = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadProfile(user),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const CBPrismScaffold(
                title: '',
                showAppBar: false,
                body: Center(child: CBBreathingSpinner()),
              );
            }

            final profile = profileSnapshot.data;
            final username = (profile?['username'] as String?)?.trim();
            if (username != null && username.isNotEmpty) {
              return widget.child;
            }

            return CBPrismScaffold(
              title: 'IDENTITY REGISTRATION',
              body: Center(
                child: SingleChildScrollView(
                  padding: CBInsets.panel,
                  physics: const BouncingScrollPhysics(),
                  child: CBPanel(
                      borderColor: scheme.secondary.withValues(alpha: 0.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('WELCOME, AGENT',
                              style: textTheme.headlineSmall!
                                  .copyWith(
                                    color: scheme.secondary,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    shadows: CBColors.textGlow(scheme.secondary, intensity: 0.4),
                                  )),
                          const SizedBox(height: CBSpace.x4),
                          Text(
                            'CHOOSE YOUR HOST MONIKER. THIS WILL BE YOUR PUBLIC IDENTITY IN THE CLUB.',
                            style: textTheme.bodySmall!.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: CBSpace.x8),
                          CBTextField(
                            controller: _usernameController,
                            hintText: 'HOST USERNAME',
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline,
                                  color: scheme.secondary),
                            ),
                          ),
                          const SizedBox(height: CBSpace.x8),
                          CBPrimaryButton(
                            label: _isSavingUsername
                                ? 'ENCRYPTING...'
                                : 'SAVE IDENTITY',
                            backgroundColor: scheme.secondary,
                            onPressed: _isSavingUsername
                                ? null
                                : () {
                                    HapticService.heavy();
                                    _saveUsername(user);
                                  },
                          ),
                          const SizedBox(height: CBSpace.x3),
                          CBGhostButton(
                            label: 'USE DIFFERENT ACCOUNT',
                            onPressed: () {
                              HapticService.light();
                              _signOut();
                            },
                            color: scheme.tertiary,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: CBSpace.x3),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall!
                                  .copyWith(
                                    color: scheme.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ],
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: '',
      showAppBar: false,
      body: Center(
        child: SingleChildScrollView(
          padding: CBInsets.panel,
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CBFadeSlide(
                key: const ValueKey('style_header'),
                  child: Column(
                    children: [
                      const CBRoleAvatar(
                          color: CBColors.neonPurple, size: 80, pulsing: true),
                      const SizedBox(height: CBSpace.x6),
                      Text(
                        'SELECT HOSTING PERSONALITY',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall!.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          shadows: CBColors.textGlow(scheme.primary),
                        ),
                      ),
                      const SizedBox(height: CBSpace.x4),
                      Text(
                        'YOUR CHOICE INFLUENCES THE NARRATIVE STYLE OF THE GAME.',
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CBSpace.x12),
                CBFadeSlide(
                  key: const ValueKey('style_options'),
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: GameStyle.values
                        .map((style) => Padding(
                              padding: const EdgeInsets.only(bottom: CBSpace.x4),
                              child: CBGlassTile(
                                isSelected: _selectedStyle == style,
                                onTap: () {
                                  HapticService.selection();
                                  setState(() => _selectedStyle = style);
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      style.label.toUpperCase(),
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color: _selectedStyle == style ? scheme.primary : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      style.description.toUpperCase(),
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
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
    );
  }
}
