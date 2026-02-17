import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  }) {
    return _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  bool isSignInWithEmailLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    return _auth.signInWithEmailLink(email: email, emailLink: emailLink);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }

    await _googleSignIn.initialize();
    final googleUser = await _googleSignIn.authenticate();

    final googleAuth = googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
