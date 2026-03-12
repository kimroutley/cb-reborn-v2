import 'package:cb_theme/cb_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_edit_guard.dart';
import '../widgets/custom_drawer.dart';

/// Player profile screen — delegates entirely to the shared implementation
/// in [SharedProfileScreen] from `cb_theme`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.repository,
    this.currentUserResolver,
    this.profileStreamFactory,
    this.authStateChangesResolver,
    this.startInEditMode = false,
  });

  final dynamic repository;
  final User? Function()? currentUserResolver;
  final Stream<Map<String, dynamic>?> Function(String uid)?
      profileStreamFactory;
  final Stream<User?> Function()? authStateChangesResolver;
  final bool startInEditMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SharedProfileScreen(
      isHost: false,
      startInEditMode: startInEditMode,
      drawer: const CustomDrawer(),
      onDirtyChanged: (dirty) {
        ref.read(playerProfileDirtyProvider.notifier).setDirty(dirty);
      },
    );
  }
}
