import 'push_subscription_register_stub.dart'
    if (dart.library.html) 'push_subscription_register_web.dart' as impl;

/// VAPID public key (base64url). Set when deploying the push Cloud Function.
/// Generate with: npx web-push generate-vapid-keys
const String vapidPublicKeyBase64 = '';

/// Returns a Web Push subscription map for the current client (web only).
/// Returns null on non-web or if subscription fails.
Future<Map<String, dynamic>?> getPushSubscription([
  String? vapidPublicKeyBase64,
]) =>
    impl.getPushSubscription(vapidPublicKeyBase64);

bool get isPushSubscriptionSupported => impl.isPushSubscriptionSupported;
