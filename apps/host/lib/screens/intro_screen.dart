import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'host_navigation_shell.dart';
import 'host_onboarding_screen.dart';

class HostIntroScreen extends ConsumerStatefulWidget {
  const HostIntroScreen({super.key});

  @override
  ConsumerState<HostIntroScreen> createState() => _HostIntroScreenState();
}

class _HostIntroScreenState extends ConsumerState<HostIntroScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.user == null) {
      return const HostOnboardingScreen();
    }

    return const HostNavigationShell();
  }
}
