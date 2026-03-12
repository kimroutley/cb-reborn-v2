import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth? _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;

  Future<void> _ensureFirebaseInitialized() async {
    if (_auth != null) {
      return;
    }
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Stream<User?> get authStateChanges {
    if (_auth != null || Firebase.apps.isNotEmpty) {
      return _firebaseAuth.authStateChanges();
    }

    return Stream<void>.fromFuture(_ensureFirebaseInitialized())
        .asyncExpand((_) => _firebaseAuth.authStateChanges());
  }

  User? get currentUser => (_auth != null || Firebase.apps.isNotEmpty)
      ? _firebaseAuth.currentUser
      : null;

  Future<UserCredential> signInAnonymously() async {
    await _ensureFirebaseInitialized();
    return _firebaseAuth.signInAnonymously();
  }

  Future<void> signOut() async {
    if (_auth != null || Firebase.apps.isNotEmpty) {
      await _firebaseAuth.signOut();
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
