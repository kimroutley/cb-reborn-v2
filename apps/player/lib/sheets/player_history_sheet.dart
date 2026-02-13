import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../player_bridge.dart';

void showPlayerHistory(BuildContext context, PlayerGameState gs) {
  final scheme = Theme.of(context).colorScheme;
  showThemedBottomSheetBuilder<void>(
    context: context,
    accentColor: scheme.primary,
    padding: EdgeInsets.zero,
    wrapInScrollView: false,
    addHandle: false,
    builder: (ctx) {
      final textTheme = Theme.of(ctx).textTheme;
      final scheme = Theme.of(ctx).colorScheme;
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) {
          final history = gs.gameHistory;
          return Column(
            children: [
              const CBBottomSheetHandle(
                margin: EdgeInsets.only(top: CBSpace.x3, bottom: CBSpace.x3),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: CBSpace.x4, vertical: CBSpace.x2),
                child: CBSectionHeader(title: 'Game History'),
              ),
              if (history.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No history yet.',
                      style: textTheme.bodySmall!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: CBInsets.screenH,
                    itemCount: history.length,
                    itemBuilder: (ctx, i) {
                      final line = history[i];
                      final isHeader = line.startsWith('──');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: CBSpace.x1),
                        child: Text(
                          line,
                          style: isHeader
                              ? CBTypography.micro
                                  .copyWith(color: scheme.primary)
                              : CBTypography.monoSmall.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.7),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: CBSpace.x4),
            ],
          );
        },
      );
    },
  );
}
