import 'package:flutter/services.dart';

/// Haptic feedback service providing tactile responses.
class HapticService {
  HapticService._();

  static bool _enabled = true;

  /// Enable or disable haptic feedback globally.
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Light impact feedback (e.g., button taps, selections).
  static void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact feedback (e.g., mode changes, confirmations).
  static void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback (e.g., errors, critical actions).
  static void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Selection click (e.g., scrolling through options).
  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Vibrate feedback (basic vibration pattern).
  static void vibrate() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  /// Success pattern (double light).
  static Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Error pattern (heavy impact).
  static void error() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Night action pattern (medium impact).
  static void nightAction() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Vote cast pattern (light + selection).
  static Future<void> voteCast() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 30));
    await HapticFeedback.lightImpact();
  }

  /// Alert Dispatch (Triple pulse for new messages)
  static Future<void> alertDispatch() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Eyes Open (Strong pulse)
  static void eyesOpen() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  /// Eyes Closed (Gentle double tap)
  static Future<void> eyesClosed() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.lightImpact();
  }

  /// Roofied Alert (Aggressive triple pulse)
  static Future<void> roofied() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }
}
