import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoteTallyPanel extends ConsumerWidget {
  final List<Player> players;
  final Map<String, int> tally;
  final Map<String, String> votesByVoter;

  const VoteTallyPanel({
    super.key,
    required this.players,
    required this.tally,
    this.votesByVoter = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final sorted = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Check if we are in a day vote step to show the override button
    final gameState = ref.watch(gameProvider);
    final currentStepId = gameState.currentStep?.id;
    final isDayVote =
        currentStepId != null && StepKey.isDayVoteStep(currentStepId);

    if (tally.isEmpty && !isDayVote) {
      return const SizedBox.shrink();
    }

    return CBFadeSlide(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: CBSpace.x2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(CBRadius.md),
          border: Border.all(
            color: scheme.secondary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: scheme.secondary.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: -2)],
        ),
        padding: const EdgeInsets.all(CBSpace.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.how_to_vote_rounded,
                  color: scheme.secondary,
                  shadows: CBColors.iconGlow(scheme.secondary, intensity: 0.5),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Text(
                    'VOTE TALLY',
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.secondary,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w900,
                      shadows: CBColors.textGlow(scheme.secondary, intensity: 0.4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CBSpace.x4),
            if (sorted.isEmpty)
              Center(
                child: Text(
                  'NO VOTES CAST YET',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                separatorBuilder: (context, index) => Divider(
                  color: scheme.outlineVariant.withValues(alpha: 0.1),
                  height: CBSpace.x4,
                ),
                itemBuilder: (context, index) {
                  final entry = sorted[index];
                  final targetId = entry.key;
                  final targetName = _nameForId(targetId);
                  final voterText = _voterNamesFor(targetId);
                  final targetPlayer = players
                      .cast<Player?>()
                      .firstWhere((p) => p?.id == targetId, orElse: () => null);

                  // Use a default color for non-players (e.g. Abstain)
                  final roleColor = targetPlayer != null
                      ? CBColors.fromHex(targetPlayer.role.colorHex)
                      : scheme.secondary;

                  return Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.5),
                              width: 1.5),
                          boxShadow: [BoxShadow(color: roleColor.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -2)],
                        ),
                        child: Center(
                          child: Text(
                            '${entry.value}',
                            style: textTheme.titleMedium?.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'RobotoMono',
                              shadows: CBColors.textGlow(roleColor, intensity: 0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetName.toUpperCase(),
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: scheme.onSurface,
                                shadows: CBColors.textGlow(scheme.onSurface, intensity: 0.2),
                              ),
                            ),
                            if (voterText.isNotEmpty)
                              Text(
                                voterText.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (targetPlayer != null)
                        CBMiniTag(
                          text: targetPlayer.role.name.toUpperCase(),
                          color: roleColor,
                        ),
                    ],
                  );
                },
              ),

            // HOST OVERRIDE BUTTON
            if (isDayVote) ...[
              const SizedBox(height: 24),
              CBGhostButton(
                label: 'HOST VOTE OVERRIDE',
                fullWidth: true,
                icon: Icons.gavel_rounded,
                color: scheme.secondary,
                onPressed: () {
                    HapticService.selection();
                    _showVoteOverrideSheet(context, ref, currentStepId, gameState);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVoteOverrideSheet(
      BuildContext context, WidgetRef ref, String stepId, GameState gameState) {
    // Only alive players can vote
    final alivePlayers = players.where((p) => p.isAlive).toList();
    if (alivePlayers.isEmpty) return;

    final controller = ref.read(gameProvider.notifier);

    showThemedDialog(
      context: context,
      child: HostVoteOverrideDialog(
        players: players,
        gameState: gameState,
        controller: controller,
        onDismiss: () => Navigator.pop(context),
        stepId: stepId,
      ),
    );
  }

  String _voterNamesFor(String targetId) {
    final voterNames = votesByVoter.entries
        .where((e) => e.value == targetId)
        .map((e) => _nameForId(e.key))
        .toList();
    if (voterNames.isEmpty) return '';
    return 'BY ${voterNames.join(", ")}';
  }

  String _nameForId(String playerId) {
    if (playerId == 'abstain') return 'ABSTAIN';
    for (final player in players) {
      if (player.id == playerId) return player.name;
    }
    return 'UNKNOWN';
  }
}

class HostVoteOverrideDialog extends ConsumerStatefulWidget {
  final List<Player> players;
  final GameState gameState;
  final Game controller;
  final void Function() onDismiss;
  final String stepId;

  const HostVoteOverrideDialog({
    super.key,
    required this.players,
    required this.gameState,
    required this.controller,
    required this.onDismiss,
    required this.stepId,
  });

  @override
  ConsumerState<HostVoteOverrideDialog> createState() =>
      _HostVoteOverrideDialogState();
}

class _HostVoteOverrideDialogState
    extends ConsumerState<HostVoteOverrideDialog> {
  String? _selectedTargetId;
  late List<Player> potentialTargets;

  @override
  void initState() {
    super.initState();
    potentialTargets = widget.players.where((p) => p.isAlive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(CBSpace.x4),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(CBRadius.lg),
          border: Border.all(color: scheme.secondary.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [BoxShadow(color: scheme.secondary.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(CBSpace.x6),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(CBRadius.lg)),
                border: Border(bottom: BorderSide(color: scheme.secondary.withValues(alpha: 0.2))),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    color: scheme.secondary,
                    size: 36,
                    shadows: CBColors.iconGlow(scheme.secondary, intensity: 0.5),
                  ),
                  const SizedBox(height: CBSpace.x3),
                  Text(
                    'HOST VOTE OVERRIDE',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: CBColors.textGlow(scheme.secondary, intensity: 0.5),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CBSpace.x2),
                  Text(
                    'FORCE A VOTE OUTCOME OR CLEAR AN EXISTING ENTRY.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(CBSpace.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'TARGET SELECTION',
                    style: TextStyle(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: CBSpace.x2),
                  _buildVotingSelectionGrid(context, scheme),
                  const SizedBox(height: CBSpace.x6),
                  CBPrimaryButton(
                    label: 'SUBMIT OVERRIDE',
                    icon: Icons.done_all_rounded,
                    backgroundColor: scheme.secondary,
                    onPressed: () {
                      HapticService.heavy();
                      _applyVoteOverride();
                    },
                    fullWidth: true,
                  ),
                  const SizedBox(height: CBSpace.x3),
                  CBGhostButton(
                    label: 'ABORT',
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    onPressed: () {
                      HapticService.light();
                      widget.onDismiss();
                    },
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyVoteOverride() {
    final selectedId = _selectedTargetId;
    widget.controller.handleInteraction(
      stepId: widget.stepId,
      targetId: (selectedId == null || selectedId.isEmpty) ? null : selectedId,
    );

    widget.onDismiss();
  }

  Widget _buildVotingSelectionGrid(BuildContext context, ColorScheme scheme) {
    if (potentialTargets.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CBRadius.md),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CBSpace.x3),
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            spacing: CBSpace.x2,
            runSpacing: CBSpace.x2,
            alignment: WrapAlignment.center,
            children: [
              CBCompactPlayerChip(
                name: '(CLEAR VOTE)',
                color: scheme.onSurface.withValues(alpha: 0.5),
                isSelected: _selectedTargetId == '',
                onTap: () {
                  HapticService.selection();
                  setState(() => _selectedTargetId = '');
                },
              ),
              CBCompactPlayerChip(
                name: 'ABSTAIN',
                color: scheme.tertiary,
                isSelected: _selectedTargetId == 'abstain',
                onTap: () {
                  HapticService.selection();
                  setState(() => _selectedTargetId = 'abstain');
                },
              ),
              ...potentialTargets.map((p) {
                final isSelected = _selectedTargetId == p.id;
                final roleColor = CBColors.fromHex(p.role.colorHex);

                // Compute dynamic status chips
                final statuses = <String>[...p.statusEffects];
                
                if (widget.gameState.players.any((other) => other.clingerPartnerId == p.id)) {
                  if (!statuses.any((s) => s.toUpperCase() == 'OBSESSION')) statuses.add('OBSESSION');
                }
                
                if (widget.gameState.players.any((other) => 
                    other.creepTargetId == p.id || 
                    other.teaSpillerTargetId == p.id || 
                    other.predatorTargetId == p.id ||
                    other.dramaQueenTargetAId == p.id ||
                    other.dramaQueenTargetBId == p.id)) {
                  if (!statuses.any((s) => s.toUpperCase() == 'TARGET')) statuses.add('TARGET');
                }
                
                if (p.hasHostShield || widget.gameState.players.any((other) => other.medicProtectedPlayerId == p.id)) {
                  if (!statuses.any((s) => s.toUpperCase() == 'PROTECTED')) statuses.add('PROTECTED');
                }
                
                if (p.hasReviveToken) {
                  if (!statuses.any((s) => s.toUpperCase() == 'SAVED')) statuses.add('SAVED');
                }

                return CBCompactPlayerChip(
                  name: p.name,
                  assetPath: p.role.assetPath,
                  color: roleColor,
                  isSelected: isSelected,
                  statusEffects: statuses.take(3).toList(),
                  onTap: () {
                    HapticService.selection();
                    setState(() => _selectedTargetId = p.id);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

