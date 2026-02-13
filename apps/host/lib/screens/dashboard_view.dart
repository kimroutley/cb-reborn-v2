import 'dart:math';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/ai_recap_export.dart';

/// Host Command Center - Tactical Dashboard with God Mode and Analytics
class DashboardView extends ConsumerStatefulWidget {
  final GameState gameState;

  const DashboardView({super.key, required this.gameState});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  String _logFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: CBInsets.screen,
      children: [
        // Header
        CBSectionHeader(
          title: 'Host Command Center',
          color: scheme.primary,
          icon: Icons.dashboard_customize,
        ),
        const SizedBox(height: 24),

        // Live Intel
        if (widget.gameState.phase != GamePhase.lobby) ...[
          _buildLiveIntel(),
          const SizedBox(height: 24),
          _buildDeadPoolOddsPanel(),
          const SizedBox(height: 24),
        ],

        // God Mode Control Panel
        if (widget.gameState.phase != GamePhase.lobby &&
            widget.gameState.phase != GamePhase.endGame) ...[
          _buildGodModePanel(),
          const SizedBox(height: 24),
        ],

        // Director Commands
        _buildDirectorCommands(),
        const SizedBox(height: 24),

        // Enhanced Logs
        _buildEnhancedLogs(),
        const SizedBox(height: 24),

        // AI Export
        _buildAIExport(),
      ],
    );
  }

  Widget _buildLiveIntel() {
    final scheme = Theme.of(context).colorScheme;
    final players = widget.gameState.players;
    final alive = players.where((p) => p.isAlive).toList();
    final staff = alive.where((p) => p.alliance == Team.clubStaff).length;
    final animals = alive.where((p) => p.alliance == Team.partyAnimals).length;
    final total = staff + animals;
    final staffOdds = total > 0 ? (staff / total * 100).round() : 50;

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'Live Intel & Win Prediction',
            color: scheme.primary,
            icon: Icons.analytics,
          ),
          const SizedBox(height: 16),

          // Win Odds Bars
          Text(
            'WIN PROBABILITY',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 8),
          _winOddsBar('CLUB STAFF', staffOdds, scheme.error),
          const SizedBox(height: 6),
          _winOddsBar('PARTY ANIMALS', 100 - staffOdds, scheme.tertiary),
          const SizedBox(height: 16),

          // Player Health Rail
          Text(
            'PLAYER STATUS',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPlayerAvatar(player),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _winOddsBar(String label, int percentage, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.bodySmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: textTheme.bodySmall!.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerAvatar(Player player) {
    final textTheme = Theme.of(context).textTheme;
    Color statusColor = CBColors.matrixGreen;
    if (!player.isAlive) {
      statusColor = CBColors.dead;
    } else if (player.isSinBinned) {
      statusColor = CBColors.darkMetal;
    } else if (player.isShadowBanned) {
      statusColor = CBColors.alertOrange;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            CBRoleAvatar(
              assetPath: player.role.assetPath,
              color: CBColors.fromHex(player.role.colorHex),
              size: 40,
            ),
            // Status dot
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: CBColors.surface, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            // Shield icon
            if (player.hasHostShield)
              const Positioned(
                top: -2,
                left: -2,
                child: Icon(
                  Icons.shield,
                  color: CBColors.electricCyan,
                  size: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          player.name.split(' ').first,
          style: textTheme.bodySmall!.copyWith(
            fontSize: 8,
            color: statusColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildGodModePanel() {
    final alivePlayers =
        widget.gameState.players.where((p) => p.isAlive).toList();

    return CBPanel(
      borderColor: CBColors.radiantPink.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'God Mode Controls',
            color: CBColors.radiantPink,
            icon: Icons.flash_on,
          ),
          const SizedBox(height: 8),
          Text(
            'Powerful host tools. Use responsibly.',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: CBColors.matrixGreen,
                ),
          ),
          const SizedBox(height: 16),
          ...alivePlayers.map((player) => _buildPlayerControlTile(player)),
        ],
      ),
    );
  }

  Widget _buildDeadPoolOddsPanel() {
    final scheme = Theme.of(context).colorScheme;
    final playersById = {
      for (final player in widget.gameState.players) player.id: player,
    };

    final activeBets = widget.gameState.deadPoolBets.entries.toList();
    final deadBettors =
        widget.gameState.players.where((p) => !p.isAlive).toList();

    final betCounts = <String, int>{};
    for (final entry in activeBets) {
      betCounts[entry.value] = (betCounts[entry.value] ?? 0) + 1;
    }

    return CBPanel(
      borderColor: scheme.error.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'Dead Pool Live Bets',
            color: scheme.error,
            icon: Icons.casino_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            deadBettors.isEmpty
                ? 'No eliminated players yet.'
                : activeBets.isEmpty
                    ? 'No active bets placed by ghosts.'
                    : '${activeBets.length} active bets',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (activeBets.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...activeBets.map((entry) {
              final bettor = playersById[entry.key];
              final target = playersById[entry.value];
              final oddsCount = betCounts[entry.value] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${bettor?.name ?? entry.key} → ${target?.name ?? entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    CBBadge(
                      text: '$oddsCount on target',
                      color: CBColors.alertOrange,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerControlTile(Player player) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      leading: CBRoleAvatar(
        assetPath: player.role.assetPath,
        color: CBColors.fromHex(player.role.colorHex),
        size: 32,
      ),
      title: Text(
        player.name,
        style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        player.role.name,
        style: textTheme.bodySmall!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CBGhostButton(
                label: 'KILL',
                color: CBColors.dead,
                onPressed: () => _confirmKill(player),
              ),
              CBGhostButton(
                label: player.isMuted ? 'UNMUTE' : 'MUTE',
                color: CBColors.alertOrange,
                onPressed: () => _toggleMute(player),
              ),
              CBGhostButton(
                label: player.hasHostShield ? 'REMOVE SHIELD' : 'GRANT SHIELD',
                color: CBColors.electricCyan,
                onPressed: () => _grantShield(player),
              ),
              CBGhostButton(
                label: player.isSinBinned ? 'RELEASE' : 'SIN BIN',
                color: CBColors.darkMetal,
                onPressed: () => _toggleSinBin(player),
              ),
              CBGhostButton(
                label: player.isShadowBanned ? 'UNBAN' : 'SHADOW BAN',
                color: CBColors.alertOrange,
                onPressed: () => _toggleShadowBan(player),
              ),
              CBGhostButton(
                label: 'KICK',
                color: CBColors.dead,
                onPressed: () => _kickPlayer(player),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectorCommands() {
    final scheme = Theme.of(context).colorScheme;
    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CBSectionHeader(
            title: 'Director Commands',
            icon: Icons.movie_filter,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _directorButton(
                'RANDOM RUMOUR',
                Icons.campaign_rounded,
                scheme.secondary,
                _flashRandomRumour,
              ),
              _directorButton(
                'VOICE OF GOD',
                Icons.record_voice_over_rounded,
                scheme.primary,
                _voiceOfGod,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _directorButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 160,
      child: CBGhostButton(
        label: label,
        color: color,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildEnhancedLogs() {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final filteredLogs = _filterLogs(widget.gameState.gameHistory);

    return CBPanel(
      borderColor: CBColors.radiantTurquoise.withValues(alpha: 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CBSectionHeader(
            title: 'Enhanced Session Logs',
            icon: Icons.history,
          ),
          const SizedBox(height: 16),

          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['ALL', 'SYSTEM', 'ACTION', 'HOST'].map((filter) {
              final color = switch (filter) {
                'SYSTEM' => scheme.secondary,
                'ACTION' => scheme.tertiary,
                'HOST' => scheme.error,
                _ => scheme.primary,
              };
              final icon = switch (filter) {
                'SYSTEM' => Icons.memory_rounded,
                'ACTION' => Icons.flash_on_rounded,
                'HOST' => Icons.admin_panel_settings_rounded,
                _ => Icons.all_inclusive_rounded,
              };

              return CBFilterChip(
                label: filter,
                icon: icon,
                color: color,
                selected: _logFilter == filter,
                onSelected: () => setState(() => _logFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Search field
          CBTextField(
            decoration: const InputDecoration(
              hintText: 'Search logs...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 16),

          // Log list
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[filteredLogs.length - 1 - index];
                final isHost = log.contains('[HOST]');
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '> ',
                        style: textTheme.bodySmall!.copyWith(
                          color: isHost ? scheme.error : scheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          log,
                          style: textTheme.bodySmall!.copyWith(
                            color: isHost
                                ? scheme.error
                                : scheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
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

  Widget _buildAIExport() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CBPanel(
      padding: const EdgeInsets.all(20),
      borderColor: scheme.secondary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBBadge(text: 'AI RECAP EXPORT', color: scheme.secondary),
          const SizedBox(height: 16),

          Text(
            'Generate a Gemini-ready prompt for game recap',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // Export button (opens style menu)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('GENERATE AI RECAP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => showAIRecapExportMenu(
                context: context,
                controller: ref.read(gameProvider.notifier),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _filterLogs(List<String> logs) {
    var filtered = logs;

    // Apply category filter
    if (_logFilter != 'ALL') {
      filtered = filtered.where((log) {
        switch (_logFilter) {
          case 'SYSTEM':
            return log.contains('──') ||
                log.contains('NIGHT') ||
                log.contains('DAY');
          case 'ACTION':
            return !log.contains('──') && !log.contains('[HOST]');
          case 'HOST':
            return log.contains('[HOST]');
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (log) => log.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  // Action Methods

  void _confirmKill(Player player) {
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONFIRM KILL',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows:
                      CBColors.textGlow(scheme.error, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Force eliminate ${player.name}? This will trigger death effects.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.75),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'KILL',
                backgroundColor: scheme.error,
                onPressed: () {
                  ref.read(gameProvider.notifier).forceKillPlayer(player.id);
                  Navigator.pop(context);
                  showThemedSnackBar(context, '${player.name} eliminated');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _toggleMute(Player player) {
    ref
        .read(gameProvider.notifier)
        .togglePlayerMute(player.id, !player.isMuted);
    showThemedSnackBar(
        context, '${player.name} ${player.isMuted ? 'unmuted' : 'muted'}');
  }

  void _grantShield(Player player) {
    final scheme = Theme.of(context).colorScheme;
    // Grant or update shield
    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GRANT SHIELD',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows:
                      CBColors.textGlow(scheme.primary, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Grant temporary immunity to ${player.name}.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<int>(
            initialSelection: 1,
            label: const Text('Duration (days)'),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 1, label: '1 day'),
              DropdownMenuEntry(value: 2, label: '2 days'),
              DropdownMenuEntry(value: 3, label: '3 days'),
            ],
            onSelected: (days) {
              if (days == null) return;
              Navigator.pop(context);
              ref.read(gameProvider.notifier).grantHostShield(player.id, days);
              showThemedSnackBar(
                context,
                'Shield granted to ${player.name} ($days days)',
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _toggleSinBin(Player player) {
    ref.read(gameProvider.notifier).setSinBin(player.id, !player.isSinBinned);
    showThemedSnackBar(context,
        '${player.name} ${player.isSinBinned ? 'released from' : 'sent to'} sin bin');
  }

  void _toggleShadowBan(Player player) {
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.tertiary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.isShadowBanned ? 'CONFIRM UNBAN' : 'CONFIRM SHADOW BAN',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.tertiary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            player.isShadowBanned
                ? 'Remove shadow ban from ${player.name}?'
                : 'Shadow ban ${player.name}? Their actions will be silently discarded without their knowledge.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.75),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: player.isShadowBanned ? 'UNBAN' : 'SHADOW BAN',
                backgroundColor: scheme.tertiary,
                onPressed: () {
                  ref
                      .read(gameProvider.notifier)
                      .setShadowBan(player.id, !player.isShadowBanned);
                  Navigator.pop(context);
                  showThemedSnackBar(context,
                      '${player.name} ${player.isShadowBanned ? 'unbanned' : 'shadow banned'}');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _kickPlayer(Player player) {
    String reason = '';
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.error,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KICK PLAYER',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.error,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows: CBColors.textGlow(scheme.error, intensity: 0.5),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Permanently remove ${player.name} from the game?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface
                      .withValues(alpha: 0.75),
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 16),
          CBTextField(
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
            ),
            onChanged: (value) => reason = value,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'KICK',
                backgroundColor: scheme.error,
                onPressed: () {
                  ref.read(gameProvider.notifier).kickPlayer(player.id,
                      reason.isEmpty ? 'No reason provided' : reason);
                  Navigator.pop(context);
                  showThemedSnackBar(
                      context, '${player.name} kicked from game');
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _flashRandomRumour() {
    final alivePlayers =
        widget.gameState.players.where((p) => p.isAlive).toList();
    if (alivePlayers.isEmpty) return;

    final target = alivePlayers[Random().nextInt(alivePlayers.length)];
    final rumour = rumourTemplates[Random().nextInt(rumourTemplates.length)]
        .replaceAll('{player}', target.name);

    ref.read(gameProvider.notifier).dispatchBulletin(
          title: 'RUMOUR MILL',
          content: rumour,
          type: 'event',
        );

    showThemedSnackBar(context, 'Rumour dispatched to all players');
  }

  void _voiceOfGod() {
    String message = '';
    final scheme = Theme.of(context).colorScheme;
    showThemedDialog(
      context: context,
      accentColor: scheme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOICE OF GOD',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.bold,
                  shadows:
                      CBColors.textGlow(scheme.primary, intensity: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          CBTextField(
            decoration: const InputDecoration(
              labelText: 'Announcement',
              hintText: 'Your message to all players...',
            ),
            maxLines: 3,
            onChanged: (value) => message = value,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CBGhostButton(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              CBPrimaryButton(
                fullWidth: false,
                label: 'SEND',
                onPressed: () {
                  if (message.isNotEmpty) {
                    ref.read(gameProvider.notifier).dispatchBulletin(
                          title: 'HOST ANNOUNCEMENT',
                          content: message,
                          type: 'urgent',
                        );
                    Navigator.pop(context);
                    showThemedSnackBar(
                        context, 'Announcement sent to all players');
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showHelpSheet() {
    showThemedBottomSheet<void>(
      context: context,
      accentColor: CBColors.electricCyan,
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HOST DASHBOARD GUIDE',
                style: textTheme.headlineSmall?.copyWith(
                  letterSpacing: 2.0,
                  color: CBColors.electricCyan,
                  shadows:
                      CBColors.textGlow(CBColors.electricCyan, intensity: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Live Intel: Real-time win probabilities and player status',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'God Mode: Powerful admin controls (use responsibly!)',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Director Commands: Fun narrative tools and announcements',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enhanced Logs: Filterable game history with search',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'AI Export: Generate Gemini prompts for game recaps',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ God Mode can break game balance. Recommended for fixing mistakes or handling disruptive players only.',
                style: textTheme.bodySmall?.copyWith(
                  color: CBColors.alertOrange,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
