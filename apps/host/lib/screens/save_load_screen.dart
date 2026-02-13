import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'game_screen.dart';

class SaveLoadScreen extends ConsumerStatefulWidget {
  const SaveLoadScreen({super.key});

  @override
  ConsumerState<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends ConsumerState<SaveLoadScreen> {
  bool _isLoading = true;
  final List<String> _slotIds = PersistenceService.instance.listSaveSlots();
  Map<String, ActiveGameLoadResult> _slotResults = const {};
  Map<String, DateTime?> _slotSavedAts = const {};
  List<GameRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final service = PersistenceService.instance;
    final records = service.loadGameRecords();
    final slotResults = <String, ActiveGameLoadResult>{
      for (final slotId in _slotIds)
        slotId: service.loadGameSlotDetailed(slotId),
    };
    final slotSavedAts = <String, DateTime?>{
      for (final slotId in _slotIds) slotId: service.gameSlotSavedAt(slotId),
    };

    if (!mounted) return;
    setState(() {
      _slotResults = slotResults;
      _slotSavedAts = slotSavedAts;
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _saveCurrentGame(ColorScheme scheme, String slotId) async {
    final saved = ref.read(gameProvider.notifier).manualSave(slotId: slotId);
    final slotLabel = _slotLabel(slotId);
    if (!mounted) return;
    showThemedSnackBar(
      context,
      saved
          ? 'Current game saved to $slotLabel.'
          : 'Unable to save current game to $slotLabel.',
      accentColor: saved ? scheme.tertiary : scheme.error,
    );
    await _refresh();
  }

  Future<void> _loadTestSandbox(ColorScheme scheme) async {
    final loaded = ref.read(gameProvider.notifier).loadTestGameSandbox();
    if (!mounted) return;

    if (!loaded) {
      showThemedSnackBar(
        context,
        'Unable to create test sandbox game.',
        accentColor: scheme.error,
      );
      return;
    }

    showThemedSnackBar(
      context,
      'Test sandbox loaded with simulated roster.',
      accentColor: scheme.tertiary,
    );
    await _refresh();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  Future<void> _loadGameSlot(ColorScheme scheme, String slotId) async {
    final probe = PersistenceService.instance.loadGameSlotDetailed(slotId);
    final slotLabel = _slotLabel(slotId);

    if (!probe.hasAnyData) {
      if (!mounted) return;
      showThemedSnackBar(
        context,
        'No save found in $slotLabel.',
        accentColor: scheme.error,
      );
      return;
    }

    if (probe.data == null) {
      if (!mounted) return;
      showThemedSnackBar(
        context,
        '$slotLabel is unreadable. Clear it and save again.',
        accentColor: scheme.error,
      );
      return;
    }

    final loaded = ref.read(gameProvider.notifier).manualLoad(slotId: slotId);
    if (!mounted) return;

    if (loaded) {
      showThemedSnackBar(
        context,
        'Loaded game from $slotLabel.',
        accentColor: scheme.tertiary,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
      return;
    }

    showThemedSnackBar(
      context,
      'Unable to restore save from $slotLabel.',
      accentColor: scheme.error,
    );
    await _refresh();
  }

  Future<void> _clearGameSlot(ColorScheme scheme, String slotId) async {
    final slotLabel = _slotLabel(slotId);
    final confirmed = await _confirmClearSlot(context, scheme, slotLabel);
    if (confirmed != true) return;

    await PersistenceService.instance.clearGameSlot(slotId);
    if (!mounted) return;
    showThemedSnackBar(
      context,
      '$slotLabel cleared.',
      accentColor: scheme.error, // Migrated from CBColors.warning
    );
    await _refresh();
  }

  Future<bool?> _confirmClearSlot(
    BuildContext context,
    ColorScheme scheme,
    String slotLabel,
  ) {
    final theme = Theme.of(context);
    return showThemedDialog<bool>(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLEAR $slotLabel',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.error,
              letterSpacing: 1.6,
              fontWeight: FontWeight.bold,
              shadows: CBColors.textGlow(scheme.error, intensity: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This will permanently remove all data from $slotLabel. This cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                label: 'CLEAR',
                backgroundColor: scheme
                    .error, // Explicitly set background color for destructive action
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _slotLabel(String slotId) {
    final index = _slotIds.indexOf(slotId);
    final humanIndex = index >= 0 ? index + 1 : slotId;
    return 'SAVE SLOT $humanIndex';
  }

  Future<void> _deleteRecord(GameRecord record, ColorScheme scheme) async {
    await PersistenceService.instance.deleteGameRecord(record.id);
    if (!mounted) return;
    showThemedSnackBar(
      context,
      'Deleted archived game from ${_formatDate(record.endedAt)}.',
      accentColor: scheme.error, // Migrated from CBColors.warning
    );
    await _refresh();
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year} $hh:$min';
  }

  String _winnerLabel(Team winner) {
    switch (winner) {
      case Team.clubStaff:
        return 'CLUB STAFF WIN';
      case Team.partyAnimals:
        return 'PARTY ANIMALS WIN';
      case Team.neutral:
        return 'NEUTRAL WIN';
      case Team.unknown:
        return 'UNKNOWN';
    }
  }

  Color _winnerColor(Team winner, ColorScheme scheme) {
    switch (winner) {
      case Team.clubStaff:
        return scheme.secondary; // Migrated from CBColors.hotPink
      case Team.partyAnimals:
        return scheme.primary; // Migrated from CBColors.electricCyan
      case Team.neutral:
        return scheme
            .surfaceContainerHighest; // Migrated from CBColors.purple to a neutral theme color
      case Team.unknown:
        return scheme.onSurfaceVariant; // Migrated from CBColors.coolGrey
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'SAVE / LOAD',
      drawer: const CustomDrawer(),
      actions: const [SimulationModeBadgeAction()],
      body: _isLoading
          ? const Center(child: CBBreathingSpinner(size: 42))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  CBSectionHeader(
                    title: 'SAVE SLOTS',
                    icon: Icons.shield_outlined,
                    color:
                        scheme.primary, // Migrated from CBColors.electricCyan
                  ),
                  const SizedBox(height: 12),
                  ..._slotIds.map((slotId) {
                    final result =
                        _slotResults[slotId] ?? ActiveGameLoadResult.none();
                    final savedAt = _slotSavedAts[slotId];
                    final slotLabel = _slotLabel(slotId);

                    if (!result.hasAnyData) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CBGlassTile(
                          title: slotLabel,
                          subtitle:
                              'Empty slot. Save the current game state here for manual restore.',
                          accentColor: scheme.outline,
                          isPrismatic: true,
                          icon: Icon(
                            Icons.save_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                          content: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    _saveCurrentGame(scheme, slotId),
                                icon: const Icon(Icons.save_rounded),
                                label: const Text('SAVE HERE'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (result.data == null) {
                      final subtitle = result.failure ==
                              ActiveGameLoadFailure.partialSnapshot
                          ? 'Slot data is incomplete (missing game/session pair).'
                          : 'Slot data is corrupted and cannot be decoded.';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CBGlassTile(
                          title: '$slotLabel • UNREADABLE',
                          subtitle: subtitle,
                          accentColor: scheme.error,
                          isPrismatic: true,
                          icon: Icon(
                            Icons.warning_amber_rounded,
                            color: scheme.error,
                          ),
                          content: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _clearGameSlot(scheme, slotId),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('CLEAR'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final game = result.data!.$1;
                    final savedAtText = savedAt == null
                        ? ''
                        : '\nSaved: ${_formatDate(savedAt)}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CBGlassTile(
                        title: '$slotLabel • READY',
                        subtitle:
                            'Players: ${game.players.length} • Day ${game.dayCount} • ${game.phase.name.toUpperCase()}$savedAtText',
                        accentColor: scheme.primary,
                        isPrismatic: true,
                        icon:
                            Icon(Icons.restore_rounded, color: scheme.primary),
                        content: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _loadGameSlot(scheme, slotId),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('LOAD'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _saveCurrentGame(scheme, slotId),
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('OVERWRITE'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _clearGameSlot(scheme, slotId),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('CLEAR'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  CBPrimaryButton(
                    label: 'LOAD TEST SANDBOX',
                    icon: Icons.science_rounded,
                    backgroundColor:
                        scheme.tertiary, // Migrated from CBColors.matrixGreen
                    onPressed: () => _loadTestSandbox(scheme),
                  ),
                  const SizedBox(height: 28),
                  CBSectionHeader(
                    title: 'ARCHIVED GAMES (${_records.length})',
                    icon: Icons.history_rounded,
                    color: scheme.secondary, // Migrated from CBColors.hotPink
                  ),
                  const SizedBox(height: 12),
                  if (_records.isEmpty)
                    CBPanel(
                      borderColor: scheme
                          .outlineVariant, // Migrated from CBColors.coolGrey
                      child: Text(
                        'No archived game records found. Finished games are archived automatically when a winner is declared.',
                      ),
                    )
                  else
                    ..._records.map(
                      (record) {
                        final winnerColor = _winnerColor(record.winner, scheme);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CBGlassTile(
                            title: _winnerLabel(record.winner),
                            subtitle:
                                '${_formatDate(record.endedAt)} • ${record.playerCount} players • Day ${record.dayCount}',
                            accentColor: winnerColor,
                            isPrismatic: true,
                            icon: Icon(Icons.flag_rounded, color: winnerColor),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Roles in play: ${record.rolesInPlay.take(6).join(', ')}${record.rolesInPlay.length > 6 ? '…' : ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme
                                        .onSurfaceVariant, // Migrated from CBColors.textDim
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _deleteRecord(record, scheme),
                                    icon: const Icon(
                                        Icons.delete_forever_outlined),
                                    label: const Text('DELETE RECORD'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
