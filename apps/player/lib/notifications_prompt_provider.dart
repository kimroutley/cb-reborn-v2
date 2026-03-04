import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/push_notification_service.dart';

enum NotificationPermission { granted, denied, defaultState }

class NotificationsPromptState {
  final bool isGranted;
  final bool isRequesting;
  final bool askedBefore;

  const NotificationsPromptState({
    this.isGranted = false,
    this.isRequesting = false,
    this.askedBefore = false,
  });

  NotificationsPromptState copyWith({
    bool? isGranted,
    bool? isRequesting,
    bool? askedBefore,
  }) {
    return NotificationsPromptState(
      isGranted: isGranted ?? this.isGranted,
      isRequesting: isRequesting ?? this.isRequesting,
      askedBefore: askedBefore ?? this.askedBefore,
    );
  }
}

class NotificationsPromptNotifier extends Notifier<NotificationsPromptState> {
  static const _askedKey = 'notification_permission_asked';

  @override
  NotificationsPromptState build() => const NotificationsPromptState();

  Future<void> loadAskedBefore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final asked = prefs.getBool(_askedKey) ?? false;
      final granted = checkNotificationPermissionGranted();
      state = state.copyWith(askedBefore: asked, isGranted: granted);
    } catch (_) {
      // SharedPreferences may throw on some web environments; degrade gracefully.
    }
  }

  Future<NotificationPermission> requestPermission() async {
    state = state.copyWith(isRequesting: true);
    try {
      final result = await requestNotificationPermission();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_askedKey, true);
      state = state.copyWith(
        isGranted: result == NotificationPermission.granted,
        isRequesting: false,
        askedBefore: true,
      );
      return result;
    } catch (_) {
      state = state.copyWith(isRequesting: false);
      return NotificationPermission.denied;
    }
  }
}

final notificationsPromptProvider =
    NotifierProvider<NotificationsPromptNotifier, NotificationsPromptState>(
  NotificationsPromptNotifier.new,
);
