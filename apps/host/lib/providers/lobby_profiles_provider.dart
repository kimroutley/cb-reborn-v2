import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firestore_provider.dart';

/// Provider that fetches user profiles for all players in the lobby in batches.
/// This avoids the N+1 read problem where each player in the list triggers a separate listener.
final lobbyProfilesProvider =
    StreamProvider.autoDispose<Map<String, Map<String, dynamic>>>((ref) {
      final gameState = ref.watch(gameProvider);
      final uids =
          gameState.players
              .map((p) => p.authUid)
              .where((uid) => uid != null && uid.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList()
            ..sort();

      if (uids.isEmpty) {
        return Stream.value({});
      }

      final firestore = ref.watch(firestoreProvider);
      final chunks = <List<String>>[];
      for (var i = 0; i < uids.length; i += 10) {
        chunks.add(
          uids.sublist(i, (i + 10) > uids.length ? uids.length : i + 10),
        );
      }

      final streams = chunks.map((chunk) {
        return firestore
            .collection('user_profiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .map((qs) {
              return {for (var doc in qs.docs) doc.id: doc.data()};
            });
      }).toList();

      return _combineLatestMaps(streams);
    });

/// Combines a list of streams of maps into a single stream of a merged map.
Stream<Map<String, Map<String, dynamic>>> _combineLatestMaps(
  List<Stream<Map<String, Map<String, dynamic>>>> streams,
) {
  if (streams.isEmpty) return Stream.value({});

  final controller = StreamController<Map<String, Map<String, dynamic>>>();
  final values = List<Map<String, Map<String, dynamic>>?>.filled(
    streams.length,
    null,
  );
  final hasValue = List<bool>.filled(streams.length, false);
  int activeStreams = streams.length;
  final subscriptions = <StreamSubscription>[];

  void checkEmit() {
    if (hasValue.every((h) => h)) {
      final merged = <String, Map<String, dynamic>>{};
      for (var map in values) {
        if (map != null) merged.addAll(map);
      }
      controller.add(merged);
    }
  }

  for (var i = 0; i < streams.length; i++) {
    subscriptions.add(
      streams[i].listen(
        (data) {
          values[i] = data;
          hasValue[i] = true;
          checkEmit();
        },
        onError: controller.addError,
        onDone: () {
          activeStreams--;
          if (activeStreams == 0) controller.close();
        },
      ),
    );
  }

  controller.onCancel = () {
    for (var sub in subscriptions) {
      sub.cancel();
    }
  };

  return controller.stream;
}
