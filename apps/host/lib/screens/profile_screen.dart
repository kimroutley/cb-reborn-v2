import 'package:cb_theme/cb_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_edit_guard.dart';
import '../host_destinations.dart';
import '../widgets/custom_drawer.dart';

/// Host profile screen — delegates entirely to the shared implementation
/// in [SharedProfileScreen] from `cb_theme`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.repository,
    this.currentUserResolver,
    this.startInEditMode = false,
  });

  final dynamic repository;
  final User? Function()? currentUserResolver;
  final bool startInEditMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SharedProfileScreen(
      isHost: true,
      startInEditMode: startInEditMode,
      drawer: const CustomDrawer(
        currentDestination: HostDestination.profile,
      ),
      onDirtyChanged: (dirty) {
        ref.read(hostProfileDirtyProvider.notifier).setDirty(dirty);
      },
    );
  }
}
