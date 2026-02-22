import 'package:cb_comms/cb_comms_player.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_bridge.dart';
import '../profile_edit_guard.dart';
import '../widgets/custom_drawer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.repository,
    this.currentUserResolver,
    this.profileStreamFactory,
    this.authStateChangesResolver,
    this.startInEditMode = false,
  });

  final ProfileRepository? repository;
  final User? Function()? currentUserResolver;
  final Stream<Map<String, dynamic>?> Function(String uid)?
      profileStreamFactory;
  final Stream<User?> Function()? authStateChangesResolver;
  final bool startInEditMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SharedProfileScreen(
      repository: repository,
      currentUserResolver: currentUserResolver,
      profileStreamFactory: profileStreamFactory,
      authStateChangesResolver: authStateChangesResolver,
      startInEditMode: startInEditMode,
      drawer: const CustomDrawer(),
      onDirtyChanged: (isDirty) {
        // Only update if changed to avoid loop if state was updated from elsewhere
        if (ref.read(playerProfileDirtyProvider) != isDirty) {
          ref.read(playerProfileDirtyProvider.notifier).setDirty(isDirty);
        }
      },
      bridgePlayerId: ref.watch(playerBridgeProvider).myPlayerId,
    );
  }
}
