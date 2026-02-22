import 'package:cb_theme/src/haptic_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticService', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
      HapticService.setEnabled(true);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('light invokes HapticFeedback.lightImpact', () async {
      HapticService.light();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
    });

    test('medium invokes HapticFeedback.mediumImpact', () async {
      HapticService.medium();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.mediumImpact'));
    });

    test('heavy invokes HapticFeedback.heavyImpact', () async {
      HapticService.heavy();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.heavyImpact'));
    });

    test('selection invokes HapticFeedback.selectionClick', () async {
      HapticService.selection();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.selectionClick'));
    });

    test('vibrate invokes HapticFeedback.vibrate', () async {
      HapticService.vibrate();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: null));
    });

    test('success invokes HapticFeedback.lightImpact twice', () async {
      await HapticService.success();
      expect(log, hasLength(2));
      expect(log[0], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
      expect(log[1], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
    });

    test('error invokes HapticFeedback.heavyImpact', () async {
      HapticService.error();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.heavyImpact'));
    });

    test('nightAction invokes HapticFeedback.mediumImpact', () async {
      HapticService.nightAction();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.mediumImpact'));
    });

    test('voteCast invokes selection then light', () async {
      await HapticService.voteCast();
      expect(log, hasLength(2));
      expect(log[0], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.selectionClick'));
      expect(log[1], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
    });

    test('alertDispatch invokes heavy, medium, then light', () async {
      await HapticService.alertDispatch();
      expect(log, hasLength(3));
      expect(log[0], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.heavyImpact'));
      expect(log[1], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.mediumImpact'));
      expect(log[2], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
    });

    test('eyesOpen invokes vibrate', () async {
      HapticService.eyesOpen();
      expect(log, hasLength(1));
      expect(log.single, isMethodCall('HapticFeedback.vibrate', arguments: null));
    });

    test('eyesClosed invokes light twice', () async {
      await HapticService.eyesClosed();
      expect(log, hasLength(2));
      expect(log[0], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
      expect(log[1], isMethodCall('HapticFeedback.vibrate', arguments: 'HapticFeedbackType.lightImpact'));
    });

    test('when disabled, no feedback is invoked', () async {
      HapticService.setEnabled(false);

      HapticService.light();
      HapticService.medium();
      HapticService.heavy();
      HapticService.selection();
      HapticService.vibrate();
      await HapticService.success();
      HapticService.error();
      HapticService.nightAction();
      await HapticService.voteCast();
      await HapticService.alertDispatch();
      HapticService.eyesOpen();
      await HapticService.eyesClosed();

      expect(log, isEmpty);
    });
  });
}
