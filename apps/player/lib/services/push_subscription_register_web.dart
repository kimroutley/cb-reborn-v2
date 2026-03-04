import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const String vapidPublicKeyBase64 =
    'BD1-M8Df2DH3Nu-ykoyibEnrANu1zYJlqGH8DRRzm5hXe_cFKNKhlrw2QbDmA8tVrrL9daqldvzCMwwIqLR9G5M';

/// Subscribe the active service worker to push and return the subscription
/// as a JSON-serialisable map (endpoint + keys). Returns `null` if the
/// browser doesn't support push or the service worker isn't ready.
Future<Map<String, dynamic>?> getPushSubscription(String vapidKey) async {
  if (vapidKey.isEmpty) return null;
  try {
    final sw = web.window.navigator.serviceWorker;
    final registration = await sw.ready.toDart;

    final applicationServerKey = _urlBase64ToUint8Array(vapidKey);
    final sub = await registration.pushManager
        .subscribe(
          web.PushSubscriptionOptionsInit(
            userVisibleOnly: true,
            applicationServerKey: applicationServerKey.buffer.toJS,
          ),
        )
        .toDart;

    // Serialise the subscription into a portable map.
    final jsonStr = _subscriptionToJson(sub);
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Uint8List _urlBase64ToUint8Array(String base64String) {
  final padding = '=' * ((4 - base64String.length % 4) % 4);
  final base64 = (base64String + padding)
      .replaceAll('-', '+')
      .replaceAll('_', '/');
  return base64Decode(base64);
}

String? _subscriptionToJson(web.PushSubscription sub) {
  try {
    // PushSubscription.toJSON() returns a JS object. Convert to JSON string.
    final jsObj = sub.toJSON();
    return _jsObjectToJsonString(jsObj);
  } catch (_) {
    return null;
  }
}

@JS('JSON.stringify')
external JSString _jsonStringify(JSAny? value);

String _jsObjectToJsonString(JSObject obj) {
  return _jsonStringify(obj).toDart;
}
