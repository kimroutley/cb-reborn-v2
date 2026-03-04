import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebPushService extends Notifier<WebPushState> {
  @override
  WebPushState build() => const WebPushState();

  Future<void> checkPermissionStatus() async {}
  Future<bool> requestPermission() async => false;
  
  void initPwaInstallPrompt() {}
  Future<void> promptPwaInstall() async {}
  
  Future<Map<String, dynamic>?> subscribeToPush(String vapidPublicKey) async => null;
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
