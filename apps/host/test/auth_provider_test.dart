import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cb_host/auth/auth_provider.dart';
import 'package:cb_host/auth/auth_service.dart';
import 'package:cb_host/auth/user_repository.dart';

// ignore_for_file: subtype_of_sealed_class

// Fakes
class FakeAuthService extends Fake implements AuthService {
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInAnonymously() async {
    return FakeUserCredential();
  }

  @override
  Future<void> signOut() async {
    await _authStateController.close();
  }

  void emitUser(User? user) {
    _authStateController.add(user);
  }

  void dispose() {
    _authStateController.close();
  }
}

class FakeUserRepository extends Fake implements UserRepository {
  @override
  Future<bool> hasProfile(String uid) async => false;

  @override
  Future<void> createProfile({
    required String uid,
    required String username,
    required String? email,
    String? publicPlayerId,
    String? avatarEmoji,
  }) async {}

  @override
  Future<bool> isUsernameAvailable(
    String username, {
    String? excludingUid,
  }) async =>
      true;

  @override
  Future<bool> isPublicPlayerIdAvailable(
    String publicPlayerId, {
    String? excludingUid,
  }) async =>
      true;
}

class FakeUserCredential extends Fake implements UserCredential {
  @override
  User? get user => FakeUser();
}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_uid';

  @override
  String? get email => null;

  @override
  String? get displayName => null;
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late FakeAuthService fakeAuthService;
  late FakeUserRepository fakeUserRepository;

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    fakeAuthService = FakeAuthService();
    fakeUserRepository = FakeUserRepository();
  });

  tearDown(() {
    fakeAuthService.dispose();
  });

  test('signInAnonymouslyWithUsername rejects short usernames', () async {
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(mockFirestore),
        authServiceProvider.overrideWithValue(fakeAuthService),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    notifier.usernameController.text = 'AB'; // Too short

    await notifier.signInAnonymouslyWithUsername();

    final state = container.read(authProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.error, contains('3 characters'));
  });

  test('Auth state listener sets needsProfile when profile is missing',
      () async {
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(mockFirestore),
        authServiceProvider.overrideWithValue(fakeAuthService),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
    addTearDown(container.dispose);

    // Read to initialize the notifier
    container.read(authProvider);

    // Simulate user sign-in via stream
    fakeAuthService.emitUser(FakeUser());

    // Wait for async operations
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);

    final state = container.read(authProvider);
    expect(state.status, AuthStatus.needsProfile);
  });

  test('signOut resets state to unauthenticated', () async {
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(mockFirestore),
        authServiceProvider.overrideWithValue(fakeAuthService),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.signOut();

    final state = container.read(authProvider);
    expect(state.status, AuthStatus.unauthenticated);
  });
}
