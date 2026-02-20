import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

class FirebaseAnalyticsProvider implements AnalyticsProvider {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsProvider(this._analytics);

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
    if (kDebugMode) {
      debugPrint('Firebase Analytics collection enabled: $enabled');
    }
  }

  @override
  Future<void> logScreenView({String? screenName, String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
    if (kDebugMode) {
      debugPrint('Firebase Analytics: Screen view - $screenName');
    }
  }

  @override
  Future<void> logEvent(
      {required String name, Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
    if (kDebugMode) {
      debugPrint('Firebase Analytics: Event - $name, Parameters: $parameters');
    }
  }
}
