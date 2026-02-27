// Stub for non-web: no push subscription.

Future<Map<String, dynamic>?> getPushSubscription([
  String? vapidPublicKeyBase64,
]) async {
  return null;
}

bool get isPushSubscriptionSupported => false;
