import 'package:flutter_riverpod/flutter_riverpod.dart';

class HostEffectsState {
  final String? activeEffect;
  final Map<String, dynamic>? activeEffectPayload;

  const HostEffectsState({
    this.activeEffect,
    this.activeEffectPayload,
  });

  HostEffectsState copyWith({
    String? activeEffect,
    Map<String, dynamic>? activeEffectPayload,
  }) {
    return HostEffectsState(
      activeEffect: activeEffect,
      activeEffectPayload: activeEffectPayload,
    );
  }
}

class HostRoomEffectsNotifier extends Notifier<HostEffectsState> {
  @override
  HostEffectsState build() {
    return const HostEffectsState();
  }

  void triggerEffect(String effectType, Map<String, dynamic>? payload) {
    state =
        state.copyWith(activeEffect: effectType, activeEffectPayload: payload);
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(activeEffect: null, activeEffectPayload: null);
    });
  }
}

final hostRoomEffectsProvider =
    NotifierProvider<HostRoomEffectsNotifier, HostEffectsState>(
  HostRoomEffectsNotifier.new,
);
