# Role Awards System Plan

This document captures a merge-ready implementation plan for a role-based awards ladder across Host + Player apps.

> Status: Phase 1 role-specific ladders implemented and validated across models, logic, host, and player (including Hall of Fame role/tier filters and role-specific deterministic unlock profiles).
> Last updated: Feb 18, 2026

## 1) Goal

Create a scalable, cloud-ready **Role Awards** system that:

- covers all canonical roles in `role_catalog`
- supports a **3-tier core ladder** (`Rookie`, `Pro`, `Legend`)
- supports **bonus awards** per role
- integrates with existing Hall of Fame + recap surfaces
- preserves legacy game record compatibility

## 2) Locked decisions (for merge alignment)

- **Role scope:** all canonical roles in `packages/cb_models/lib/src/data/role_catalog.dart`
- **Award structure:** 3-tier core + bonus awards per role
- **Storage direction:** cloud-ready schema from day one
- **Identity keying:** stable player identifier (not display name only)
- **Tone:** hard-edged adult banter focused on gameplay behavior only

## 3) Canonical sources

- Role IDs: `packages/cb_models/lib/src/role_ids.dart`
- Role catalog: `packages/cb_models/lib/src/data/role_catalog.dart`
- Award names + icon metadata catalog: `AWARDS_NAME_ICON_CATALOG.md`
- Existing recap awards: `packages/cb_logic/lib/src/recap_generator.dart`
- Existing persistence: `packages/cb_logic/lib/src/persistence/persistence_service.dart`
- Host Hall of Fame: `apps/host/lib/screens/hall_of_fame_screen.dart`
- Player Hall of Fame: `apps/player/lib/screens/hall_of_fame_screen.dart`

## 4) Data model plan

Add shared awards domain in `packages/cb_models`:

- `RoleAwardTier`
  - `rookie`, `pro`, `legend`, `bonus`
- `RoleAwardDefinition`
  - `awardId` (stable key)
  - `roleId` (must map to `RoleIds`)
  - `tier`
  - `title`
  - `description`
  - `unlockRule` (structured metadata; threshold/condition)
  - optional `toneVariant` metadata
- `PlayerRoleAwardProgress`
  - `playerKey` (stable)
  - `awardId`
  - `progressValue`
  - `isUnlocked`
  - `unlockedAt`
  - `sourceGameId` / `sourceSessionId` (optional provenance)

Add canonical catalog:

- `packages/cb_models/lib/src/data/role_award_catalog.dart`
- one entry-set per role
- each role includes Rookie/Pro/Legend + bonus awards

## 5) Computation + persistence plan

Extend `PersistenceService` to:

- compute award progress from `GameRecord` history
- store/retrieve `PlayerRoleAwardProgress`
- expose query APIs:
  - by player
  - by role
  - by tier
  - recent unlocks
- keep computation idempotent for safe backfill/replay

Compatibility requirements:

- old records without awards remain readable
- lazy recompute/backfill when award data is missing

## 6) UI integration plan

### Host app

- `apps/host/lib/screens/hall_of_fame_screen.dart`
  - role/tier filters
  - leaderboard + unlock summaries
  - if role awards are not configured yet, show: `Awards Coming Soon`
- `apps/host/lib/screens/games_night_recap_screen.dart`
  - “new unlocks” award slide(s)

### Player app

- `apps/player/lib/screens/hall_of_fame_screen.dart`
  - personal role ladder progress
  - unlocked badge grid/list
  - if role awards are not configured yet, show: `Awards Coming Soon`
- `apps/player/lib/screens/stats_screen.dart`
  - entry point card into role awards

Consistency requirement:

- host/player Hall of Fame sort logic is normalized and shared semantically

## 7) Build order (monorepo-safe)

1. `packages/cb_models` (types + catalog)
2. `packages/cb_logic` (compute + persistence + queries)
3. `apps/host` (Hall of Fame + recap unlock surfaces)
4. `apps/player` (progress presentation + navigation)
5. docs update (`AGENT_CONTEXT.md`)

## 8) Verification checklist

### Package checks

- [x] Analyze/test `packages/cb_models`
- [x] Analyze/test `packages/cb_logic`
- [x] Analyze/test `apps/host`
- [x] Analyze/test `apps/player`

### Functional checks

- [x] Phase 0: every role resolves to either a placeholder or finalized definition
- [x] Phase 1: every role has Rookie/Pro/Legend + bonus definitions
- [x] Unlocks compute deterministically from the same game history
- [x] Legacy records load without crash/regression
- [x] Host + Player show consistent ranking semantics
- [x] Existing recap awards (`mvp`, `ghost`, etc.) still work

## 9) Open merge slots (for your other draft)

Use these sections to merge alternate details without conflict:

### Merge Slot A: Unlock rule formulas

- Add concrete thresholds/conditions per role + tier.

### Merge Slot B: Copywriting packs

- Add title/description variants by tone level.

### Merge Slot C: Cloud sync contract

- Add Firestore (or other backend) document shape and indexes.

### Merge Slot D: Seasonal resets

- Add season boundary logic, carry-over policy, and archival behavior.

## 10) Risks + mitigations

- **Risk:** name-based identity collisions in Hall of Fame
  - **Mitigation:** aggregate by stable player key; treat names as display-only
- **Risk:** role catalog drift breaks award mapping
  - **Mitigation:** startup validation that every role has definitions
- **Risk:** schema bloat from over-flexible rules
  - **Mitigation:** start with typed rule primitives, not freeform scripts
- **Risk:** host/player inconsistency
  - **Mitigation:** shared query + sort helpers in logic layer

## 11) Definition of done

### Phase 0 done (placeholder launch)

- [x] placeholder registry committed for all canonical roles
- [x] host/player Hall of Fame role cards render `Awards Coming Soon` for unresolved roles
- [x] legacy sessions still function
- [x] docs updated with extension instructions for new roles

### Phase 1 done (full role ladders)

- [x] award domain models and catalog committed
- [x] persistence computation + query paths implemented and tested
- [x] host/player Hall of Fame award views render from shared data
- [x] host/player Hall of Fame role/tier filters implemented
- [x] role-specific deterministic unlock profiles implemented
- [x] all canonical roles have Rookie/Pro/Legend + bonus definitions
- [x] existing recap awards (`mvp`, `ghost`, etc.) still function

## 12) Role workshop tracker (live, mergeable)

This section stores finalized role ladders from live workshop sessions.
Format follows the build-instructions companion and can be copied directly into catalog seed data.

Current rollout mode:

- Launch with placeholder cards first.
- For any role without finalized definitions, show exact UI copy: `Awards Coming Soon`.
- Add/edit/create role awards incrementally without schema changes.

### Role Intake: `wallflower` / `The Wallflower`

- Award 1
  Tier: `Rookie`
  Award ID: `wallflower_rookie_nosy_neighbor`
  Title: `Nosy Neighbor`
  Description: Peek at at least 2 successful night kills in a single game and survive to Day 2.
  Unlock Trigger (Deterministic): `killsObservedCount >= 2 AND survivedThroughDay >= 2`
  Difficulty (1-5): `1`
  Rarity: `common`
  Icon Key: `eye`
  Source: `Phosphor`
  License: `MIT`
  Attribution Needed: `no`

- Award 2
  Tier: `Pro`
  Award ID: `wallflower_pro_professional_snitch`
  Title: `Professional Snitch`
  Description: Observe 3 or more successful kills in one game while never being eliminated.
  Unlock Trigger (Deterministic): `killsObservedCount >= 3 AND isAliveAtGameEnd == true`
  Difficulty (1-5): `3`
  Rarity: `uncommon`
  Icon Key: `binoculars`
  Source: `Tabler`
  License: `MIT`
  Attribution Needed: `no`

- Award 3
  Tier: `Legend`
  Award ID: `wallflower_legend_night_shift_manager`
  Title: `Night Shift Manager`
  Description: Across any rolling 5 games, observe at least 8 successful kills and survive in at least 4 of those games.
  Unlock Trigger (Deterministic): `rolling5Games.killsObservedSum >= 8 AND rolling5Games.survivalCount >= 4`
  Difficulty (1-5): `5`
  Rarity: `rare`
  Icon Key: `surveillance-camera`
  Source: `Game-Icons`
  License: `CC BY 3.0`
  Attribution Needed: `yes`
  Attribution Text: `Icon by Delapouite via game-icons.net (CC BY 3.0)`

- Award 4
  Tier: `Bonus`
  Award ID: `wallflower_bonus_wrong_place_right_time`
  Title: `Wrong Place, Right Time`
  Description: Observe a kill on the same night you were targeted but survived due to protection.
  Unlock Trigger (Deterministic): `observedKillNight == protectedFromKillNight`
  Difficulty (1-5): `2`
  Rarity: `uncommon`
  Icon Key: `shield-check`
  Source: `Heroicons`
  License: `MIT`
  Attribution Needed: `no`

- Award 5
  Tier: `Bonus`
  Award ID: `wallflower_bonus_receipts`
  Title: `Receipts`
  Description: Observe at least 2 killers who are later eliminated by day vote in the same game.
  Unlock Trigger (Deterministic): `observedKillerEliminatedByDayVoteCount >= 2`
  Difficulty (1-5): `4`
  Rarity: `ultra`
  Icon Key: `clipboard-list`
  Source: `Tabler`
  License: `MIT`
  Attribution Needed: `no`

Notes:

- Required event fields: `nightActions`, `successfulKills`, `wallflowerPeekEvents`, `eliminationLog`, `protectionEvents`, `dayVoteOutcomes`.
- Edge cases: no-kill nights should not increment peek-kill counters; canceled kills should not count as observed successful kills.
- Anti-cheese constraint: only one progress increment per distinct kill event; repeated peeks on the same event do not stack.

## 13) Placeholder registry (Phase 0 launch)

Use this registry to mark roles that should display `Awards Coming Soon` until finalized.

Registry quality checks:

- Keep role IDs aligned with `role_catalog` / `RoleIds` constants.
- Current canonical expected count: `22` roles.
- CI/startup guard should fail if registry count drifts from canonical role count.

- `dealer` -> `Awards Coming Soon`
- `whore` -> `Awards Coming Soon`
- `silver_fox` -> `Awards Coming Soon`
- `party_animal` -> `Awards Coming Soon`
- `medic` -> `Awards Coming Soon`
- `bouncer` -> `Awards Coming Soon`
- `roofi` -> `Awards Coming Soon`
- `sober` -> `Awards Coming Soon`
- `wallflower` -> `Awards Coming Soon` (until draft set is approved for release)
- `ally_cat` -> `Awards Coming Soon`
- `minor` -> `Awards Coming Soon`
- `seasoned_drinker` -> `Awards Coming Soon`
- `lightweight` -> `Awards Coming Soon`
- `tea_spiller` -> `Awards Coming Soon`
- `predator` -> `Awards Coming Soon`
- `drama_queen` -> `Awards Coming Soon`
- `bartender` -> `Awards Coming Soon`
- `second_wind` -> `Awards Coming Soon`
- `messy_bitch` -> `Awards Coming Soon`
- `club_manager` -> `Awards Coming Soon`
- `clinger` -> `Awards Coming Soon`
- `creep` -> `Awards Coming Soon`

## 14) Incremental authoring protocol (post-launch)

When you are ready to activate a role:

1. Replace that role’s placeholder line with a full 5-award intake block.
2. Add icon metadata and attribution requirement per award.
3. Keep old placeholders for all other roles.
4. Release without needing a full catalog rewrite.

## 15) Scenario and all-star awards (future extension)

Support non-role awards without changing role ladder contracts:

- Add `awardScope` in model design:
  - `role` (default)
  - `scenario`
  - `all_star`
- Keep role ladders independent; scenario/all-star awards should be additive overlays.
- Examples for later authoring:
  - `all_star_clutch_chain` (multiple clutch votes in one session)
  - `all_star_survivor_streak` (consecutive game survivals)
  - `scenario_blood_bath_mvp` (top impact in offensive game style)
- UI behavior:
  - separate tab/filter for `All-Star Awards`
  - unresolved entries may also use `Awards Coming Soon` until configured

## 16) Merge contract (absorbed from companion)

When merging additional drafts into this file:

1. Keep Sections **1–11** as the canonical implementation backbone.
2. Merge new or conflicting ideas into **Section 9 (Open merge slots)** first.
3. Promote accepted content from Section 9 into Sections 4/5/6 only after de-duplication.
4. Do not change canonical role IDs away from `RoleIds` constants.
5. Never replace stable identifiers with display names.

If two drafts disagree, keep both variants in Slot A/B/C/D and mark one as `preferred`.

## 17) Award definition quality gate

Every award proposal must pass all checks before being marked finalized:

- **Role-specific:** behavior is tied to the role’s mechanics.
- **Observable:** can be derived from recorded game events/history.
- **Deterministic:** same history yields the same unlock result.
- **Non-overlapping:** does not duplicate another award trigger.
- **Tone-safe:** sarcastic/funny but gameplay-focused and non-personal.

Reject (or rework) any award that fails one of these checks.

## 18) Icon sourcing + attribution policy

Canonical source note:

- Use `AWARDS_NAME_ICON_CATALOG.md` as the source of truth for award titles and icon metadata (`title`, `iconKey`, `iconSource`, `iconLicense`).

Preferred icon source order:

1. MIT/Apache sets (Phosphor, Tabler, Heroicons, Material Symbols).
2. CC-BY sets (e.g., Game-Icons) only when thematic fit is significantly better.

Required metadata per award icon:

- `iconKey`
- `iconSource`
- `iconLicense`
- `iconAuthor` (if required)
- `attributionText` (especially for CC-BY)
- `iconUrl` (source link)

Do not mark a role as finalized without icon metadata completeness.

## 19) Canonical role completion checklist (merge gate)

A role is complete only when all checks are true:

- [x] 5+ awards defined for the role
- [x] all triggers deterministic and testable
- [x] no overlap with another role’s core ladder
- [x] icons assigned with license metadata
- [x] attribution requirement recorded (if any)

## 20) Workshop intake template (standard block)

Use this template when adding a new role intake block to Section 12:

### Role Intake: `<roleId>` / `<displayName>`

- Award 1
  Tier: `Rookie`
  Award ID: `roleid_rookie_01`
  Title:
  Description:
  Unlock Trigger (Deterministic):
  Difficulty (1-5): `1`
  Rarity: `common`
  Icon Key:
  Source:
  License:
  Attribution Needed: `no`

- Award 2
  Tier: `Pro`
  Award ID: `roleid_pro_01`
  Title:
  Description:
  Unlock Trigger (Deterministic):
  Difficulty (1-5): `3`
  Rarity: `uncommon`
  Icon Key:
  Source:
  License:
  Attribution Needed: `no`

- Award 3
  Tier: `Legend`
  Award ID: `roleid_legend_01`
  Title:
  Description:
  Unlock Trigger (Deterministic):
  Difficulty (1-5): `5`
  Rarity: `rare`
  Icon Key:
  Source:
  License:
  Attribution Needed: `no`

- Award 4
  Tier: `Bonus`
  Award ID: `roleid_bonus_01`
  Title:
  Description:
  Unlock Trigger (Deterministic):
  Difficulty (1-5): `2`
  Rarity: `uncommon`
  Icon Key:
  Source:
  License:
  Attribution Needed: `no`

- Award 5
  Tier: `Bonus`
  Award ID: `roleid_bonus_02`
  Title:
  Description:
  Unlock Trigger (Deterministic):
  Difficulty (1-5): `4`
  Rarity: `ultra`
  Icon Key:
  Source:
  License:
  Attribution Needed: `no`

Notes:

- Required event fields:
- Edge cases:
- Anti-cheese constraint:

## 21) Live collaboration protocol

During role workshops, follow this loop:

1. Select a canonical role ID.
2. Draft 5 awards (Rookie/Pro/Legend + 2 bonus).
3. Normalize triggers into deterministic rules.
4. Assign icon + license metadata.
5. Append finalized block to Section 12.

Repeat until all canonical roles are complete.
