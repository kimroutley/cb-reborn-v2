import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'stats_view.dart';

class HostHallOfFameScreen extends ConsumerWidget {
  const HostHallOfFameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CBPrismScaffold(
      title: 'HALL OF FAME',
      drawer: const CustomDrawer(
        currentDestination: HostDestination.hallOfFame,
      ),
      actions: const [SimulationModeBadgeAction()],
      body: StatsView(gameState: ref.watch(gameProvider)),
    );
  }
}
