import 'package:flutter_riverpod/flutter_riverpod.dart';

class HostProfileDirtyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDirty(bool value) {
    state = value;
  }

  void reset() {
    state = false;
  }
}

final hostProfileDirtyProvider =
    NotifierProvider<HostProfileDirtyNotifier, bool>(
      HostProfileDirtyNotifier.new,
    );
