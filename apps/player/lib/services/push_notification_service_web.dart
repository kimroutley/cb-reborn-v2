// Web implementation: uses dart:html for Notification API and PWA install.

import 'dart:html' as html;

/// Returns 'granted', 'denied', 'default', or 'unsupported'.
Future<String> requestNotificationPermission() async {
  if (!html.Notification.supported) {
    return 'unsupported';
  }
  final result = await html.Notification.requestPermission();
  return result;
}

bool get isNotificationPermissionSupported => html.Notification.supported;

/// Expose from window.__cbPwaInstallPrompt (set by index.html).
bool get isPwaInstallPromptAvailable {
  final v = (html.window as dynamic).__cbPwaInstallPrompt;
  return v != null;
}

/// Calls the stored beforeinstallprompt.prompt(); returns true if the prompt was shown.
Future<bool> showPwaInstallPrompt() async {
  final prompt = (html.window as dynamic).__cbPwaInstallPrompt;
  if (prompt == null) return false;
  try {
    (prompt as dynamic).prompt();
    return true;
  } catch (_) {
    return false;
  }
}
