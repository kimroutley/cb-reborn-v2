import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';

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
    ref
        .read(hostNavigationProvider.notifier)
        .setDestination(HostDestination.game);
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
      ref
          .read(hostNavigationProvider.notifier)
          .setDestination(HostDestination.game);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final slots = _slotIds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAVE & LOAD'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [SimulationModeBadgeAction()],
      ),
      drawer: const CustomDrawer(),
      body: CBNeonBackground(
        child: _isLoading
            ? const Center(child: CBBreathingSpinner())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSandboxPanel(scheme, textTheme),
                    const SizedBox(height: 24),
                    CBSectionHeader(
                      title: 'SAVE SLOTS',
                      icon: Icons.save_alt,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 12),
                    ...slots.map(
                      (id) => _buildSaveSlotTile(
                        context: context,
                        slotId: id,
                        scheme: scheme,
                        textTheme: textTheme,
                        result: _slotResults[id] ?? ActiveGameLoadResult.none(),
                        savedAt: _slotSavedAts[id],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CBSectionHeader(
                      title: 'PAST GAME RECORDS',
                      icon: Icons.history,
                      color: scheme.secondary,
                    ),
                    const SizedBox(height: 12),
                    if (_records.isEmpty)
                      CBPanel(
                        borderColor: scheme.secondary.withValues(alpha: 0.4),
                        child: Text(
                          'No completed games found in the archive.',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurface),
                        ),
                      )
                    else
                      ..._records.map(
                        (r) => _buildRecordTile(
                          context,
                          r,
                          scheme,
                          textTheme,
                        ),
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSandboxPanel(ColorScheme scheme, TextTheme textTheme) {
    final textTheme = Theme.of(context).textTheme;

    return CBPanel(
      borderColor: scheme.tertiary.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOAD TEST SANDBOX',
            style: textTheme.headlineSmall
                ?.copyWith(color: scheme.tertiary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'This will load a test sandbox game with a simulated roster.',
            style: textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurface, height: 1.3),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBPrimaryButton(
                label: 'LOAD SANDBOX',
                backgroundColor: scheme.tertiary,
                onPressed: () => _loadTestSandbox(scheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveSlotTile({
    required BuildContext context,
    required String slotId,
    required ColorScheme scheme,
    required TextTheme textTheme,
    required ActiveGameLoadResult result,
    DateTime? savedAt,
  }) {
    final slotLabel = _slotLabel(slotId);

    if (!result.hasAnyData) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CBPanel(
          borderColor: scheme.outline.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.save_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: CBSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slotLabel,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                color: scheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Empty slot. Save the current game state here for manual restore.',
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => _saveCurrentGame(scheme, slotId),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('SAVE HERE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (result.data == null) {
      final subtitle = result.failure == ActiveGameLoadFailure.partialSnapshot
          ? 'Slot data is incomplete (missing game/session pair).'
          : 'Slot data is corrupted and cannot be decoded.';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CBPanel(
          borderColor: scheme.error.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: scheme.error,
                  ),
                  const SizedBox(width: CBSpace.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$slotLabel • UNREADABLE',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                color: scheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
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
            ],
          ),
        ),
      );
    }

    final game = result.data!.$1;
    final savedAtText =
        savedAt == null ? '' : '\nSaved: ${_formatDate(savedAt)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CBPanel(
        borderColor: result.hasAnyData
            ? scheme.primary.withValues(alpha: 0.55)
            : scheme.onSurface.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restore_rounded, color: scheme.primary),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$slotLabel • READY',
                        style:
                            Theme.of(context).textTheme.headlineSmall!.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Players: ${game.players.length} • Day ${game.dayCount} • ${game.phase.name.toUpperCase()}$savedAtText',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
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
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(
    BuildContext context,
    GameRecord record,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    final winner = record.winner;
    final color = winner == Team.clubStaff
        ? scheme.primary
        : (winner == Team.partyAnimals ? scheme.secondary : scheme.tertiary);

    return CBPanel(
      borderColor: color.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: color),
              const SizedBox(width: CBSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _winnerLabel(record.winner),
                      style: textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(record.endedAt)} • ${record.playerCount} players • Day ${record.dayCount}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Roles in play: ${record.rolesInPlay.take(6).join(', ')}${record.rolesInPlay.length > 6 ? '…' : ''}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _deleteRecord(record, scheme),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('DELETE RECORD'),
            ),
          ),
        ],
      ),
    );
  }
}
