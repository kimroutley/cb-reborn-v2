import 'package:flutter/material.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cloud_host_bridge.dart';

class GodModePanel extends ConsumerWidget {
  final GameState gameState;
  final Game controller;

  const GodModePanel(
      {super.key, required this.gameState, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final hostBridge = ref.read(cloudHostBridgeProvider);

    return ListView(
      padding: CBInsets.screen,
      children: [
        _buildDirectorCommands(context, hostBridge),
        const SizedBox(height: CBSpace.x6),
        Padding(
          padding: const EdgeInsets.only(left: CBSpace.x1, bottom: CBSpace.x3),
          child: Text("PLAYER MANIPULATION",
              style: CBTypography.micro.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.45),
                letterSpacing: 2,
              )),
        ),
        ...gameState.players.map((p) => _buildPlayerTacticalCard(context, p)),
      ],
    );
  }

  Widget _buildDirectorCommands(
      BuildContext context, CloudHostBridge hostBridge) {
    final scheme = Theme.of(context).colorScheme;
    return CBPanel(
      borderColor: scheme.secondary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: "DIRECTOR COMMANDS",
            icon: Icons.flash_on,
            color: scheme.secondary,
          ),
          const SizedBox(height: CBSpace.x4),
          Wrap(
            spacing: CBSpace.x3,
            runSpacing: CBSpace.x3,
            children: [
              _buildCmdButton(context, "NEON FLICKER", Icons.lightbulb_outline,
                  () {
                controller.sendDirectorCommand('flicker');
              }),
              _buildCmdButton(context, "SYSTEM GLITCH", Icons.settings_ethernet,
                  () {
                controller.sendDirectorCommand('glitch');
              }),
              _buildCmdButton(context, "RANDOM RUMOUR", Icons.record_voice_over,
                  () {
                // Logic for injecting random rumour - already implemented in DashboardView
              }),
              _buildCmdButton(context, "VOICE OF GOD", Icons.volume_up, () {
                _showVoiceOfGodDialog(context, hostBridge);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCmdButton(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(CBRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: CBSpace.x4, vertical: CBSpace.x3),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CBRadius.sm),
          border: Border.all(color: scheme.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.secondary),
            const SizedBox(width: CBSpace.x2),
            Text(
              label,
              style: CBTypography.micro.copyWith(color: scheme.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTacticalCard(BuildContext context, Player player) {
    final scheme = Theme.of(context).colorScheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: CBSpace.x3),
      child: CBPanel(
        borderColor:
            (player.isAlive ? roleColor : scheme.error).withValues(alpha: 0.4),
        child: InkWell(
          onTap: () => _showTacticalMenu(context, player),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                color:
                                    player.isAlive ? roleColor : scheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          player.role.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                color:
                                    (player.isAlive ? roleColor : scheme.error)
                                        .withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!player.isAlive)
                    CBBadge(text: "DEAD", color: scheme.error),
                  if (player.isSinBinned)
                    Padding(
                      padding: const EdgeInsets.only(left: CBSpace.x2),
                      child:
                          CBBadge(text: "SIN BINNED", color: scheme.secondary),
                    ),
                  if (player.isShadowBanned)
                    Padding(
                      padding: const EdgeInsets.only(left: CBSpace.x2),
                      child: CBBadge(
                          text: "SHADOW BANNED", color: scheme.tertiary),
                    ),
                  if (player.isMuted)
                    Padding(
                      padding: const EdgeInsets.only(left: CBSpace.x2),
                      child: CBBadge(text: "MUTED", color: scheme.primary),
                    ),
                  const Spacer(),
                  Text("TAP FOR TACTICAL MENU",
                      style: CBTypography.nano.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTacticalMenu(BuildContext context, Player player) {
    final textTheme = Theme.of(context).textTheme;
    final roleColor = CBColors.fromHex(player.role.colorHex);

    showThemedBottomSheetBuilder<void>(
      context: context,
      accentColor: roleColor,
      padding: EdgeInsets.zero,
      wrapInScrollView: false,
      addHandle: false,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: CBInsets.screenH,
              children: [
                const CBBottomSheetHandle(
                  margin: EdgeInsets.only(top: CBSpace.x3, bottom: CBSpace.x3),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: CBSpace.x2),
                  child: Text(
                    'TACTICAL OVERRIDE: ${player.name.toUpperCase()}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: roleColor,
                      letterSpacing: 1.2,
                      shadows: CBColors.textGlow(roleColor, intensity: 0.55),
                    ),
                  ),
                ),
                const SizedBox(height: CBSpace.x4),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: CBSpace.x3,
                  crossAxisSpacing: CBSpace.x3,
                  childAspectRatio: 2.5,
                  children: [
                    _buildMenuAction(
                      context,
                      player.isAlive ? "KILL" : "REVIVE",
                      player.isAlive ? Icons.close : Icons.favorite,
                      player.isAlive
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.tertiary,
                      () {
                        if (player.isAlive) {
                          controller.forceKillPlayer(player.id);
                        } else {
                          controller.revivePlayer(player.id);
                        }
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuAction(
                      context,
                      player.isSinBinned ? "RELEASE" : "SIN BIN",
                      Icons.timer_off,
                      CBColors.alertOrange,
                      () {
                        controller.setSinBin(player.id, !player.isSinBinned);
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuAction(
                      context,
                      player.isMuted ? "UNMUTE" : "MUTE",
                      Icons.mic_off,
                      CBColors.neonBlue,
                      () {
                        controller.togglePlayerMute(player.id, !player.isMuted);
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuAction(
                      context,
                      player.isShadowBanned ? "UNBAN" : "SHADOW BAN",
                      Icons.visibility_off,
                      CBColors.yellow,
                      () {
                        controller.setShadowBan(
                            player.id, !player.isShadowBanned);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: CBSpace.x5),
                CBGhostButton(
                  label: "REMOVE FROM CLUB",
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () {
                    controller.kickPlayer(player.id, "Admin removal");
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: CBSpace.x4),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMenuAction(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CBRadius.md),
      child: Container(
        padding: const EdgeInsets.all(CBSpace.x3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CBRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: CBSpace.x3),
            Text(label,
                style: textTheme.labelSmall!
                    .copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showVoiceOfGodDialog(BuildContext context, CloudHostBridge hostBridge) {
    String message = '';
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOICE OF GOD',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          CBTextField(
            decoration: const InputDecoration(
              labelText: 'Announcement',
              hintText: 'Your message to all players...',
            ),
            maxLines: 3,
            onChanged: (value) => message = value,
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
                label: 'SEND',
                onPressed: () {
                  if (message.isNotEmpty) {
                    controller.sendDirectorCommand('toast:');
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
