import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cb_host/auth/auth_provider.dart';
import 'package:cb_host/auth/auth_service.dart';
import 'package:cb_host/auth/user_repository.dart';

// Fake User implementation
class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;

  FakeUser({required this.uid, this.email});
}

// Fake AuthService implementation
class FakeAuthService implements AuthService {
  final _authStateController = StreamController<User?>();
  User? _currentUser;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  User? get currentUser => _currentUser;

  void emitUser(User? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  void close() {
    _authStateController.close();
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    emitUser(null);
  }
}

// Fake UserRepository implementation
class FakeUserRepository implements UserRepository {
  final Map<String, bool> _profiles = {};

  void setProfile(String uid, bool exists) {
    _profiles[uid] = exists;
  }

  @override
  Future<bool> hasProfile(String uid) async {
    return _profiles[uid] ?? false;
  }

  @override
  Future<void> createProfile({
    required String uid,
    required String username,
    required String? email,
    String? publicPlayerId,
    String? avatarEmoji,
  }) async {
    _profiles[uid] = true;
  }

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

void main() {
  late FakeAuthService fakeAuthService;
  late FakeUserRepository fakeUserRepository;
  late ProviderContainer container;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    fakeAuthService = FakeAuthService();
    fakeUserRepository = FakeUserRepository();

    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(fakeAuthService),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
  });

  tearDown(() {
    fakeAuthService.close();
    container.dispose();
  });

  test('Initial state is initial', () {
    final authState = container.read(authProvider);
    expect(authState.status, AuthStatus.initial);
  });

  test('State becomes unauthenticated when user is null', () async {
    final subscription = container.listen(authProvider, (_, __) {});

    fakeAuthService.emitUser(null);

    await Future.delayed(Duration.zero);

    final authState = container.read(authProvider);
    expect(authState.status, AuthStatus.unauthenticated);

    subscription.close();
  });

  test('State becomes authenticated when user exists and has profile',
      () async {
    final subscription = container.listen(authProvider, (_, __) {});

    final user = FakeUser(uid: '123', email: 'test@example.com');
    fakeUserRepository.setProfile('123', true);

    fakeAuthService.emitUser(user);

    await Future.delayed(const Duration(milliseconds: 10));

    final authState = container.read(authProvider);
    expect(authState.status, AuthStatus.authenticated);
    expect(authState.user, user);

    subscription.close();
  });

  test('State becomes needsProfile when user exists but no profile', () async {
    final subscription = container.listen(authProvider, (_, __) {});

    final user = FakeUser(uid: '456', email: 'new@example.com');
    fakeUserRepository.setProfile('456', false);

    fakeAuthService.emitUser(user);

    await Future.delayed(const Duration(milliseconds: 10));

    final authState = container.read(authProvider);
    expect(authState.status, AuthStatus.needsProfile);
    expect(authState.user, user);

    subscription.close();
  });

  test('saveUsername creates profile and updates state', () async {
    final subscription = container.listen(authProvider, (_, __) {});

    final user = FakeUser(uid: '789', email: 'save@example.com');
    fakeAuthService.emitUser(user);

    await Future.delayed(const Duration(milliseconds: 10));

    var authState = container.read(authProvider);
    expect(authState.status, AuthStatus.needsProfile);

    final notifier = container.read(authProvider.notifier);
    notifier.usernameController.text = 'HostUser';
    await notifier.saveUsername();

    expect(await fakeUserRepository.hasProfile('789'), true);

    authState = container.read(authProvider);
    expect(authState.status, AuthStatus.authenticated);

    subscription.close();
  });
}
