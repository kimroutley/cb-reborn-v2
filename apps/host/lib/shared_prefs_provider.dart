import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider not initialized');
});

class HostIntroSeenNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return prefs.getBool('hasSeenHostIntro') ?? false;
  }

  void setSeen(bool seen) {
    state = seen;
  }
}

final hostIntroSeenProvider = NotifierProvider<HostIntroSeenNotifier, bool>(HostIntroSeenNotifier.new);
