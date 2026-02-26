import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';
import 'role.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
abstract class Player with _$Player {
  const Player._();

  const factory Player({
    required String id,
    required String name,
    String? authUid,
    required Role role,
    @Default(false) bool isBot,
    @Default(true) bool isAlive,
    @Default(true) bool isEnabled,
    @Default([]) List<String> statusEffects,
    @Default(1) int lives,
    required Team alliance,
    @Default(false) bool needsSetup,

    // Host God Mode Controls
    @Default(false) bool isMuted,
    @Default(false) bool hasHostShield,
    @Default(false) bool isShadowBanned,
    @Default(false) bool isSinBinned,
    int? hostShieldExpiresDay,

    // Social Mechanics (Bar Tab)
    @Default(0) int drinksOwed,
    @Default([]) List<String> penalties,

    // Death Info
    String? deathReason,
    int? deathDay,

    // ── GHOST LOUNGE & DEAD POOL ──
    String? currentBetTargetId,

    // Role Specific - Medic
    String? medicChoice,
    @Default(false) bool hasReviveToken,
    String? medicProtectedPlayerId,

    // Role Specific - Bouncer
    @Default(false) bool idCheckedByBouncer,
    @Default(false) bool bouncerAbilityRevoked,
    @Default(false) bool bouncerHasRoofiAbility,

    // Role Specific - Club Manager
    @Default(false) bool sightedByClubManager,

    // Role Specific - Messy Bitch
    @Default(false) bool hasRumour,
    @Default(false) bool messyBitchKillUsed,

    // Role Specific - Clinger
    String? clingerPartnerId,
    @Default(false) bool clingerFreedAsAttackDog,
    @Default(false) bool clingerAttackDogUsed,

    // Role Specific - Minor
    @Default([]) List<String> tabooNames,
    @Default(false) bool minorHasBeenIDd,

    // Role Specific - Lightweight
    @Default([]) List<String> blockedVoteTargets,

    // Role Specific - Wallflower
    @Default(false) bool isExposed,

    // Role Specific - Sober
    @Default(false) bool soberAbilityUsed,
    @Default(false) bool soberSentHome,

    // Role Specific - Silver Fox
    @Default(false) bool silverFoxAbilityUsed,
    int? alibiDay,

    // Role Specific - Second Wind
    @Default(false) bool secondWindConverted,
    @Default(false) bool secondWindPendingConversion,
    @Default(false) bool secondWindRefusedConversion,
    int? secondWindConversionNight,
    @Default(false) bool joinsNextNight,

    // Role Specific - Roofi
    int? silencedDay,
    @Default(false) bool roofiAbilityRevoked,

    // Role Specific - Dealer
    int? blockedKillNight,

    // Persistent Targets
    String? creepTargetId,
    String? teaSpillerTargetId,
    String? predatorTargetId,
    String? dramaQueenTargetAId,
    String? dramaQueenTargetBId,
    String? whoreDeflectionTargetId,
    @Default(false) bool whoreDeflectionUsed,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  /// Helper to check if player is active (alive + enabled)
  bool get isActive => isAlive && isEnabled && !joinsNextNight;
}
