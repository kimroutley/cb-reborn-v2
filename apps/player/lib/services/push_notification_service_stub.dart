// Stub for non-web platforms. Notification permission and PWA install are unsupported.

/// Returns 'denied' on non-web (no API).
Future<String> requestNotificationPermission() async => 'denied';

/// Whether the platform supports requesting notification permission (web only).
bool get isNotificationPermissionSupported => false;

/// Whether the PWA install prompt is available (web only, when browser supports it).
bool get isPwaInstallPromptAvailable => false;

/// Shows the PWA "Add to Home Screen" prompt. No-op on non-web.
Future<bool> showPwaInstallPrompt() async => false;
