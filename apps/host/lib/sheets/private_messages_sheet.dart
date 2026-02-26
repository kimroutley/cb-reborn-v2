import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

void showPrivateMessages(BuildContext context, GameState gameState) {
  final scheme = Theme.of(context).colorScheme;
  showThemedBottomSheetBuilder<void>(
    context: context,
    accentColor: scheme.secondary,
    padding: EdgeInsets.zero,
    wrapInScrollView: false,
    addHandle: false,
    builder: (ctx) {
      final textTheme = Theme.of(ctx).textTheme;
      final scheme = Theme.of(ctx).colorScheme;
      final messages = gameState.privateMessages;

      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          final entries = messages.entries.toList();
          return Column(
            children: [
              const CBBottomSheetHandle(
                margin: EdgeInsets.only(top: CBSpace.x3, bottom: CBSpace.x3),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: CBSpace.x4,
                  vertical: CBSpace.x2,
                ),
                child: CBSectionHeader(title: 'Private Intel'),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: CBInsets.screenH,
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final entry = entries[i];
                    final playerName =
                        gameState.players
                            .where((p) => p.id == entry.key)
                            .map((p) => p.name)
                            .firstOrNull ??
                        entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: CBSpace.x3),
                      child: CBPanel(
                        borderColor: CBColors.alertOrange.withValues(
                          alpha: 0.4,
                        ),
                        padding: const EdgeInsets.all(CBSpace.x3),
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CBBadge(
                              text: playerName.toUpperCase(),
                              color: CBColors.alertOrange,
                            ),
                            const SizedBox(height: CBSpace.x2),
                            for (final line in entry.value)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: CBSpace.x1,
                                ),
                                child: Text(
                                  line,
                                  style: textTheme.bodySmall!.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
