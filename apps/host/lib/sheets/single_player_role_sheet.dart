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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(gameProvider.notifier);

    // Filter out unassigned from the catalog for the grid
    final roles = roleCatalog.where((r) => r.id != 'unassigned').toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CBSpace.x6, vertical: CBSpace.x4),
          child: Row(
            children: [
              Icon(Icons.assignment_ind_rounded, color: scheme.primary, size: 24),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASSIGN ROLE',
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Text(
                      playerName.toUpperCase(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(CBSpace.x4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: CBSpace.x3,
              crossAxisSpacing: CBSpace.x3,
              childAspectRatio: 0.85,
            ),
            itemCount: roles.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Unassigned option
                return _RoleGridTile(
                  name: 'NONE',
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  icon: Icons.block_rounded,
                  onTap: () {
                    controller.assignRole(playerId, 'unassigned');
                    Navigator.pop(context);
                  },
                );
              }

              final role = roles[index - 1];
              return _RoleGridTile(
                name: role.name,
                color: CBColors.fromHex(role.colorHex),
                assetPath: role.assetPath,
                onTap: () {
                  controller.assignRole(playerId, role.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        const SizedBox(height: CBSpace.x6),
      ],
    );
  }
}

class _RoleGridTile extends StatelessWidget {
  final String name;
  final Color color;
  final String? assetPath;
  final IconData? icon;
  final VoidCallback onTap;

  const _RoleGridTile({
    required this.name,
    required this.color,
    this.assetPath,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(CBRadius.md),
      child: CBGlassTile(
        padding: const EdgeInsets.all(CBSpace.x2),
        borderColor: color.withValues(alpha: 0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (assetPath != null)
              CBRoleAvatar(
                assetPath: assetPath!,
                color: color,
                size: 40,
              )
            else
              Icon(icon, color: color, size: 32),
            const SizedBox(height: CBSpace.x2),
            Text(
              name.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 8,
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
