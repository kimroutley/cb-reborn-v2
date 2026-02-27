import 'dart:math' as math;

import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class LiveIntelPanel extends StatelessWidget {
  final GameState gameState;

  const LiveIntelPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final players = gameState.players;

    final alive = players.where((p) => p.isAlive).toList();
    final dead = players.where((p) => !p.isAlive).toList();
    final staff = alive.where((p) => p.alliance == Team.clubStaff).toList();
    final animals =
        alive.where((p) => p.alliance == Team.partyAnimals).toList();
    final neutrals = alive.where((p) => p.alliance == Team.neutral).toList();
    final alivePlayerIds = alive.map((p) => p.id).toSet();
    final pendingDramaSwapTargetIds = <String>{};
    for (final dramaQueen in players.where(
      (p) => p.role.id == RoleIds.dramaQueen && p.isAlive,
    )) {
      final targetAId = dramaQueen.dramaQueenTargetAId;
      final targetBId = dramaQueen.dramaQueenTargetBId;
      if (targetAId == null || targetBId == null) continue;
      if (targetAId == targetBId) continue;
      if (targetAId == dramaQueen.id || targetBId == dramaQueen.id) continue;
      if (!alivePlayerIds.contains(targetAId) ||
          !alivePlayerIds.contains(targetBId)) {
        continue;
      }
      pendingDramaSwapTargetIds
        ..add(targetAId)
        ..add(targetBId);
    }

    final odds = _calculateWinOdds(alive, staff, animals, neutrals);

    return CBPanel(
      borderColor: scheme.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'TACTICAL INTELLIGENCE',
            color: scheme.primary,
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 16),

          // Phase & Round Tracker
          _PhaseTracker(gameState: gameState),
          const SizedBox(height: 14),

          // Faction Breakdown
          Row(
            children: [
              Text(
                '// FACTION BREAKDOWN',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
              const Spacer(),
              CBBadge(
                text: '${alive.length}/${players.length} ALIVE',
                color: scheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FactionChip(
                label: 'STAFF',
                count: staff.length,
                color: scheme.secondary,
              ),
              const SizedBox(width: 8),
              _FactionChip(
                label: 'ANIMALS',
                count: animals.length,
                color: scheme.tertiary,
              ),
              if (neutrals.isNotEmpty) ...[
                const SizedBox(width: 8),
                _FactionChip(
                  label: 'NEUTRAL',
                  count: neutrals.length,
                  color: CBColors.alertOrange,
                ),
              ],
              const SizedBox(width: 8),
              _FactionChip(
                label: 'DEAD',
                count: dead.length,
                color: scheme.error,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Win Odds
          Text(
            '// PROBABILITY MATRIX',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 12),
          _WinOddsBar(
            label: 'CLUB STAFF',
            percentage: odds.staffOdds,
            color: scheme.secondary,
            detail: odds.staffDetail,
          ),
          const SizedBox(height: 12),
          _WinOddsBar(
            label: 'PARTY ANIMALS',
            percentage: odds.animalOdds,
            color: scheme.tertiary,
            detail: odds.animalDetail,
          ),

          const SizedBox(height: 16),

          // Key Role Status Intel
          _RoleIntelSection(alive: alive, scheme: scheme, textTheme: textTheme),

          const SizedBox(height: 14),

          // Player Health Rail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '// PATRON STATUS RAIL',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildPlayerAvatar(
                    context,
                    player,
                    hasPendingDramaSwap:
                        pendingDramaSwapTargetIds.contains(player.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _WinOddsResult _calculateWinOdds(
    List<Player> alive,
    List<Player> staff,
    List<Player> animals,
    List<Player> neutrals,
  ) {
    if (alive.isEmpty) {
      return const _WinOddsResult(
        staffOdds: 50,
        animalOdds: 50,
        staffDetail: '',
        animalDetail: '',
      );
    }

    final staffCount = staff.length;
    final animalCount = animals.length;
    final total = staffCount + animalCount + neutrals.length;
    if (total == 0) {
      return const _WinOddsResult(
        staffOdds: 50,
        animalOdds: 50,
        staffDetail: '',
        animalDetail: '',
      );
    }

    // Base ratio from headcount
    double staffScore = staffCount.toDouble();
    double animalScore = animalCount.toDouble();

    // Factor in extra lives
    for (final p in staff) {
      if (p.lives > 1) staffScore += (p.lives - 1) * 0.5;
      if (p.hasHostShield) staffScore += 0.4;
    }
    for (final p in animals) {
      if (p.lives > 1) animalScore += (p.lives - 1) * 0.5;
      if (p.hasHostShield) animalScore += 0.4;
    }

    // Key role bonuses
    final hasLivingMedic =
        alive.any((p) => p.role.id == RoleIds.medic && p.hasReviveToken);
    final hasLivingBouncer =
        alive.any((p) => p.role.id == RoleIds.bouncer && !p.bouncerAbilityRevoked);
    final hasLivingSober =
        alive.any((p) => p.role.id == RoleIds.sober && !p.soberAbilityUsed);
    final hasLivingSilverFox =
        alive.any((p) => p.role.id == RoleIds.silverFox && !p.silverFoxAbilityUsed);

    if (hasLivingMedic) animalScore += 0.6;
    if (hasLivingBouncer) animalScore += 0.5;
    if (hasLivingSober) animalScore += 0.3;
    if (hasLivingSilverFox) animalScore += 0.3;

    // Dealers inherently have info asymmetry advantage
    final dealerCount = staff.where((p) => p.role.id == RoleIds.dealer).length;
    staffScore += dealerCount * 0.3;

    // Staff win when they equal or outnumber animals — so closer parity = staff advantage
    final ratio = staffCount / math.max(animalCount, 1);
    if (ratio >= 0.5) staffScore += 0.4;
    if (ratio >= 0.8) staffScore += 0.6;

    // Neutrals slightly favour chaos (which generally benefits staff)
    staffScore += neutrals.length * 0.15;

    final totalScore = staffScore + animalScore;
    final rawStaffPct = (staffScore / totalScore * 100).round();
    final clampedStaff = rawStaffPct.clamp(5, 95);

    String staffDetail = '$staffCount alive';
    if (dealerCount > 0) staffDetail += ' · $dealerCount dealer${dealerCount > 1 ? 's' : ''}';
    String animalDetail = '$animalCount alive';
    final activeAbilities = <String>[];
    if (hasLivingMedic) activeAbilities.add('Medic');
    if (hasLivingBouncer) activeAbilities.add('Bouncer');
    if (hasLivingSober) activeAbilities.add('Sober');
    if (hasLivingSilverFox) activeAbilities.add('Silver Fox');
    if (activeAbilities.isNotEmpty) {
      animalDetail += ' · ${activeAbilities.join(', ')}';
    }

    return _WinOddsResult(
      staffOdds: clampedStaff,
      animalOdds: 100 - clampedStaff,
      staffDetail: staffDetail,
      animalDetail: animalDetail,
    );
  }

  Widget _buildPlayerAvatar(
    BuildContext context,
    Player player, {
    required bool hasPendingDramaSwap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color statusColor = scheme.tertiary;
    if (!player.isAlive) {
      statusColor = CBColors.dead;
    } else if (player.isSinBinned) {
      statusColor = scheme.error;
    } else if (player.isShadowBanned) {
      statusColor = scheme.secondary;
    }

    final roleColor = CBColors.fromHex(player.role.colorHex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CBRoleAvatar(
              assetPath: player.role.assetPath,
              color: roleColor,
              size: 44,
              pulsing: player.isAlive && !player.isSinBinned,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 2),
                  boxShadow: CBColors.circleGlow(statusColor, intensity: 0.4),
                ),
              ),
            ),
            if (player.hasHostShield)
              Positioned(
                top: -4,
                left: -4,
                child: Icon(
                  Icons.shield_rounded,
                  color: scheme.primary,
                  size: 18,
                  shadows: CBColors.iconGlow(scheme.primary),
                ),
              ),
            if (player.lives > 1)
              Positioned(
                top: -6,
                left: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.tertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${player.lives}HP',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: scheme.surface,
                    ),
                  ),
                ),
              ),
            if (hasPendingDramaSwap)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: CBColors.boxGlow(
                      scheme.secondary,
                      intensity: 0.25,
                    ),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    size: 10,
                    color: scheme.surface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          player.name.toUpperCase().split(' ').first,
          style: textTheme.labelSmall!.copyWith(
            fontSize: 8,
            color: statusColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Supporting Widgets ──

class _WinOddsResult {
  final int staffOdds;
  final int animalOdds;
  final String staffDetail;
  final String animalDetail;

  const _WinOddsResult({
    required this.staffOdds,
    required this.animalOdds,
    required this.staffDetail,
    required this.animalDetail,
  });
}

class _PhaseTracker extends StatelessWidget {
  final GameState gameState;
  const _PhaseTracker({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final phaseLabel = switch (gameState.phase) {
      GamePhase.lobby => 'LOBBY',
      GamePhase.setup => 'SETUP',
      GamePhase.night => 'NIGHT ${gameState.dayCount}',
      GamePhase.day => 'DAY ${gameState.dayCount}',
      GamePhase.resolution => 'RESOLUTION',
      GamePhase.endGame => 'GAME OVER',
    };
    final phaseColor = switch (gameState.phase) {
      GamePhase.night => scheme.secondary,
      GamePhase.day => scheme.tertiary,
      GamePhase.endGame => scheme.error,
      _ => scheme.primary,
    };
    final phaseIcon = switch (gameState.phase) {
      GamePhase.night => Icons.nightlight_round,
      GamePhase.day => Icons.wb_sunny_rounded,
      GamePhase.setup => Icons.settings_rounded,
      GamePhase.endGame => Icons.flag_rounded,
      _ => Icons.access_time_rounded,
    };

    final scriptProgress = gameState.scriptQueue.isEmpty
        ? 0.0
        : (gameState.scriptIndex + 1) / gameState.scriptQueue.length;

    return CBGlassTile(
      isPrismatic: true,
      borderColor: phaseColor.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(phaseIcon, color: phaseColor, size: 20,
                  shadows: CBColors.iconGlow(phaseColor, intensity: 0.4)),
              const SizedBox(width: 10),
              Text(
                phaseLabel,
                style: textTheme.labelLarge!.copyWith(
                  color: phaseColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: CBColors.textGlow(phaseColor, intensity: 0.4),
                ),
              ),
              const Spacer(),
              if (gameState.scriptQueue.isNotEmpty)
                Text(
                  'STEP ${gameState.scriptIndex + 1}/${gameState.scriptQueue.length}',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
            ],
          ),
          if (gameState.scriptQueue.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: scriptProgress,
                minHeight: 4,
                backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(phaseColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FactionChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _FactionChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: textTheme.titleMedium!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                shadows: CBColors.textGlow(color, intensity: 0.3),
              ),
            ),
            Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinOddsBar extends StatelessWidget {
  final String label;
  final int percentage;
  final Color color;
  final String detail;

  const _WinOddsBar({
    required this.label,
    required this.percentage,
    required this.color,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: textTheme.labelSmall!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Text(
              '$percentage%',
              style: textTheme.labelLarge!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                shadows: CBColors.textGlow(color, intensity: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * (percentage / 100),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: CBColors.boxGlow(color, intensity: 0.3),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detail.toUpperCase(),
            style: textTheme.labelSmall!.copyWith(
              color: color.withValues(alpha: 0.5),
              fontSize: 7,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleIntelSection extends StatelessWidget {
  final List<Player> alive;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _RoleIntelSection({
    required this.alive,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final keyRoles = <_RoleStatus>[];

    for (final p in alive) {
      final rid = p.role.id;
      if (rid == RoleIds.partyAnimal || rid == 'unassigned') continue;

      String? abilityStatus;
      Color statusColor = scheme.tertiary;

      if (rid == RoleIds.medic) {
        abilityStatus = p.hasReviveToken ? 'REVIVE READY' : 'REVIVE USED';
        statusColor = p.hasReviveToken ? scheme.tertiary : scheme.error;
      } else if (rid == RoleIds.bouncer) {
        abilityStatus = p.bouncerAbilityRevoked ? 'ABILITY REVOKED' : 'ACTIVE';
        statusColor = p.bouncerAbilityRevoked ? scheme.error : scheme.tertiary;
      } else if (rid == RoleIds.sober) {
        abilityStatus = p.soberAbilityUsed ? 'USED' : 'AVAILABLE';
        statusColor = p.soberAbilityUsed ? scheme.error : scheme.tertiary;
      } else if (rid == RoleIds.silverFox) {
        abilityStatus = p.silverFoxAbilityUsed ? 'ALIBI USED' : 'ALIBI READY';
        statusColor = p.silverFoxAbilityUsed ? scheme.error : scheme.tertiary;
      } else if (rid == RoleIds.roofi) {
        abilityStatus = p.roofiAbilityRevoked ? 'REVOKED' : 'ACTIVE';
        statusColor = p.roofiAbilityRevoked ? scheme.error : scheme.tertiary;
      } else if (rid == RoleIds.messyBitch) {
        abilityStatus = p.messyBitchKillUsed ? 'KILL SPENT' : 'KILL READY';
        statusColor = p.messyBitchKillUsed ? scheme.error : scheme.tertiary;
      } else if (rid == RoleIds.clinger) {
        if (p.clingerPartnerId != null) {
          abilityStatus = 'ATTACHED';
        } else {
          abilityStatus = 'UNATTACHED';
        }
      } else if (rid == RoleIds.secondWind) {
        abilityStatus = p.secondWindConverted ? 'CONVERTED' : 'DORMANT';
        statusColor = p.secondWindConverted ? scheme.secondary : scheme.primary;
      } else {
        continue;
      }

      keyRoles.add(_RoleStatus(
        name: p.role.name,
        playerName: p.name,
        status: abilityStatus,
        color: CBColors.fromHex(p.role.colorHex),
        statusColor: statusColor,
      ));
    }

    if (keyRoles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// KEY ROLE ABILITIES',
          style: textTheme.labelSmall!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keyRoles
              .map((r) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: r.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: r.color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: r.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${r.name.toUpperCase()} (${r.playerName.split(' ').first.toUpperCase()})',
                          style: textTheme.labelSmall!.copyWith(
                            color: r.color,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          r.status,
                          style: textTheme.labelSmall!.copyWith(
                            color: r.statusColor,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _RoleStatus {
  final String name;
  final String playerName;
  final String status;
  final Color color;
  final Color statusColor;

  const _RoleStatus({
    required this.name,
    required this.playerName,
    required this.status,
    required this.color,
    required this.statusColor,
  });
}
