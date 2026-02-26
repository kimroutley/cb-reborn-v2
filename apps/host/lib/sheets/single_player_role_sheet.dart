import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SinglePlayerRoleSheet extends ConsumerWidget {
  final String playerId;
  final String playerName;

  const SinglePlayerRoleSheet({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameProvider.notifier);
    final currentPlayer = ref.watch(gameProvider).players.firstWhere(
          (p) => p.id == playerId,
        );
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final assignableRoles =
        roleCatalog.where((role) => role.id != 'unassigned').toList();
    final hasRole = currentPlayer.role.id != 'unassigned';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CBBottomSheetHandle(),
          const SizedBox(height: 16),
          Text(
            'ASSIGN ROLE',
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              shadows: CBColors.textGlow(scheme.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playerName.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          if (hasRole)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CBGhostButton(
                label: 'CLEAR ROLE',
                icon: Icons.clear_rounded,
                onPressed: () {
                  HapticService.medium();
                  controller.assignRole(playerId, 'unassigned');
                  Navigator.pop(context);
                },
              ),
            ),

          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: assignableRoles.length,
              itemBuilder: (context, index) {
                final role = assignableRoles[index];
                final roleColor = CBColors.fromHex(role.colorHex);
                final isCurrentRole = currentPlayer.role.id == role.id;

                return GestureDetector(
                  onTap: () {
                    HapticService.medium();
                    controller.assignRole(playerId, role.id);
                    Navigator.pop(context);
                  },
                  child: CBGlassTile(
                    isPrismatic: isCurrentRole,
                    isSelected: isCurrentRole,
                    borderColor: isCurrentRole
                        ? roleColor
                        : roleColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CBRoleAvatar(
                          assetPath: role.assetPath,
                          color: roleColor,
                          size: 32,
                          pulsing: isCurrentRole,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          role.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: isCurrentRole
                                ? roleColor
                                : scheme.onSurface,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: isCurrentRole
                                ? CBColors.textGlow(roleColor, intensity: 0.3)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CBMiniTag(
                          text: role.alliance == Team.clubStaff
                              ? 'STAFF'
                              : role.alliance == Team.partyAnimals
                                  ? 'PARTY'
                                  : 'WILD',
                          color: roleColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
