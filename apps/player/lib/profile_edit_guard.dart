import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerProfileDirtyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDirty(bool value) {
    state = value;
  }

  void reset() {
    state = false;
  }
}

final playerProfileDirtyProvider =
    NotifierProvider<PlayerProfileDirtyNotifier, bool>(
      PlayerProfileDirtyNotifier.new,
    );
