import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// A specialized view for eliminated players.
/// Features spectator info, "Dead Pool" betting, and ghost aesthetics.
class CBGhostLoungeView extends StatelessWidget {
  final List<({String name, String role, Color color, bool isAlive})>
      playerRoster;
  final String? lastWords;
  final String? currentBetTargetName;
  final List<String> bettingHistory;
  final List<String> ghostMessages;
  final VoidCallback? onPlaceBet;
  final ValueChanged<String>? onSendGhostMessage;

  const CBGhostLoungeView({
    super.key,
    required this.playerRoster,
    this.lastWords,
    this.currentBetTargetName,
    this.bettingHistory = const [],
    this.ghostMessages = const [],
    this.onPlaceBet,
    this.onSendGhostMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildGhostHeader(context),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (lastWords != null) _buildLastWordsCard(context),
              const SizedBox(height: 24),

              // Spectator Intel
              CBSectionHeader(
                  title: "SPECTATOR INTEL",
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              ...playerRoster.map((p) => _buildGhostRosterTile(p, context)),

              const SizedBox(height: 32),

              // Dead Pool
              _buildDeadPoolCard(context),

              const SizedBox(height: 24),

              _buildBettingHistoryCard(context),

              const SizedBox(height: 24),

              _buildGhostChatCard(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGhostHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: scheme.secondary, width: 0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.visibility_rounded,
              color: scheme.secondary.withValues(alpha: 0.8), size: 48),
          const SizedBox(height: 12),
          Text("THE GHOST LOUNGE",
              style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: scheme.onSurface,
                  shadows: CBColors.textGlow(scheme.secondary))),
          const SizedBox(height: 4),
          Text("YOU ARE DEAD. ENJOY THE SHOW.",
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.3),
                    letterSpacing: 2,
                  )),
        ],
      ),
    );
  }

  Widget _buildLastWordsCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CBGlassTile(
      title: "YOUR LAST WORDS",
      accentColor: CBColors.dead,
      content: Text(
        "\"$lastWords\"",
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontStyle: FontStyle.italic,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }

  Widget _buildGhostRosterTile(
      ({String name, String role, Color color, bool isAlive}) p,
      BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CBRoleAvatar(color: p.isAlive ? p.color : CBColors.dead, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.bold,
                        )),
                Text(p.role.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: p.color.withValues(alpha: 0.5), fontSize: 9)),
              ],
            ),
          ),
          if (p.isAlive)
            const Icon(Icons.favorite, color: CBColors.matrixGreen, size: 14)
          else
            const Icon(Icons.close, color: CBColors.dead, size: 14),
        ],
      ),
    );
  }

  Widget _buildDeadPoolCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: scheme.secondary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.casino_outlined, color: scheme.secondary, size: 32),
          const SizedBox(height: 16),
          Text("THE DEAD POOL",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(color: scheme.secondary)),
          const SizedBox(height: 8),
          Text("Place a bet on the next player to be exiled.",
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: scheme.onSurface.withValues(alpha: 0.55))),
          const SizedBox(height: 10),
          Text(
            currentBetTargetName == null
                ? 'No active bet placed.'
                : 'Current Bet: $currentBetTargetName',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          CBPrimaryButton(
            label: "PLACE YOUR BET",
            onPressed: onPlaceBet,
          ),
        ],
      ),
    );
  }

  Widget _buildBettingHistoryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CBGlassTile(
      title: 'BETTING HISTORY',
      accentColor: scheme.tertiary,
      content: bettingHistory.isEmpty
          ? Text(
              'No resolved bets yet this session.',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bettingHistory.reversed
                  .take(8)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $entry',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildGhostChatCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CBGlassTile(
      title: 'GHOST CHAT',
      accentColor: scheme.secondary,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ghostMessages.isEmpty)
            Text(
              'No ghost messages yet.',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
            )
          else
            ...ghostMessages.reversed.take(12).map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $line',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: CBPrimaryButton(
              label: 'SEND GHOST MSG',
              onPressed: onSendGhostMessage == null
                  ? null
                  : () {
                      final controller = TextEditingController();
                      showThemedDialog<void>(
                        context: context,
                        accentColor: scheme.secondary,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send Ghost Message',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: controller,
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Speak from beyond…',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CBGhostButton(
                                  label: 'CANCEL',
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 8),
                                CBPrimaryButton(
                                  label: 'SEND',
                                  onPressed: () {
                                    final text = controller.text.trim();
                                    if (text.isEmpty) {
                                      return;
                                    }
                                    onSendGhostMessage!(text);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          ],
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
