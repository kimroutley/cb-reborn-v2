import 'push_notification_service_stub.dart'
    if (dart.library.html) 'push_notification_service_web.dart' as impl;

/// Notification permission status.
enum NotificationPermission {
  granted,
  denied,
  default_,
  unsupported,
}

/// Request notification permission (web: browser prompt; other platforms: no-op).
/// After this, call [PushSubscriptionService] to register for push if granted.
Future<NotificationPermission> requestNotificationPermission() async {
  final result = await impl.requestNotificationPermission();
  switch (result) {
    case 'granted':
      return NotificationPermission.granted;
    case 'denied':
      return NotificationPermission.denied;
    case 'default':
      return NotificationPermission.default_;
    case 'unsupported':
      return NotificationPermission.unsupported;
    default:
      return NotificationPermission.denied;
  }
}

/// Whether this platform supports requesting notification permission (true on web).
bool get isNotificationPermissionSupported =>
    impl.isNotificationPermissionSupported;

/// Whether the PWA "Add to Home Screen" prompt is available (web, when browser supports it).
bool get isPwaInstallPromptAvailable => impl.isPwaInstallPromptAvailable;

/// Show the PWA install prompt. Returns true if the user accepted.
Future<bool> showPwaInstallPrompt() => impl.showPwaInstallPrompt();
