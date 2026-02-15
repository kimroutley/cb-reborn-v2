import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cloud_host_bridge.dart';
import '../../host_bridge.dart';

class LobbyConfigTile extends ConsumerWidget {
  final GameState gameState;
  final Game controller;
  final Color primaryColor;
  final Color secondaryColor;

  const LobbyConfigTile({
    super.key,
    required this.gameState,
    required this.controller,
    required this.primaryColor,
    required this.secondaryColor,
  });

  Future<void> _setSyncMode(
    WidgetRef ref,
    Game controller,
    SyncMode newMode,
  ) async {
    controller.setSyncMode(newMode);

    if (newMode == SyncMode.cloud) {
      await ref.read(hostBridgeProvider).stop();
      await ref.read(cloudHostBridgeProvider).start();
      return;
    }

    await ref.read(cloudHostBridgeProvider).stop();
    await ref.read(hostBridgeProvider).start();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CBGlassTile(
      title: "PROTOCOL SETTINGS",
      accentColor: secondaryColor,
      isPrismatic: true,
      icon: Icon(Icons.settings_input_component_rounded, color: secondaryColor),
      content: Row(
        children: [
          _buildConfigOption(
              context, "SYNC", gameState.syncMode.name, primaryColor, () {
            HapticService.selection();
            final newMode = gameState.syncMode == SyncMode.local
                ? SyncMode.cloud
                : SyncMode.local;
            unawaited(_setSyncMode(ref, controller, newMode));
          }),
          const SizedBox(width: 12),
          _buildConfigOption(
              context, "STYLE", gameState.gameStyle.label, secondaryColor, () {
            HapticService.selection();
            controller.setGameStyle(gameState.gameStyle == GameStyle.chaos
                ? GameStyle.offensive
                : GameStyle.chaos);
          }),
        ],
      ),
    );
  }

  Widget _buildConfigOption(BuildContext context, String label, String value,
      Color color, VoidCallback onTap) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: CBColors.boxGlow(color, intensity: 0.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: CBTypography.labelSmall.copyWith(
                      fontSize: 8,
                      color: scheme.onSurface.withValues(alpha: 0.3),
                      letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(value.toUpperCase(),
                  style: CBTypography.labelSmall.copyWith(
                      color: color, // Migrated from CBColors.neonBlue
                      fontWeight: FontWeight.w900,
                      fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
