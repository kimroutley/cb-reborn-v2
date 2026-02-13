import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerEffectsState {
  final String? activeEffect;
  final Map<String, dynamic>? activeEffectPayload;

  const PlayerEffectsState({
    this.activeEffect,
    this.activeEffectPayload,
  });

  PlayerEffectsState copyWith({
    String? activeEffect,
    Map<String, dynamic>? activeEffectPayload,
  }) {
    return PlayerEffectsState(
      activeEffect: activeEffect,
      activeEffectPayload: activeEffectPayload,
    );
  }
}

class RoomEffectsNotifier extends Notifier<PlayerEffectsState> {
  @override
  PlayerEffectsState build() {
    return const PlayerEffectsState();
  }

  void triggerEffect(String effectType, Map<String, dynamic>? payload) {
    state =
        state.copyWith(activeEffect: effectType, activeEffectPayload: payload);
    // Clear the effect after a short duration if not a persistent one
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(activeEffect: null, activeEffectPayload: null);
    });
  }
}

final roomEffectsProvider =
    NotifierProvider<RoomEffectsNotifier, PlayerEffectsState>(
  RoomEffectsNotifier.new,
);
