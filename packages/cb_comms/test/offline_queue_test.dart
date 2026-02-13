import 'package:cb_comms/src/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OfflineQueue', () {
    late OfflineQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      queue = OfflineQueue();
      await queue.init();
    });

    test('should queue actions', () async {
      await queue.add('GAME1', {'id': 1});
      expect(queue.queue.length, 1);
      expect(queue.joinCode, 'GAME1');

      await queue.add('GAME1', {'id': 2});
      expect(queue.queue.length, 2);
    });

    test('should clear queue when joining different game', () async {
      await queue.add('GAME1', {'id': 1});
      expect(queue.queue.length, 1);

      await queue.add('GAME2', {'id': 2});
      expect(queue.queue.length, 1);
      expect(queue.joinCode, 'GAME2');
      expect(queue.queue.first['id'], 2);
    });

    test('should persist queue', () async {
      await queue.add('GAME1', {'id': 1});

      final queue2 = OfflineQueue();
      await queue2.init();
      expect(queue2.queue.length, 1);
      expect(queue2.joinCode, 'GAME1');
      expect(queue2.queue.first['id'], 1);
    });

    test('should remove first item', () async {
      await queue.add('GAME1', {'id': 1});
      await queue.add('GAME1', {'id': 2});

      await queue.removeFirst();
      expect(queue.queue.length, 1);
      expect(queue.queue.first['id'], 2);

      final queue2 = OfflineQueue();
      await queue2.init();
      expect(queue2.queue.length, 1);
      expect(queue2.queue.first['id'], 2);
    });

    test('should clear queue', () async {
      await queue.add('GAME1', {'id': 1});
      await queue.clear();
      expect(queue.queue.isEmpty, true);
      expect(queue.joinCode, null);

      final queue2 = OfflineQueue();
      await queue2.init();
      expect(queue2.queue.isEmpty, true);
    });
  });
}
