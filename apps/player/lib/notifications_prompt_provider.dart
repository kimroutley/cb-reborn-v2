import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/push_notification_service.dart';

const _keyNotificationPermissionAsked = 'cb_notification_permission_asked';

class NotificationsPromptState {
  const NotificationsPromptState({
    this.permission = NotificationPermission.default_,
    this.askedBefore = false,
    this.isRequesting = false,
  });

  final NotificationPermission permission;
  final bool askedBefore;
  final bool isRequesting;

  NotificationsPromptState copyWith({
    NotificationPermission? permission,
    bool? askedBefore,
    bool? isRequesting,
  }) {
    return NotificationsPromptState(
      permission: permission ?? this.permission,
      askedBefore: askedBefore ?? this.askedBefore,
      isRequesting: isRequesting ?? this.isRequesting,
    );
  }

  bool get isGranted => permission == NotificationPermission.granted;
  bool get canAsk => !isGranted && !isRequesting;
}

class NotificationsPromptNotifier extends Notifier<NotificationsPromptState> {
  @override
  NotificationsPromptState build() => const NotificationsPromptState();

  Future<void> loadAskedBefore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final asked = prefs.getBool(_keyNotificationPermissionAsked) ?? false;
      state = state.copyWith(askedBefore: asked);
    } catch (_) {}
  }

  Future<NotificationPermission> requestPermission() async {
    if (!PushNotificationService.isNotificationPermissionSupported) {
      return NotificationPermission.unsupported;
    }
    state = state.copyWith(isRequesting: true);
    try {
      final result =
          await PushNotificationService.requestNotificationPermission();
      state = state.copyWith(
        permission: result,
        askedBefore: true,
        isRequesting: false,
      );
      if (result != NotificationPermission.default_) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyNotificationPermissionAsked, true);
      }
      return result;
    } catch (e) {
      debugPrint('[NotificationsPrompt] requestPermission failed: $e');
      state = state.copyWith(isRequesting: false);
      return NotificationPermission.denied;
    }
  }
}

final notificationsPromptProvider =
    NotifierProvider<NotificationsPromptNotifier, NotificationsPromptState>(
        NotificationsPromptNotifier.new);
