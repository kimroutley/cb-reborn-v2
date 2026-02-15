import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GodModeControls extends ConsumerWidget {
  final GameState gameState;

  const GodModeControls({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alivePlayers =
        gameState.players.where((p) => p.isAlive).toList();

    return CBPanel(
      borderColor: CBColors.radiantPink.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'God Mode Controls',
            color: CBColors.radiantPink,
            icon: Icons.flash_on,
          ),
          const SizedBox(height: 8),
          Text(
            'Powerful host tools. Use responsibly.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: CBColors.matrixGreen,
                ),
          ),
          const SizedBox(height: 16),
          ...alivePlayers.map((player) => _buildPlayerControlTile(context, ref, player)),
        ],
      ),
    );
  }

  Widget _buildPlayerControlTile(BuildContext context, WidgetRef ref, Player player) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      leading: CBRoleAvatar(
        assetPath: player.role.assetPath,
        color: CBColors.fromHex(player.role.colorHex),
        size: 32,
      ),
      title: Text(
        player.name,
        style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        player.role.name,
        style: textTheme.bodySmall!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CBGhostButton(
                label: 'KILL',
                color: CBColors.dead,
                onPressed: () => _confirmKill(context, ref, player),
              ),
              CBGhostButton(
                label: player.isMuted ? 'UNMUTE' : 'MUTE',
                color: CBColors.alertOrange,
                onPressed: () => _toggleMute(context, ref, player),
              ),
              CBGhostButton(
                label: player.hasHostShield ? 'REMOVE SHIELD' : 'GRANT SHIELD',
                color: CBColors.electricCyan,
                onPressed: () => _grantShield(context, ref, player),
              ),
              CBGhostButton(
                label: player.isSinBinned ? 'RELEASE' : 'SIN BIN',
                color: CBColors.darkMetal,
                onPressed: () => _toggleSinBin(context, ref, player),
              ),
              CBGhostButton(
                label: player.isShadowBanned ? 'UNBAN' : 'SHADOW BAN',
                color: CBColors.alertOrange,
                onPressed: () => _toggleShadowBan(context, ref, player),
              ),
              CBGhostButton(
                label: 'KICK',
                color: CBColors.dead,
                onPressed: () => _kickPlayer(context, ref, player),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmKill(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONFIRM KILL',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows:
                      CBColors.textGlow(scheme.error, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Force eliminate ${player.name}? This will trigger death effects.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.75),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'KILL',
                backgroundColor: scheme.error,
                onPressed: () {
                  ref.read(gameProvider.notifier).forceKillPlayer(player.id);
                  Navigator.pop(context);
                  showThemedSnackBar(context, '${player.name} eliminated');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _toggleMute(BuildContext context, WidgetRef ref, Player player) {
    ref
        .read(gameProvider.notifier)
        .togglePlayerMute(player.id, !player.isMuted);
    showThemedSnackBar(
        context, '${player.name} ${player.isMuted ? 'unmuted' : 'muted'}');
  }

  void _grantShield(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    // Grant or update shield
    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GRANT SHIELD',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows:
                      CBColors.textGlow(scheme.primary, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Grant temporary immunity to ${player.name}.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<int>(
            initialSelection: 1,
            label: const Text('Duration (days)'),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 1, label: '1 day'),
              DropdownMenuEntry(value: 2, label: '2 days'),
              DropdownMenuEntry(value: 3, label: '3 days'),
            ],
            onSelected: (days) {
              if (days == null) return;
              Navigator.pop(context);
              ref.read(gameProvider.notifier).grantHostShield(player.id, days);
              showThemedSnackBar(
                context,
                'Shield granted to ${player.name} ($days days)',
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _toggleSinBin(BuildContext context, WidgetRef ref, Player player) {
    ref.read(gameProvider.notifier).setSinBin(player.id, !player.isSinBinned);
    showThemedSnackBar(context,
        '${player.name} ${player.isSinBinned ? 'released from' : 'sent to'} sin bin');
  }

  void _toggleShadowBan(BuildContext context, WidgetRef ref, Player player) {
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.tertiary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.isShadowBanned ? 'CONFIRM UNBAN' : 'CONFIRM SHADOW BAN',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            player.isShadowBanned
                ? 'Remove shadow ban from ${player.name}?'
                : 'Shadow ban ${player.name}? Their actions will be silently discarded without their knowledge.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.75),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: player.isShadowBanned ? 'UNBAN' : 'SHADOW BAN',
                backgroundColor: scheme.tertiary,
                onPressed: () {
                  ref
                      .read(gameProvider.notifier)
                      .setShadowBan(player.id, !player.isShadowBanned);
                  Navigator.pop(context);
                  showThemedSnackBar(context,
                      '${player.name} ${player.isShadowBanned ? 'unbanned' : 'shadow banned'}');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _kickPlayer(BuildContext context, WidgetRef ref, Player player) {
    String reason = '';
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KICK PLAYER',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.5),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Permanently remove ${player.name} from the game?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.75),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 16),
          CBTextField(
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
            ),
            onChanged: (value) => reason = value,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'KICK',
                backgroundColor: scheme.error,
                onPressed: () {
                  ref.read(gameProvider.notifier).kickPlayer(player.id,
                      reason.isEmpty ? 'No reason provided' : reason);
                  Navigator.pop(context);
                  showThemedSnackBar(
                      context, '${player.name} kicked from game');
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
