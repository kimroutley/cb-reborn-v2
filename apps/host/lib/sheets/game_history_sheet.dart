import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

void showGameHistory(BuildContext context, GameState gameState) {
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
      final history = gameState.gameHistory;
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
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
                child: CBSectionHeader(title: 'Game History'),
              ),
              if (history.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No events yet.', style: textTheme.bodySmall!),
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
                              ? CBTypography.micro.copyWith(
                                  color: scheme.primary,
                                )
                              : CBTypography.monoSmall.copyWith(
                                  color: CBColors.matrixGreen.withValues(
                                    alpha: 0.85,
                                  ),
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
