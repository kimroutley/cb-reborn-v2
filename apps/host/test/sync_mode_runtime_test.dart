import 'package:cb_host/sync_mode_runtime.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('syncHostBridgesForMode', () {
    test('cloud mode stops local before starting cloud', () async {
      final calls = <String>[];

      await syncHostBridgesForMode(
        mode: SyncMode.cloud,
        stopLocal: () async => calls.add('stopLocal'),
        startLocal: () async => calls.add('startLocal'),
        stopCloud: () async => calls.add('stopCloud'),
        startCloud: () async => calls.add('startCloud'),
      );

      expect(calls, equals(['stopLocal', 'startCloud']));
    });

    test('local mode stops cloud before starting local', () async {
      final calls = <String>[];

      await syncHostBridgesForMode(
        mode: SyncMode.local,
        stopLocal: () async => calls.add('stopLocal'),
        startLocal: () async => calls.add('startLocal'),
        stopCloud: () async => calls.add('stopCloud'),
        startCloud: () async => calls.add('startCloud'),
      );

      expect(calls, equals(['stopCloud', 'startLocal']));
    });
  });
}
