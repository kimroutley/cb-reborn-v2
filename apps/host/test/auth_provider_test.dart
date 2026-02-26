import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cb_host/auth/auth_provider.dart';
import 'package:cb_host/auth/auth_service.dart';
import 'package:cb_host/auth/user_repository.dart';

// ignore_for_file: subtype_of_sealed_class

// Fakes
class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  @override
  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) async {
    // No-op
  }

  @override
  bool isSignInWithEmailLink(String emailLink) {
    return emailLink.contains('signIn');
  }

  @override
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    return FakeUserCredential();
  }

  @override
  User? get currentUser => null;
}

class FakeAuthService extends Fake implements AuthService {
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  User? get currentUser => null;

  @override
  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) async {}

  @override
  bool isSignInWithEmailLink(String link) {
    return link.contains('signIn');
  }

  @override
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    return FakeUserCredential();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    return FakeUserCredential();
  }

  @override
  Future<void> signOut() async {
    await _authStateController.close();
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
  }) async => true;

  @override
  Future<bool> isPublicPlayerIdAvailable(
    String publicPlayerId, {
    String? excludingUid,
  }) async => true;
}

class FakeUserCredential extends Fake implements UserCredential {
  @override
  User? get user => FakeUser();
}

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_uid';

  @override
  String? get email => 'test@example.com';
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference();
  }
}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference();
  }
}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return FakeDocumentSnapshot();
  }
}

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  bool get exists => false;

  @override
  Map<String, dynamic>? data() => null;
}

class FakeAppLinks extends Fake implements AppLinks {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => null;

  @override
  Stream<Uri> get uriLinkStream => _controller.stream;

  void simulateLink(Uri uri) {
    _controller.add(uri);
  }
}

void main() {
  late FakeFlutterSecureStorage mockStorage;
  late FakeFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late FakeAppLinks mockAppLinks;
  late FakeAuthService fakeAuthService;
  late FakeUserRepository fakeUserRepository;

  setUp(() {
    mockStorage = FakeFlutterSecureStorage();
    mockAuth = FakeFirebaseAuth();
    mockFirestore = FakeFirebaseFirestore();
    mockAppLinks = FakeAppLinks();
    fakeAuthService = FakeAuthService();
    fakeUserRepository = FakeUserRepository();
  });

  tearDown(() {
    fakeAuthService.dispose();
  });

  test('sendSignInLink writes email to secure storage', () async {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        firebaseAuthProvider.overrideWithValue(mockAuth),
        firestoreProvider.overrideWithValue(mockFirestore),
        appLinksProvider.overrideWithValue(mockAppLinks),
        authServiceProvider.overrideWithValue(fakeAuthService),
        userRepositoryProvider.overrideWithValue(fakeUserRepository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    notifier.emailController.text = 'test@example.com';

    await notifier.sendSignInLink();

    final storedEmail = await mockStorage.read(key: 'host_email_link_pending');
    expect(storedEmail, 'test@example.com');
  });

  test(
    'Completing sign in via deep link reads and deletes email from storage',
    () async {
      await mockStorage.write(
        key: 'host_email_link_pending',
        value: 'saved@example.com',
      );

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          firebaseAuthProvider.overrideWithValue(mockAuth),
          firestoreProvider.overrideWithValue(mockFirestore),
          appLinksProvider.overrideWithValue(mockAppLinks),
          authServiceProvider.overrideWithValue(fakeAuthService),
          userRepositoryProvider.overrideWithValue(fakeUserRepository),
        ],
      );
      addTearDown(container.dispose);

      // Watch the provider to initialize the notifier and start listening to links
      final _ = container.read(authProvider);

      // Simulate incoming link
      mockAppLinks.simulateLink(
        Uri.parse('https://example.com/signIn?code=123'),
      );

      // Wait for async operations to complete
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Verify storage is cleared
      final storedEmail = await mockStorage.read(
        key: 'host_email_link_pending',
      );
      expect(storedEmail, isNull);
    },
  );
}
