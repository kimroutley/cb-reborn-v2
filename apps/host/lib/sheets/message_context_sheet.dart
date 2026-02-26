import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

void showMessageContextActions(
  BuildContext context, {
  required String playerName,
  required String message,
  VoidCallback? onSinBin,
  VoidCallback? onMute,
  VoidCallback? onViewRole,
}) {
  final scheme = Theme.of(context).colorScheme;

  showThemedBottomSheetBuilder<void>(
    context: context,
    accentColor: scheme.primary,
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CBBottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CBSectionHeader(
                  title: playerName.toUpperCase(),
                  icon: Icons.person_outline_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                CBGlassTile(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.security_rounded, color: scheme.error),
            title: Text('SEND TO SIN BIN', style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(ctx);
              onSinBin?.call();
            },
          ),
          ListTile(
            leading: Icon(Icons.volume_off_rounded, color: scheme.secondary),
            title: const Text('MUTE PLAYER'),
            onTap: () {
              Navigator.pop(ctx);
              onMute?.call();
            },
          ),
          ListTile(
            leading: Icon(Icons.visibility_rounded, color: scheme.tertiary),
            title: const Text('VIEW ROLE DETAILS'),
            onTap: () {
              Navigator.pop(ctx);
              onViewRole?.call();
            },
          ),
          const SizedBox(height: 24),
        ],
      );
    },
  );
}
