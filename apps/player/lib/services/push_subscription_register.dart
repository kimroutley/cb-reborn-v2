import 'push_subscription_register_stub.dart'
    if (dart.library.html) 'push_subscription_register_web.dart' as impl;

/// VAPID public key (base64url). Set when deploying the push Cloud Function.
/// Generate with: npx web-push generate-vapid-keys (or scripts/setup_push_vapid.ps1)
const String vapidPublicKeyBase64 =
    'BP2O8P3Tj8N4Z5PtSUaFi_vRq8F_jHEGtaQqRcZlbDK6Ddzbnmqfu3nXa9DEUr7za8m6ghctcy11EhcPCXXw9Vo';

/// Returns a Web Push subscription map for the current client (web only).
/// Returns null on non-web or if subscription fails.
Future<Map<String, dynamic>?> getPushSubscription([
  String? vapidPublicKeyBase64,
]) =>
    impl.getPushSubscription(vapidPublicKeyBase64);

bool get isPushSubscriptionSupported => impl.isPushSubscriptionSupported;
