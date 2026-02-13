import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState(this.status, {this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) {
    return AuthState(
      status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  linkSent,
  needsProfile,
  authenticated,
  error,
}

class AuthNotifier extends Notifier<AuthState> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;
  final _appLinks = AppLinks();
  StreamSubscription? _userSub;
  StreamSubscription? _linkSub;

  final emailController = TextEditingController();
  final usernameController = TextEditingController();

  static const _pendingEmailKey = 'host_email_link_pending';

  @override
  AuthState build() {
    _userSub?.cancel();
    _linkSub?.cancel();

    _userSub = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        state = const AuthState(AuthStatus.unauthenticated);
        return;
      }

      try {
        final profile = await _loadProfile(user);
        if (profile.exists) {
          state = AuthState(AuthStatus.authenticated, user: user);
        } else {
          state = AuthState(AuthStatus.needsProfile, user: user);
        }
      } catch (_) {
        state = AuthState(AuthStatus.needsProfile, user: user);
      }
    });

    if (kIsWeb) {
      unawaited(_tryCompleteSignIn(Uri.base.toString()));
    }

    _initLinkHandling();

    ref.onDispose(() {
      _userSub?.cancel();
      _linkSub?.cancel();
      usernameController.dispose();
      emailController.dispose();
    });

    return const AuthState(AuthStatus.initial);
  }

  void _initLinkHandling() {
    if (kIsWeb) {
      return;
    }

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _tryCompleteSignIn(uri.toString());
    });
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _tryCompleteSignIn(uri.toString());
    });
  }

  Future<void> sendSignInLink() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(
          status: AuthStatus.error, error: 'Enter a valid secure email.');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://cb-reborn.web.app/email-link-signin?app=host',
        handleCodeInApp: true,
        androidPackageName: 'com.clubblackout.cb_host',
        androidInstallApp: true,
        androidMinimumVersion: '1',
        iOSBundleId: 'com.clubblackout.cbHost',
      );
      await _auth.sendSignInLinkToEmail(
          email: email, actionCodeSettings: actionCodeSettings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingEmailKey, email);
      state = const AuthState(AuthStatus.linkSent);
    } on FirebaseAuthException catch (e) {
      state = AuthState(AuthStatus.error, error: e.message);
    } catch (_) {
      state = AuthState(
        AuthStatus.error,
        error: 'Could not send sign-in link. Please try again.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return;
      }

      _googleSignIn ??= GoogleSignIn.instance;
      await _googleSignIn!.initialize();
      final GoogleSignInAccount googleUser = await _googleSignIn!.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        AuthStatus.error,
        error: e.message ?? 'Google sign-in failed. Please try again.',
      );
    } catch (e) {
      state = AuthState(
        AuthStatus.error,
        error: 'Google sign-in failed. Please retry.',
      );
    }
  }

  Future<void> completeSignInFromCurrentLink() async {
    final link = Uri.base.toString();
    if (!_auth.isSignInWithEmailLink(link)) {
      state = AuthState(
        AuthStatus.error,
        error: 'No valid sign-in link found in this session.',
      );
      return;
    }
    await _tryCompleteSignIn(link, preferTypedEmail: true);
  }

  Future<void> _tryCompleteSignIn(
    String link, {
    bool preferTypedEmail = false,
  }) async {
    if (!_auth.isSignInWithEmailLink(link)) return;

    state = state.copyWith(status: AuthStatus.loading);
    final prefs = await SharedPreferences.getInstance();
    final persistedEmail = prefs.getString(_pendingEmailKey);
    final typedEmail = emailController.text.trim();
    final email = preferTypedEmail
        ? (typedEmail.isNotEmpty ? typedEmail : persistedEmail)
        : (persistedEmail ?? (typedEmail.isNotEmpty ? typedEmail : null));

    if (email == null || !email.contains('@')) {
      state = AuthState(
        AuthStatus.error,
        error:
            'Email confirmation needed. Enter the same email used to request the link, then tap COMPLETE OPEN LINK.',
      );
      return;
    }

    try {
      final userCredential =
          await _auth.signInWithEmailLink(email: email, emailLink: link);
      await prefs.remove(_pendingEmailKey);
      if (userCredential.user != null) {
        final profile = await _loadProfile(userCredential.user!);
        if (profile.exists) {
          state =
              AuthState(AuthStatus.authenticated, user: userCredential.user);
        } else {
          state = AuthState(AuthStatus.needsProfile, user: userCredential.user);
        }
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState(AuthStatus.error, error: e.message);
    } catch (_) {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        state = AuthState(AuthStatus.needsProfile, user: currentUser);
      } else {
        state = AuthState(
          AuthStatus.error,
          error: 'Could not complete sign-in from this link. Please retry.',
        );
      }
    }
  }

  Future<void> saveUsername() async {
    final user = _auth.currentUser;
    final username = usernameController.text.trim();
    if (user == null) return;
    if (username.length < 3) {
      state = state.copyWith(
          status: AuthStatus.needsProfile,
          error: 'Username must be at least 3 characters.');
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final profileRef = _firestore.collection('user_profiles').doc(user.uid);
      await profileRef.set({
        'username': username,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'isHost': true,
      }, SetOptions(merge: true));
      state = AuthState(AuthStatus.authenticated, user: user);
    } on FirebaseException catch (e) {
      state = AuthState(
        AuthStatus.needsProfile,
        user: user,
        error:
            e.message ?? 'Failed to save profile. Check Firestore permissions.',
      );
    } catch (_) {
      state = AuthState(
        AuthStatus.needsProfile,
        user: user,
        error: 'Failed to save profile. Check Firestore permissions.',
      );
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadProfile(User user) {
    return _firestore.collection('user_profiles').doc(user.uid).get();
  }

  void reset() {
    state = const AuthState(AuthStatus.unauthenticated);
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      _googleSignIn ??= GoogleSignIn.instance;
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
