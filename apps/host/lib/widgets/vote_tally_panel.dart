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
      child: CBPanel(
        margin: const EdgeInsets.symmetric(vertical: CBSpace.x2),
        padding: const EdgeInsets.all(CBSpace.x5),
        borderColor: scheme.secondary.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CBSectionHeader(
              title: 'VOTE TALLY',
              icon: Icons.how_to_vote_rounded,
              color: scheme.secondary,
            ),
            const SizedBox(height: CBSpace.x4),
            if (sorted.isEmpty)
              Center(
                child: Text(
                  'NO VOTES CAST YET',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: roleColor.withValues(alpha: 0.3),
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.value}',
                            style: textTheme.labelLarge?.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'RobotoMono',
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
                                letterSpacing: 1.0,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (voterText.isNotEmpty)
                              Text(
                                voterText.toUpperCase(),
                                style: textTheme.labelSmall?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.4),
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
                onPressed: () =>
                    _showVoteOverrideSheet(context, ref, currentStepId),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVoteOverrideSheet(
      BuildContext context, WidgetRef ref, String stepId) {
    // Only alive players can vote
    final alivePlayers = players.where((p) => p.isAlive).toList();
    if (alivePlayers.isEmpty) return;

    final controller = ref.read(gameProvider.notifier);

    showThemedDialog(
      context: context,
      child: HostVoteOverrideDialog(
        players: players,
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
  final Game controller;
  final void Function() onDismiss;
  final String stepId;

  const HostVoteOverrideDialog({
    super.key,
    required this.players,
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

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(CBSpace.x5),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    color: scheme.onPrimary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'HOST VOTE OVERRIDE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a player to override their vote, or choose "Clear Vote" to remove a vote.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(CBSpace.x4),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Target'),
                    initialValue: _selectedTargetId,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('(Clear Vote)'),
                      ),
                      const DropdownMenuItem(
                        value: 'abstain',
                        child: Text('Abstain'),
                      ),
                      ...potentialTargets.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      )),
                     ],
                    onChanged: (val) => setState(() => _selectedTargetId = val),
                  ),
                  const SizedBox(height: 16),
                  CBGhostButton(
                    label: 'SUBMIT OVERRIDE',
                    icon: Icons.save_rounded,
                    onPressed: _applyVoteOverride,
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
}
