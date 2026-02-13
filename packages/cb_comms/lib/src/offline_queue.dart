import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages a persistent queue of actions to be sent when online.
class OfflineQueue {
  static const String _kQueueKey = 'offline_actions_queue';
  static const String _kJoinCodeKey = 'offline_queue_join_code';

  final List<Map<String, dynamic>> _queue = [];
  String? _joinCode;
  SharedPreferences? _prefs;

  /// The join code associated with the currently queued actions.
  String? get joinCode => _joinCode;

  /// The list of pending actions.
  List<Map<String, dynamic>> get queue => List.unmodifiable(_queue);

  /// Initializes the queue by loading from SharedPreferences.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    if (_prefs == null) return;
    _joinCode = _prefs!.getString(_kJoinCodeKey);
    final List<String>? jsonList = _prefs!.getStringList(_kQueueKey);

    if (jsonList != null) {
      _queue.clear();
      for (final jsonStr in jsonList) {
        try {
          _queue.add(json.decode(jsonStr) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('[OfflineQueue] Failed to decode action: $e');
        }
      }
    }
    if (_queue.isNotEmpty) {
      debugPrint('[OfflineQueue] Loaded ${_queue.length} actions for game $_joinCode');
    }
  }

  /// Adds an action to the queue.
  ///
  /// If the [joinCode] differs from the current queue's join code, the queue is cleared first.
  Future<void> add(String joinCode, Map<String, dynamic> action) async {
    if (_prefs == null) await init();

    if (_joinCode != null && _joinCode != joinCode) {
      debugPrint('[OfflineQueue] Clearing queue for old game $_joinCode (new: $joinCode)');
      await clear();
    }

    _joinCode = joinCode;
    _queue.add(action);
    await _save();
    debugPrint('[OfflineQueue] Action queued. Total: ${_queue.length}');
  }

  /// Removes the first action from the queue.
  Future<void> removeFirst() async {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0);
      await _save();
    }
  }

  /// Clears the entire queue and resets the join code.
  Future<void> clear() async {
    _queue.clear();
    _joinCode = null;
    if (_prefs != null) {
      await _prefs!.remove(_kQueueKey);
      await _prefs!.remove(_kJoinCodeKey);
    }
    debugPrint('[OfflineQueue] Queue cleared');
  }

  Future<void> _save() async {
    if (_prefs == null) return;

    if (_joinCode != null) {
      await _prefs!.setString(_kJoinCodeKey, _joinCode!);
    } else {
      await _prefs!.remove(_kJoinCodeKey);
    }

    final List<String> jsonList = _queue.map((a) => json.encode(a)).toList();
    await _prefs!.setStringList(_kQueueKey, jsonList);
  }
}
