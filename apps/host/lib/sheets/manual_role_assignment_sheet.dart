import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualRoleAssignmentSheet extends ConsumerWidget {
  const ManualRoleAssignmentSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final assignableRoles = roleCatalog
        .where((role) => role.id != 'unassigned')
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CBBottomSheetHandle(),
          const SizedBox(height: 16),
          Text(
            'ROLE ASSIGNMENT MATRIX',
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              shadows: CBColors.textGlow(scheme.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'DRAG A ROLE CHIP ONTO A PATRON TO MANUALLY ASSIGN THEIR IDENTITY.',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),

          // --- ROLE CHIPS (Draggable) ---
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: assignableRoles.length,
              itemBuilder: (context, index) {
                final role = assignableRoles[index];
                final roleColor = CBColors.fromHex(role.colorHex);

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Draggable<String>(
                    data: role.id,
                    feedback: Material(
                      type: MaterialType.transparency,
                      child: _buildRoleSourceChip(
                        role,
                        roleColor,
                        context,
                        isDragging: true,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildRoleSourceChip(role, roleColor, context),
                    ),
                    child: _buildRoleSourceChip(role, roleColor, context),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // --- PLAYER LIST (Targets) ---
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currentState.players.length,
              itemBuilder: (context, index) {
                final player = currentState.players[index];
                final hasRole = player.role.id != 'unassigned';
                final roleColor = hasRole
                    ? CBColors.fromHex(player.role.colorHex)
                    : scheme.outlineVariant;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (details) =>
                        details.data != player.role.id,
                    onAcceptWithDetails: (details) {
                      HapticService.medium();
                      controller.assignRole(player.id, details.data);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;

                      return CBGlassTile(
                        isPrismatic: isHovering || hasRole,
                        borderColor: isHovering
                            ? scheme.secondary
                            : (hasRole
                                  ? roleColor
                                  : scheme.outline.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CBRoleAvatar(
                              assetPath: hasRole ? player.role.assetPath : null,
                              color: roleColor,
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name.toUpperCase(),
                                    style: textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    hasRole
                                        ? player.role.name.toUpperCase()
                                        : 'PENDING ASSIGNMENT',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: hasRole
                                          ? roleColor
                                          : scheme.onSurface.withValues(
                                              alpha: 0.5,
                                            ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasRole)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: scheme.onSurface.withValues(alpha: 0.3),
                                onPressed: () => controller.assignRole(
                                  player.id,
                                  'unassigned',
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          CBPrimaryButton(
            label: 'FINALIZE ROSTER',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSourceChip(
    Role role,
    Color color,
    BuildContext context, {
    bool isDragging = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return CBGlassTile(
      isPrismatic: true,
      borderColor: color.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.badge_rounded,
              color: color,
              size: 24,
              shadows: CBColors.iconGlow(color, intensity: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              role.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                shadows: CBColors.textGlow(color, intensity: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
