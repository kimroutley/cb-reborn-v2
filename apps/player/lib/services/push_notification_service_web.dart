import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../notifications_prompt_provider.dart' as provider;

bool get isNotificationPermissionSupported {
  try {
    web.Notification.permission;
    return true;
  } catch (_) {
    return false;
  }
}

bool get isPwaInstallPromptAvailable => _deferredPrompt != null;

bool checkNotificationPermissionGranted() {
  try {
    return web.Notification.permission == 'granted';
  } catch (_) {
    return false;
  }
}

Future<provider.NotificationPermission>
    requestNotificationPermission() async {
  try {
    final jsResult = await web.Notification.requestPermission().toDart;
    final result = (jsResult).toDart;
    if (result == 'granted') return provider.NotificationPermission.granted;
    if (result == 'denied') return provider.NotificationPermission.denied;
    return provider.NotificationPermission.defaultState;
  } catch (_) {
    return provider.NotificationPermission.denied;
  }
}

// PWA "Add to Home Screen" install prompt -----------------------------------

JSObject? _deferredPrompt;

void initPwaInstallListener() {
  web.window.addEventListener(
    'beforeinstallprompt',
    ((web.Event event) {
      event.preventDefault();
      _deferredPrompt = event as JSObject;
    }).toJS,
  );
}

Future<void> showPwaInstallPrompt() async {
  final prompt = _deferredPrompt;
  if (prompt == null) return;
  _callPromptOnJs(prompt);
  _deferredPrompt = null;
}

@JS('Reflect.get')
external JSAny? _reflectGet(JSObject target, JSString propertyKey);

void _callPromptOnJs(JSObject obj) {
  final fn = _reflectGet(obj, 'prompt'.toJS);
  if (fn != null) {
    (fn as JSFunction).callAsFunction(obj);
  }
}
