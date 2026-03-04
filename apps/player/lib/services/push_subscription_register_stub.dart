const String vapidPublicKeyBase64 =
    'BD1-M8Df2DH3Nu-ykoyibEnrANu1zYJlqGH8DRRzm5hXe_cFKNKhlrw2QbDmA8tVrrL9daqldvzCMwwIqLR9G5M';

/// No-op on non-web platforms.
Future<Map<String, dynamic>?> getPushSubscription(String vapidKey) async =>
    null;
