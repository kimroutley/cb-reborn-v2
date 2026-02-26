import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cb_comms/cb_comms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserRepository {
  final ProfileRepository _profileRepository;

  UserRepository({FirebaseFirestore? firestore})
    : _profileRepository = ProfileRepository(
        firestore: firestore ?? FirebaseFirestore.instance,
      );

  Future<bool> hasProfile(String uid) async {
    return _profileRepository.hasProfile(uid);
  }

  Future<bool> isUsernameAvailable(
    String username, {
    String? excludingUid,
  }) async {
    return _profileRepository.isUsernameAvailable(
      username,
      excludingUid: excludingUid,
    );
  }

  Future<bool> isPublicPlayerIdAvailable(
    String publicPlayerId, {
    String? excludingUid,
  }) async {
    return _profileRepository.isPublicPlayerIdAvailable(
      publicPlayerId,
      excludingUid: excludingUid,
    );
  }

  Future<void> createProfile({
    required String uid,
    required String username,
    required String? email,
    String? publicPlayerId,
    String? avatarEmoji,
  }) async {
    await _profileRepository.upsertBasicProfile(
      uid: uid,
      username: username,
      email: email,
      isHost: true,
      publicPlayerId: publicPlayerId,
      avatarEmoji: avatarEmoji,
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
