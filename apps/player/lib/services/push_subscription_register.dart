import 'push_subscription_register_stub.dart'
    if (dart.library.html) 'push_subscription_register_web.dart' as impl;

/// VAPID public key (base64url). Must match firebase functions:config:set vapid.public_key.
/// See functions/README.md for setup.
const String vapidPublicKeyBase64 =
    'BG4bHb-5T8VGVELR9iSD3nQ8afshBHdCK6UYYoWXbuMnsgZvfxv3nTepIBA8tnNPmnHZpB0fU1FS3zoVvTBhFO0';

/// Returns a Web Push subscription map for the current client (web only).
/// Returns null on non-web or if subscription fails.
Future<Map<String, dynamic>?> getPushSubscription([
  String? vapidPublicKeyBase64,
]) =>
    impl.getPushSubscription(vapidPublicKeyBase64);

bool get isPushSubscriptionSupported => impl.isPushSubscriptionSupported;
