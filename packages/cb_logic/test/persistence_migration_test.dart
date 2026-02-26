import 'dart:convert';
import 'dart:io';

import 'package:cb_logic/src/persistence/persistence_service.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSecureStoragePlatform extends FlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  final Map<String, String> storage = {};

  // Track calls for verification
  final List<String> writeCalls = [];

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    return storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    storage[key] = value;
    writeCalls.add('$key=$value');
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    return Map.from(storage);
  }

  @override
  Future<void> deleteAll({
    required Map<String, String> options,
  }) async {
    storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    return storage.containsKey(key);
  }
}

void main() {
  late MockFlutterSecureStoragePlatform mockStorage;
  late Directory tempDir;

  setUp(() async {
    mockStorage = MockFlutterSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = mockStorage;

    tempDir = await Directory.systemTemp.createTemp('hive_migration_test');
    Hive.init(tempDir.path);

    // Reset singleton
    PersistenceService.reset();
  });

  tearDown(() async {
    // Close Hive properly
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('migrates legacy unencrypted data to encrypted boxes', () async {
    // 1. Create legacy unencrypted boxes with data
    final activeBox = await Hive.openBox<String>('active_game');
    await activeBox.put('game_state', '{"test": "active_data"}');
    await activeBox.close();

    final recordsBox = await Hive.openBox<String>('game_records');
    await recordsBox.put('record_1', '{"test": "record_data"}');
    await recordsBox.close();

    final sessionsBox = await Hive.openBox<String>('games_night_sessions');
    await sessionsBox.put('session_1', '{"test": "session_data"}');
    await sessionsBox.close();

    // Verify unencrypted boxes exist
    expect(await Hive.boxExists('active_game'), isTrue);
    expect(await Hive.boxExists('game_records'), isTrue);
    expect(await Hive.boxExists('games_night_sessions'), isTrue);

    // Ensure no key in storage
    expect(mockStorage.storage.containsKey('hive_encryption_key'), isFalse);

    // 2. Run init (triggers migration)
    final service = await PersistenceService.init();

    // 3. Verify key was generated
    expect(mockStorage.storage.containsKey('hive_encryption_key'), isTrue);
    final keyString = mockStorage.storage['hive_encryption_key']!;
    final key = base64Url.decode(keyString);

    // 4. Verify data is accessible via service (encrypted boxes are open)
    // We open the boxes manually with the key to verify content directly.
    // Note: The service keeps the boxes open, so Hive should return the open instances.

    final cipher = HiveAesCipher(key);
    final encryptedActiveBox =
        await Hive.openBox<String>('active_game', encryptionCipher: cipher);
    expect(encryptedActiveBox.get('game_state'), '{"test": "active_data"}');

    final encryptedRecordsBox =
        await Hive.openBox<String>('game_records', encryptionCipher: cipher);
    expect(encryptedRecordsBox.get('record_1'), '{"test": "record_data"}');

    // 5. Verify unencrypted access fails (proof of encryption)
    // We need to close the boxes first because Hive might return the open encrypted box if we try to open it again.
    await service.close();
    // We also need to close the manually opened references if they are distinct (usually they are shared)
    // But since we got them from Hive.openBox, they share the same instance.
    // Closing service closes them.

    // Now try to open without key
    // We disable crashRecovery to ensure it throws instead of "recovering" (wiping) the file
    expect(
      () async =>
          await Hive.openBox<String>('active_game', crashRecovery: false),
      throwsA(isA<HiveError>()),
    );
  });
}
