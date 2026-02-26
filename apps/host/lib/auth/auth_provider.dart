import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'user_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final appLinksProvider = Provider<AppLinks>((ref) => AppLinks());
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

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
  static const Duration _profileLookupTimeout = Duration(seconds: 8);

  late final AppLinks _appLinks;
  late final FlutterSecureStorage _storage;
  late final AuthService _authService;
  late final UserRepository _userRepository;

  StreamSubscription? _userSub;
  StreamSubscription? _linkSub;

  final emailController = TextEditingController();
  final usernameController = TextEditingController();

  static const _pendingEmailKey = 'host_email_link_pending';

  @override
  AuthState build() {
    _appLinks = ref.watch(appLinksProvider);
    _storage = ref.watch(secureStorageProvider);
    _authService = ref.watch(authServiceProvider);
    _userRepository = ref.watch(userRepositoryProvider);

    _userSub?.cancel();
    _linkSub?.cancel();

    _userSub = _authService.authStateChanges.listen((user) async {
      if (user == null) {
        state = const AuthState(AuthStatus.unauthenticated);
        return;
      }

      state = AuthState(AuthStatus.loading, user: user);
      state = await _resolveSignedInState(user);
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
        status: AuthStatus.error,
        error: 'Enter a valid secure email.',
      );
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
      await _authService.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      await _storage.write(key: _pendingEmailKey, value: email);
      state = const AuthState(AuthStatus.linkSent);
    } on FirebaseAuthException catch (e) {
      state = AuthState(AuthStatus.error, error: e.message);
    } catch (_) {
      state = const AuthState(
        AuthStatus.error,
        error: 'Could not send sign-in link. Please try again.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _authService.signInWithGoogle().timeout(
        const Duration(seconds: 45),
      );

      if (_authService.currentUser == null) {
        state = const AuthState(
          AuthStatus.unauthenticated,
          error: 'Sign-in did not complete. Please try again.',
        );
      }
      // Auth state listener will handle success
    } on TimeoutException {
      state = const AuthState(
        AuthStatus.unauthenticated,
        error: 'Sign-in timed out. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'ERROR_ABORTED_BY_USER') {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      state = AuthState(
        AuthStatus.error,
        error: e.message ?? 'Google sign-in failed. Please try again.',
      );
    } catch (e) {
      state = const AuthState(
        AuthStatus.error,
        error: 'Google sign-in failed. Please retry.',
      );
    }
  }

  Future<void> completeSignInFromCurrentLink() async {
    final link = Uri.base.toString();
    if (!_authService.isSignInWithEmailLink(link)) {
      state = const AuthState(
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
    if (!_authService.isSignInWithEmailLink(link)) return;

    state = state.copyWith(status: AuthStatus.loading);
    final persistedEmail = await _storage.read(key: _pendingEmailKey);
    final typedEmail = emailController.text.trim();
    final email = preferTypedEmail
        ? (typedEmail.isNotEmpty ? typedEmail : persistedEmail)
        : (persistedEmail ?? (typedEmail.isNotEmpty ? typedEmail : null));

    if (email == null || !email.contains('@')) {
      state = const AuthState(
        AuthStatus.error,
        error:
            'Email confirmation needed. Enter the same email used to request the link, then tap COMPLETE OPEN LINK.',
      );
      return;
    }

    try {
      final userCredential = await _authService.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      await _storage.delete(key: _pendingEmailKey);
      if (userCredential.user != null) {
        state = await _resolveSignedInState(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState(AuthStatus.error, error: e.message);
    } catch (_) {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        state = AuthState(AuthStatus.needsProfile, user: currentUser);
      } else {
        state = const AuthState(
          AuthStatus.error,
          error: 'Could not complete sign-in from this link. Please retry.',
        );
      }
    }
  }

  Future<AuthState> _resolveSignedInState(User user) async {
    try {
      final hasProfile = await _userRepository
          .hasProfile(user.uid)
          .timeout(_profileLookupTimeout);
      if (hasProfile) {
        return AuthState(AuthStatus.authenticated, user: user);
      }
      return AuthState(AuthStatus.needsProfile, user: user);
    } on TimeoutException {
      final hasIdentity =
          (user.displayName?.trim().isNotEmpty ?? false) ||
          (user.email?.trim().isNotEmpty ?? false);
      return AuthState(
        hasIdentity ? AuthStatus.authenticated : AuthStatus.needsProfile,
        user: user,
      );
    } catch (_) {
      final hasIdentity =
          (user.displayName?.trim().isNotEmpty ?? false) ||
          (user.email?.trim().isNotEmpty ?? false);
      return AuthState(
        hasIdentity ? AuthStatus.authenticated : AuthStatus.needsProfile,
        user: user,
      );
    }
  }

  Future<void> saveUsername({
    String? publicPlayerId,
    String? avatarEmoji,
  }) async {
    final user = _authService.currentUser;
    final username = usernameController.text.trim();
    final trimmedPublicPlayerId = publicPlayerId?.trim();
    final trimmedAvatarEmoji = avatarEmoji?.trim();
    if (user == null) return;
    if (username.length < 3) {
      state = state.copyWith(
        status: AuthStatus.needsProfile,
        error: 'Username must be at least 3 characters.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final usernameAvailable = await _userRepository.isUsernameAvailable(
        username,
        excludingUid: user.uid,
      );
      if (!usernameAvailable) {
        state = AuthState(
          AuthStatus.needsProfile,
          user: user,
          error:
              'That username is already in use. Choose another manager name.',
        );
        return;
      }

      if (trimmedPublicPlayerId != null && trimmedPublicPlayerId.isNotEmpty) {
        final publicPlayerIdAvailable = await _userRepository
            .isPublicPlayerIdAvailable(
              trimmedPublicPlayerId,
              excludingUid: user.uid,
            );
        if (!publicPlayerIdAvailable) {
          state = AuthState(
            AuthStatus.needsProfile,
            user: user,
            error:
                'That public player ID is already in use. Pick a different one.',
          );
          return;
        }
      }

      await _userRepository.createProfile(
        uid: user.uid,
        username: username,
        email: user.email,
        publicPlayerId:
            (trimmedPublicPlayerId == null || trimmedPublicPlayerId.isEmpty)
            ? null
            : trimmedPublicPlayerId,
        avatarEmoji: (trimmedAvatarEmoji == null || trimmedAvatarEmoji.isEmpty)
            ? null
            : trimmedAvatarEmoji,
      );
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

  void reset() {
    state = const AuthState(AuthStatus.unauthenticated);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
