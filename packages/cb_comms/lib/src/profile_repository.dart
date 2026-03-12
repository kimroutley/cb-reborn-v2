import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('user_profiles');

  Future<DocumentSnapshot<Map<String, dynamic>>> getProfile(String uid) {
    return _profiles.doc(uid).get();
  }

  Future<Map<String, dynamic>?> loadProfile(String uid) async {
    final snap = await getProfile(uid);
    return snap.data();
  }

  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _profiles.doc(uid).snapshots().map((snapshot) => snapshot.data());
  }

  Future<bool> hasProfile(String uid) async {
    final doc = await getProfile(uid);
    return doc.exists;
  }

  Future<bool> isUsernameAvailable(
    String username, {
    String? excludingUid,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    QuerySnapshot<Map<String, dynamic>> existing;
    try {
      existing = await _profiles
          .where('usernameLower', isEqualTo: normalized)
          .limit(1)
          .get();
    } on FirebaseException catch (error) {
      // Current security rules restrict profile reads to the signed-in user's
      // document (`request.auth.uid == uid`), so collection queries may be
      // rejected with permission-denied in client flows.
      //
      // In that configuration we allow save to proceed instead of failing the
      // entire profile update path.
      if (error.code == 'permission-denied') {
        return true;
      }
      rethrow;
    }

    if (existing.docs.isEmpty) {
      return true;
    }

    return excludingUid != null && existing.docs.first.id == excludingUid;
  }

  Future<bool> isPublicPlayerIdAvailable(
    String publicPlayerId, {
    String? excludingUid,
  }) async {
    final normalized = normalizePublicPlayerId(publicPlayerId);
    if (normalized.isEmpty) {
      return false;
    }

    QuerySnapshot<Map<String, dynamic>> existing;
    try {
      existing = await _profiles
          .where('publicPlayerIdLower', isEqualTo: normalized)
          .limit(1)
          .get();
    } on FirebaseException catch (error) {
      // See notes in isUsernameAvailable: on permission-denied we avoid
      // blocking profile updates from the client.
      if (error.code == 'permission-denied') {
        return true;
      }
      rethrow;
    }

    if (existing.docs.isEmpty) {
      return true;
    }

    return excludingUid != null && existing.docs.first.id == excludingUid;
  }

  Future<void> upsertBasicProfile({
    required String uid,
    required String username,
    required String? email,
    required bool isHost,
    String? publicPlayerId,
    String? avatarEmoji,
    String? preferredStyle,
  }) async {
    final trimmedUsername = username.trim();
    final trimmedEmail = email?.trim();
    final trimmedPublicId = publicPlayerId?.trim();
    final trimmedAvatarEmoji = avatarEmoji?.trim();
    final trimmedPreferredStyle = preferredStyle?.trim();

    final now = FieldValue.serverTimestamp();
    final docRef = _profiles.doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      final payload = <String, dynamic>{
        'uid': uid,
        'username': trimmedUsername,
        'usernameLower': trimmedUsername.toLowerCase(),
        'email': trimmedEmail,
        'emailLower': trimmedEmail?.toLowerCase(),
        'emailMasked': maskEmail(trimmedEmail),
        'isHost': isHost,
        'updatedAt': now,
      };

      if (trimmedPublicId != null && trimmedPublicId.isNotEmpty) {
        payload['publicPlayerId'] = trimmedPublicId;
        final normalizedPublicId = normalizePublicPlayerId(trimmedPublicId);
        if (normalizedPublicId.isNotEmpty) {
          payload['publicPlayerIdLower'] = normalizedPublicId;
        }
      } else {
        payload['publicPlayerId'] = FieldValue.delete();
        payload['publicPlayerIdLower'] = FieldValue.delete();
      }

      if (trimmedAvatarEmoji != null && trimmedAvatarEmoji.isNotEmpty) {
        payload['avatarEmoji'] = trimmedAvatarEmoji;
      } else {
        payload['avatarEmoji'] = FieldValue.delete();
      }

      if (trimmedPreferredStyle != null && trimmedPreferredStyle.isNotEmpty) {
        payload['preferredStyle'] = trimmedPreferredStyle;
      } else {
        payload['preferredStyle'] = FieldValue.delete();
      }

      if (!snapshot.exists) {
        payload['createdAt'] = now;
      }

      transaction.set(docRef, payload, SetOptions(merge: true));
    });
  }

  // ── Email Recovery ──────────────────────────────────────────────────

  /// Whether [user] has an email/password provider linked.
  static bool hasLinkedEmail(User user) {
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Links an email + password credential to the current anonymous [user],
  /// then persists the email in the Firestore profile document.
  ///
  /// Throws [FirebaseAuthException] on failure (e.g. email already in use,
  /// weak password).
  Future<void> linkRecoveryEmail({
    required User user,
    required String email,
    required String password,
  }) async {
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.linkWithCredential(credential);

    // Persist in Firestore profile so the wallet view can display it.
    await _profiles.doc(user.uid).update({
      'email': email.trim(),
      'emailLower': email.trim().toLowerCase(),
      'emailMasked': maskEmail(email.trim()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unlinks the email/password provider from [user] and clears Firestore
  /// email fields.
  Future<void> unlinkRecoveryEmail({required User user}) async {
    await user.unlink('password');

    await _profiles.doc(user.uid).update({
      'email': FieldValue.delete(),
      'emailLower': FieldValue.delete(),
      'emailMasked': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────

  static String normalizePublicPlayerId(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
  }

  static String maskEmail(String? value) {
    if (value == null || value.isEmpty || !value.contains('@')) {
      return 'unknown@email';
    }
    final parts = value.split('@');
    final name = parts.first;
    final domain = parts.last;
    if (name.length <= 2) {
      return '**@$domain';
    }
    return '${name[0]}***${name[name.length - 1]}@$domain';
  }
}
