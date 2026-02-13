import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingJoinUrlNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setValue(String? value) {
    state = value;
  }
}

final pendingJoinUrlProvider =
    NotifierProvider<PendingJoinUrlNotifier, String?>(
  PendingJoinUrlNotifier.new,
);
