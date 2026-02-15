import 'package:riverpod/riverpod.dart';

class RoomEffectsState {
  final String? activeEffect;
  final Map<String, dynamic>? activeEffectPayload;

  const RoomEffectsState({
    this.activeEffect,
    this.activeEffectPayload,
  });

  RoomEffectsState copyWith({
    String? activeEffect,
    Map<String, dynamic>? activeEffectPayload,
  }) {
    return RoomEffectsState(
      activeEffect: activeEffect,
      activeEffectPayload: activeEffectPayload,
    );
  }
}

class RoomEffectsNotifier extends Notifier<RoomEffectsState> {
  @override
  RoomEffectsState build() {
    return const RoomEffectsState();
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
    NotifierProvider<RoomEffectsNotifier, RoomEffectsState>(
  RoomEffectsNotifier.new,
);
