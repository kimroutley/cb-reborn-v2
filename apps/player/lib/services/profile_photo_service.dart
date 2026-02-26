import 'dart:io';

import 'package:cb_comms/cb_comms_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoService {
  ProfilePhotoService({
    ProfileRepository? repository,
    FirebaseStorage? storage,
  })  : _repository = repository ?? ProfileRepository(),
        _storage = storage ?? FirebaseStorage.instance;

  final ProfileRepository _repository;
  final FirebaseStorage _storage;

  static const int _maxDimension = 512;

  Future<String?> pickAndUpload({
    required String uid,
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: _maxDimension.toDouble(),
      maxHeight: _maxDimension.toDouble(),
      imageQuality: 80,
    );
    if (picked == null) return null;

    final ref = _storage.ref('profile_photos/$uid.jpg');

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      final file = File(picked.path);
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    }

    final downloadUrl = await ref.getDownloadURL();

    await _repository.updateProfile(uid, {'photoUrl': downloadUrl});

    return downloadUrl;
  }

  Future<void> removePhoto({required String uid}) async {
    try {
      await _storage.ref('profile_photos/$uid.jpg').delete();
    } catch (_) {
      // File may not exist -- non-critical.
    }
    await _repository.updateProfile(uid, {'photoUrl': null});
  }
}
