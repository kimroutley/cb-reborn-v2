import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualRoleAssignmentSheet extends ConsumerWidget {
  const ManualRoleAssignmentSheet({super.key});

  Color _parseRoleColor(String hex) {
    try {
      if (hex.startsWith('#')) {
        return Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
      }
      return Colors.grey;
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final assignableRoles =
        roleCatalog.where((role) => role.id != 'unassigned').toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'MANUAL ROLE ASSIGNMENT',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'Drag a role chip onto a player card, or use quick-select.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: assignableRoles.map((role) {
            final roleColor = _parseRoleColor(role.colorHex);
            return Draggable<String>(
              data: role.id,
              feedback: Material(
                color: Colors.transparent,
                child: Chip(
                  label: Text(role.name),
                  backgroundColor: roleColor,
                  labelStyle:
                      textTheme.labelLarge?.copyWith(color: Colors.black),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: Chip(label: Text(role.name)),
              ),
              child: Chip(
                label: Text(role.name),
                avatar: const Icon(Icons.drag_indicator, size: 16),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: currentState.players.map((player) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DragTarget<String>(
                    onWillAcceptWithDetails: (details) =>
                        details.data.isNotEmpty,
                    onAcceptWithDetails: (details) {
                      controller.assignRole(player.id, details.data);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isHovering
                              ? scheme.secondary.withValues(alpha: 0.18)
                              : scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isHovering
                                ? scheme.secondary
                                : scheme.outline.withValues(alpha: 0.45),
                            width: isHovering ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.name,
                                    style: textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    player.role.id == 'unassigned'
                                        ? 'Unassigned'
                                        : player.role.name,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: player.role.id == 'unassigned'
                                          ? scheme.onSurfaceVariant
                                          : scheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownButton<String>(
                              value: player.role.id == 'unassigned'
                                  ? null
                                  : player.role.id,
                              hint: const Text('Select'),
                              items: roleCatalog.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role.id,
                                  child: Text(role.name),
                                );
                              }).toList(),
                              onChanged: (roleId) {
                                if (roleId == null) return;
                                controller.assignRole(player.id, roleId);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        CBPrimaryButton(
          label: 'DONE',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
