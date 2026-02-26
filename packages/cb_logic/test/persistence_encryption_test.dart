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

    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);

    // Reset singleton
    PersistenceService.reset();
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('init generates and stores key on first run', () async {
    // Act
    await PersistenceService.init();

    // Assert
    expect(mockStorage.storage.containsKey('hive_encryption_key'), isTrue);

    final keyString = mockStorage.storage['hive_encryption_key']!;
    final keyBytes = base64Url.decode(keyString);
    expect(keyBytes.length, 32);
  });

  test('init uses existing key if available', () async {
    // Arrange: Storage has a key
    final key = Hive.generateSecureKey();
    final keyString = base64Url.encode(key);
    mockStorage.storage['hive_encryption_key'] = keyString;
    mockStorage.writeCalls.clear();

    // Act
    await PersistenceService.init();

    // Assert
    // Write should NOT be called (except maybe by other logic, but definitely not for the key)
    // Actually, migration check writes key only if migration happens.
    // If key exists, no write happens.
    expect(
        mockStorage.writeCalls
            .where((c) => c.startsWith('hive_encryption_key=')),
        isEmpty);
  });
}
