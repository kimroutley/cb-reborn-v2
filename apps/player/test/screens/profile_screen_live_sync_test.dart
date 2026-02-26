import 'dart:async';

import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_player/screens/profile_screen.dart';
import 'package:cb_player/widgets/profile_action_buttons.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopFirestore extends Fake implements FirebaseFirestore {}

class _FakeUser extends Fake implements User {
  _FakeUser({required this.id, required this.mail, required this.name});

  final String id;
  final String? mail;
  String? name;

  @override
  String get uid => id;

  @override
  String? get email => mail;

  @override
  String? get displayName => name;

  @override
  Future<void> updateDisplayName(String? displayName) async {
    name = displayName;
  }
}

class _TestProfileRepository extends ProfileRepository {
  _TestProfileRepository({required this.watch, this.initial})
    : super(firestore: _NoopFirestore());

  final Stream<Map<String, dynamic>?> watch;
  final Map<String, dynamic>? initial;

  @override
  Future<Map<String, dynamic>?> loadProfile(String uid) async => initial;

  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) => watch;

  @override
  Future<bool> isUsernameAvailable(
    String username, {
    String? excludingUid,
  }) async {
    return true;
  }

  @override
  Future<bool> isPublicPlayerIdAvailable(
    String publicPlayerId, {
    String? excludingUid,
  }) async {
    return true;
  }

  @override
  Future<void> upsertBasicProfile({
    required String uid,
    required String username,
    required String? email,
    required bool isHost,
    String? publicPlayerId,
    String? avatarEmoji,
    String? preferredStyle,
  }) async {}
}

void main() {
  testWidgets(
    'queues remote profile updates while dirty then applies on discard',
    (tester) async {
      final controller = StreamController<Map<String, dynamic>?>.broadcast();
      addTearDown(controller.close);

      final user = _FakeUser(id: 'u1', mail: 'u1@example.com', name: 'Starter');
      final repository = _TestProfileRepository(
        watch: controller.stream,
        initial: <String, dynamic>{
          'username': 'Starter',
          'publicPlayerId': 'starter',
          'avatarEmoji': clubAvatarEmojis.first,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(
                repository: repository,
                currentUserResolver: () => user,
                startInEditMode: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final usernameEditable = find.descendant(
        of: find.byType(CBTextField).first,
        matching: find.byType(EditableText),
      );
      expect(
        tester.widget<EditableText>(usernameEditable).controller.text,
        'Starter',
      );

      final dirtyController = tester
          .widget<EditableText>(usernameEditable)
          .controller;
      dirtyController.value = const TextEditingValue(
        text: 'Dirty Local',
        selection: TextSelection.collapsed(offset: 11),
      );
      await tester.pump();

      controller.add(<String, dynamic>{
        'username': 'Remote Applied',
        'publicPlayerId': 'remote_applied',
        'avatarEmoji': clubAvatarEmojis.first,
      });
      await tester.pump();

      expect(
        find.text(
          'Cloud profile update detected. Save/discard to sync latest values.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<EditableText>(usernameEditable).controller.text,
        'Dirty Local',
      );

      final discardActions = tester.widget<ProfileActionButtons>(
        find.byType(ProfileActionButtons),
      );
      discardActions.onDiscard();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('REMOTE APPLIED'), findsOneWidget);
    },
  );

  testWidgets(
    'queues remote profile updates while dirty then applies after save',
    (tester) async {
      final controller = StreamController<Map<String, dynamic>?>.broadcast();
      addTearDown(controller.close);

      final user = _FakeUser(id: 'u2', mail: 'u2@example.com', name: 'Starter');
      final repository = _TestProfileRepository(
        watch: controller.stream,
        initial: <String, dynamic>{
          'username': 'Starter',
          'publicPlayerId': 'starter',
          'avatarEmoji': clubAvatarEmojis.first,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(
                repository: repository,
                currentUserResolver: () => user,
                startInEditMode: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final usernameEditable = find.descendant(
        of: find.byType(CBTextField).first,
        matching: find.byType(EditableText),
      );
      final saveController = tester
          .widget<EditableText>(usernameEditable)
          .controller;
      saveController.value = const TextEditingValue(
        text: 'Local Save',
        selection: TextSelection.collapsed(offset: 10),
      );
      await tester.pump();

      controller.add(<String, dynamic>{
        'username': 'Remote After Save',
        'publicPlayerId': 'remote_after_save',
        'avatarEmoji': clubAvatarEmojis.first,
      });
      await tester.pump();

      expect(
        find.text(
          'Cloud profile update detected. Save/discard to sync latest values.',
        ),
        findsOneWidget,
      );

      final saveActions = tester.widget<ProfileActionButtons>(
        find.byType(ProfileActionButtons),
      );
      saveActions.onSave();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('REMOTE AFTER SAVE'), findsOneWidget);
      expect(
        find.text(
          'Cloud profile update detected. Save/discard to sync latest values.',
        ),
        findsNothing,
      );
    },
  );
}
