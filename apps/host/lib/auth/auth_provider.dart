import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cb_logic/cb_logic.dart';
import 'auth_service.dart';
import 'user_repository.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

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
  needsProfile,
  authenticated,
  error,
}

class AuthNotifier extends Notifier<AuthState> {
  static const Duration _profileLookupTimeout = Duration(seconds: 8);

  late final AuthService _authService;
  late final UserRepository _userRepository;

  StreamSubscription? _userSub;

  final usernameController = TextEditingController();

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    _userRepository = ref.watch(userRepositoryProvider);

    _userSub?.cancel();

    _userSub = _authService.authStateChanges.listen((user) {
      Future.microtask(() async {
        if (user == null) {
          state = const AuthState(AuthStatus.unauthenticated);
          return;
        }

        state = AuthState(AuthStatus.loading, user: user);
        state = await _resolveSignedInState(user);
      });
    });

    ref.onDispose(() {
      _userSub?.cancel();
      usernameController.dispose();
    });

    return const AuthState(AuthStatus.initial);
  }

  /// Signs in anonymously with Firebase and immediately saves the host
  /// profile. This is the single entry-point for the host app.
  Future<void> signInAnonymouslyWithUsername({
    String? publicPlayerId,
    String? avatarEmoji,
  }) async {
    final username = usernameController.text.trim();
    if (username.length < 3) {
      state = state.copyWith(
        status: state.user != null
            ? AuthStatus.needsProfile
            : AuthStatus.unauthenticated,
        error: 'Username must be at least 3 characters.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      // If not already signed in anonymously, do so now.
      User? user = _authService.currentUser;
      if (user == null) {
        final credential = await _authService.signInAnonymously();
        user = credential.user;
      }
      if (user == null) {
        state = const AuthState(
          AuthStatus.error,
          error: 'Failed to create anonymous session.',
        );
        return;
      }

      // Save profile
      final trimmedPublicPlayerId = publicPlayerId?.trim();
      final trimmedAvatarEmoji = avatarEmoji?.trim();

      final usernameAvailable = await _userRepository.isUsernameAvailable(
        username,
        excludingUid: user.uid,
      );
      if (!usernameAvailable) {
        state = AuthState(
          AuthStatus.needsProfile,
          user: user,
          error: 'Handle already claimed. Choose a different moniker.',
        );
        return;
      }

      if (trimmedPublicPlayerId != null && trimmedPublicPlayerId.isNotEmpty) {
        final publicPlayerIdAvailable =
            await _userRepository.isPublicPlayerIdAvailable(
          trimmedPublicPlayerId,
          excludingUid: user.uid,
        );
        if (!publicPlayerIdAvailable) {
          state = AuthState(
            AuthStatus.needsProfile,
            user: user,
            error: 'Public player ID already registered. Try another tag.',
          );
          return;
        }
      }

      await _userRepository.createProfile(
        uid: user.uid,
        username: username,
        email: null, // Anonymous users have no email
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
        AuthStatus.error,
        error: e.message ?? 'Authentication failed.',
      );
    } catch (e, stack) {
      final stackString = stack.toString();
      final truncatedStack = stackString.length <= 100
          ? stackString
          : stackString.substring(0, 100);
      AnalyticsService.logError(e.toString(), stackTrace: truncatedStack);
      state = const AuthState(
        AuthStatus.error,
        error: 'Failed to establish identity. System breach.',
      );
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
      return AuthState(AuthStatus.needsProfile, user: user);
    } catch (_) {
      return AuthState(AuthStatus.needsProfile, user: user);
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
          error: 'Username must be at least 3 characters.');
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
        final publicPlayerIdAvailable =
            await _userRepository.isPublicPlayerIdAvailable(
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

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
