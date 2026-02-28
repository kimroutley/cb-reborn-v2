import 'package:cb_player/profile_edit_guard.dart';
import 'package:cb_player/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.id);

  final String id;

  @override
  String get uid => id;

  @override
  String? get email => 'nightfox@example.com';

  @override
  String? get displayName => 'Night Fox';

  @override
  List<UserInfo> get providerData => const <UserInfo>[];
}

void main() {
  testWidgets('profile pop asks to discard unsaved changes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final navKey = GlobalKey<NavigatorState>();
    final user = _FakeUser('u-unsaved-pop');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navKey,
          home: Builder(
class _NoopFirestore extends Fake implements FirebaseFirestore {}

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
  Future<bool> isUsernameAvailable(String username, {String? excludingUid})
      async {
    return true;
  }

  @override
  Future<bool> isPublicPlayerIdAvailable(String publicPlayerId,
      {String? excludingUid}) async {
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
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
    final controller = StreamController<Map<String, dynamic>?>.broadcast();
    addTearDown(controller.close);

    final user = _FakeUser(id: 'u-pop', mail: 'u-pop@example.com', name: 'Pop');
    final repository = _TestProfileRepository(
      watch: controller.stream,
      initial: <String, dynamic>{
        'username': 'Pop',
        'publicPlayerId': 'pop',
        'avatarEmoji': clubAvatarEmojis.first,
      },
    );
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileScreen(
                            currentUserResolver: () => user,
                            startInEditMode: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Profile'),
                  ),
                ),
              );
            },
          ),
        ),
                            repository: repository,
                            currentUserResolver: () => user,
    );

    await tester.tap(find.text('Open Profile'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final usernameField = find.byType(TextField).first;
    await tester.enterText(usernameField, 'Night Fox');
    await tester.pump();
    expect(container.read(playerProfileDirtyProvider), isTrue);

    await navKey.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Discard Changes?'), findsOneWidget);

    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(container.read(playerProfileDirtyProvider), isTrue);

    await navKey.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('DISCARD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ProfileScreen), findsNothing);
    expect(container.read(playerProfileDirtyProvider), isFalse);
  });
}
