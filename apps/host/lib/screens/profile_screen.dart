import 'package:cb_comms/cb_comms.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_edit_guard.dart';
import '../widgets/custom_drawer.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.repository,
    this.currentUserResolver,
    this.startInEditMode = false,
  });

  final ProfileRepository? repository;
  final User? Function()? currentUserResolver;
  final bool startInEditMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SharedProfileScreen(
      repository: repository,
      currentUserResolver: currentUserResolver,
      startInEditMode: startInEditMode,
      drawer: const CustomDrawer(),
      onDirtyChanged: (isDirty) {
        if (ref.read(hostProfileDirtyProvider) != isDirty) {
          ref.read(hostProfileDirtyProvider.notifier).setDirty(isDirty);
        }
      },
    );
  }
}
