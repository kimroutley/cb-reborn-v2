import 'package:cb_host/host_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock audioplayers platform channel
  const channel = MethodChannel('xyz.luan/audioplayers');
  const globalChannel = MethodChannel('xyz.luan/audioplayers.global');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return 1; // Return success for all calls
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalChannel, (MethodCall methodCall) async {
          return 1; // Return success for all calls
        });

    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalChannel, null);
  });

  group('HostSettingsNotifier', () {
    test('initial state matches defaults', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(hostSettingsProvider);

      expect(settings, HostSettings.defaults);

      // Wait for async hydrate to finish before tearDown clears mocks
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    test('updates sfx volume and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger build
      container.read(hostSettingsProvider);

      final notifier = container.read(hostSettingsProvider.notifier);

      notifier.setSfxVolume(0.5);

      // Allow async operations to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final settings = container.read(hostSettingsProvider);
      expect(settings.sfxVolume, 0.5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('sfxVolume'), 0.5);
    });

    test('updates high contrast and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger build
      container.read(hostSettingsProvider);

      final notifier = container.read(hostSettingsProvider.notifier);

      notifier.setHighContrast(true);

      // Allow async operations to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final settings = container.read(hostSettingsProvider);
      expect(settings.highContrast, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('highContrast'), true);
    });

    test('hydrates from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'sfxVolume': 0.8,
        'highContrast': true,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger build which calls _hydrate
      final subscription = container.listen(hostSettingsProvider, (_, __) {});

      // Wait for async hydrate
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final settings = container.read(hostSettingsProvider);

      expect(settings.sfxVolume, 0.8);
      expect(settings.highContrast, true);

      subscription.close();
    });
  });
}
