import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cloud_host_bridge.dart';
import '../../host_bridge.dart';
import '../../sync_mode_runtime.dart';

class LobbyConfigTile extends ConsumerWidget {
  const LobbyConfigTile({
    super.key,
    required this.gameState,
    required this.controller,
    required this.onManualAssign,
  });

  final GameState gameState;
  final Game controller;
  final VoidCallback onManualAssign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final sessionController = ref.read(sessionProvider.notifier);
    final requiredConfirmations =
        gameState.players.where((p) => !p.isBot).length;
    final confirmedCount = session.roleConfirmedPlayerIds
        .where((id) => gameState.players.any((p) => p.id == id && !p.isBot))
        .length;
    final allConfirmed =
        requiredConfirmations > 0 && confirmedCount >= requiredConfirmations;

    return CBGlassTile(
      borderColor: scheme.onSurface,
      isPrismatic: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_input_component_rounded,
                  color: scheme.onSurface),
              const SizedBox(width: 10),
              Text('PROTOCOL SETTINGS', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildConfigOption(
                  context, "SYNC", gameState.syncMode.name, scheme.primary, () {
                HapticService.selection();
                final newMode = gameState.syncMode == SyncMode.local
                    ? SyncMode.cloud
                    : SyncMode.local;
                unawaited(_setSyncMode(ref, controller, newMode));
              }),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'GAME STYLE',
            style: CBTypography.labelSmall.copyWith(
              fontSize: 8,
              color: scheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStyleChip(context, GameStyle.offensive, scheme.secondary),
              _buildStyleChip(context, GameStyle.defensive, scheme.secondary),
              _buildStyleChip(context, GameStyle.reactive, scheme.secondary),
              _buildStyleChip(context, GameStyle.manual, scheme.secondary),
            ],
          ),
          if (gameState.gameStyle == GameStyle.manual) ...[
            const SizedBox(height: 12),
            CBPrimaryButton(
              label: 'MANUAL ROLE ASSIGNMENT',
              icon: Icons.tune_rounded,
              backgroundColor: scheme.secondary,
              onPressed: onManualAssign,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified_user_rounded, color: scheme.tertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SETUP CONFIRMATIONS: $confirmedCount/$requiredConfirmations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: allConfirmed ? scheme.tertiary : scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            value: session.forceStartOverride,
            onChanged: sessionController.setForceStartOverride,
            activeTrackColor: scheme.error,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'FORCE START OVERRIDE',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            subtitle: Text(
              'Allow setup to advance without all confirmations.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(BuildContext context, GameStyle style, Color color) {
    final selected = gameState.gameStyle == style;
    return CBFilterChip(
      label: style.label,
      selected: selected,
      color: color,
      onSelected: () {
        HapticService.selection();
        controller.setGameStyle(style);
      },
    );
  }

  Future<void> _setSyncMode(
    WidgetRef ref,
    Game controller,
    SyncMode newMode,
  ) async {
    controller.setSyncMode(newMode);
    final localBridge = ref.read(hostBridgeProvider);
    final cloudBridge = ref.read(cloudHostBridgeProvider);

    await syncHostBridgesForMode(
      mode: newMode,
      stopLocal: localBridge.stop,
      startLocal: localBridge.start,
      stopCloud: cloudBridge.stop,
      startCloud: cloudBridge.start,
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
