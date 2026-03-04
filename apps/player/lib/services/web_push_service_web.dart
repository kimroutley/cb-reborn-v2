import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

/// Manages Web Push notifications and PWA installation.
class WebPushService extends Notifier<WebPushState> {
  @override
  WebPushState build() {
    return const WebPushState();
  }

  /// PWA install prompt support is optional; keep this as a no-op fallback.
  void initPwaInstallPrompt() {
    if (!kIsWeb) {
      return;
    }
    state = state.copyWith(canInstallPwa: false);
  }

  Future<void> checkPermissionStatus() async {
    if (!kIsWeb) {
      return;
    }

    try {
      final permission = web.Notification.permission.toString();
      state = state.copyWith(
        isSupported: true,
        permissionStatus: _parsePermission(permission),
      );
    } catch (e) {
      debugPrint('[WebPushService] Error checking permission: $e');
      state = state.copyWith(isSupported: false);
    }
  }

  Future<bool> requestPermission() async {
    if (!kIsWeb) {
      return false;
    }

    if (!state.isSupported) {
      await checkPermissionStatus();
      if (!state.isSupported) {
        return false;
      }
    }

    try {
      final jsResult = await web.Notification.requestPermission().toDart;
      final status = _parsePermission(jsResult.toDart);
      state = state.copyWith(permissionStatus: status);
      return status == WebNotificationPermission.granted;
    } catch (e) {
      debugPrint('[WebPushService] Error requesting permission: $e');
      return false;
    }
  }

  Future<void> promptPwaInstall() async {
    if (!kIsWeb) {
      return;
    }
    state = state.copyWith(canInstallPwa: false);
  }

  Future<Map<String, dynamic>?> subscribeToPush(String vapidPublicKey) async {
    if (!kIsWeb || !state.isSupported) {
      return null;
    }
    return null;
  }

  WebNotificationPermission _parsePermission(String permission) {
    switch (permission) {
      case 'granted':
        return WebNotificationPermission.granted;
      case 'denied':
        return WebNotificationPermission.denied;
      default:
        return WebNotificationPermission.defaultStatus;
    }
  }
}

enum WebNotificationPermission {
  defaultStatus,
  granted,
  denied,
}

@immutable
class WebPushState {
  final bool isSupported;
  final WebNotificationPermission permissionStatus;
  final bool canInstallPwa;
  final Map<String, dynamic>? subscriptionPayload;

  const WebPushState({
    this.isSupported = false,
    this.permissionStatus = WebNotificationPermission.defaultStatus,
    this.canInstallPwa = false,
    this.subscriptionPayload,
  });

  WebPushState copyWith({
    bool? isSupported,
    WebNotificationPermission? permissionStatus,
    bool? canInstallPwa,
    Map<String, dynamic>? subscriptionPayload,
  }) {
    return WebPushState(
      isSupported: isSupported ?? this.isSupported,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      canInstallPwa: canInstallPwa ?? this.canInstallPwa,
      subscriptionPayload: subscriptionPayload ?? this.subscriptionPayload,
    );
  }
}

final webPushServiceProvider =
    NotifierProvider<WebPushService, WebPushState>(WebPushService.new);
