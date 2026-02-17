import 'package:cb_player/active_bridge.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededCloudBridge extends CloudPlayerBridge {
  _SeededCloudBridge(this._state);

  final PlayerGameState _state;

  @override
  PlayerGameState build() => _state;

  @override
  Future<void> disconnect() async {}
}

class _SeededLocalBridge extends PlayerBridge {
  _SeededLocalBridge(this._state);

  final PlayerGameState _state;

  @override
  PlayerGameState build() => _state;

  @override
  Future<void> disconnect() async {}
}

void main() {
  group('activeBridgeProvider', () {
    test('prefers cloud when cloud is connected', () {
      final container = ProviderContainer(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(
            () => _SeededCloudBridge(
              const PlayerGameState(isConnected: true, phase: 'lobby'),
            ),
          ),
          playerBridgeProvider.overrideWith(
            () => _SeededLocalBridge(
              const PlayerGameState(isConnected: true, phase: 'lobby'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final active = container.read(activeBridgeProvider);
      expect(active.isCloud, isTrue);
      expect(active.state.isConnected, isTrue);
    });

    test('prefers cloud when join is accepted (even if not connected)', () {
      final container = ProviderContainer(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(
            () => _SeededCloudBridge(
              const PlayerGameState(
                isConnected: false,
                joinAccepted: true,
                phase: 'setup',
              ),
            ),
          ),
          playerBridgeProvider.overrideWith(
            () => _SeededLocalBridge(
              const PlayerGameState(isConnected: true, phase: 'lobby'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final active = container.read(activeBridgeProvider);
      expect(active.isCloud, isTrue);
      expect(active.state.joinAccepted, isTrue);
      expect(active.state.phase, 'setup');
    });

    test('falls back to local when cloud is not connected and not joined', () {
      final container = ProviderContainer(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(
            () => _SeededCloudBridge(
              const PlayerGameState(isConnected: false, joinAccepted: false),
            ),
          ),
          playerBridgeProvider.overrideWith(
            () => _SeededLocalBridge(
              const PlayerGameState(isConnected: true, phase: 'lobby'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final active = container.read(activeBridgeProvider);
      expect(active.isCloud, isFalse);
      expect(active.state.isConnected, isTrue);
      expect(active.state.phase, 'lobby');
    });
  });
}
