// Web: get a Web Push subscription via PushManager for the current service worker.

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Returns a map suitable for Firestore: endpoint, keys.p256dh, keys.auth (base64).
/// Returns null if not supported, key is missing, or subscribe fails.
Future<Map<String, dynamic>?> getPushSubscription([
  String? vapidPublicKeyBase64,
]) async {
  if (vapidPublicKeyBase64 == null ||
      vapidPublicKeyBase64.isEmpty ||
      !html.Notification.supported) {
    return null;
  }

  try {
    final container = html.window.navigator.serviceWorker;
    final reg = await container.ready;

    // applicationServerKey: Uint8List from base64url-decoded key.
    final decoded = base64Url.decode(base64Url.normalize(vapidPublicKeyBase64));

    final sub = await reg.pushManager.subscribe({
      'userVisibleOnly': true,
      'applicationServerKey': decoded,
    });

    final endpoint = sub.endpoint;
    if (endpoint == null || endpoint.isEmpty) return null;

    final p256dh = sub.getKey('p256dh');
    final auth = sub.getKey('auth');
    if (p256dh == null || auth == null) return null;

    final p256dhList = Uint8List.view(p256dh);
    final authList = Uint8List.view(auth);

    return {
      'endpoint': endpoint,
      'keys': {
        'p256dh': base64Url.encode(p256dhList),
        'auth': base64Url.encode(authList),
      },
      'expirationTime': sub.expirationTime,
    };
  } catch (e) {
    // Not supported or user denied
    return null;
  }
}

bool get isPushSubscriptionSupported =>
    html.Notification.supported &&
    (html.window.navigator.serviceWorker != null);
