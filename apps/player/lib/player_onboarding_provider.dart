import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerOnboardingState {
  final bool awaitingStartConfirmation;

  const PlayerOnboardingState({this.awaitingStartConfirmation = false});

  PlayerOnboardingState copyWith({bool? awaitingStartConfirmation}) {
    return PlayerOnboardingState(
      awaitingStartConfirmation:
          awaitingStartConfirmation ?? this.awaitingStartConfirmation,
    );
  }
}

class PlayerOnboardingNotifier extends Notifier<PlayerOnboardingState> {
  @override
  PlayerOnboardingState build() => const PlayerOnboardingState();

  void setAwaitingStartConfirmation(bool value) {
    state = state.copyWith(awaitingStartConfirmation: value);
  }

  void reset() {
    state = const PlayerOnboardingState();
  }
}

final playerOnboardingProvider =
    NotifierProvider<PlayerOnboardingNotifier, PlayerOnboardingState>(
      PlayerOnboardingNotifier.new,
    );
