# Game flow and role logic audit

This document audits the codebase against the intended play flow and role-specific mechanics. **Implemented** = logic and/or UI exists; **Partial** = partly done or needs verification; **Gap** = missing or not aligned.

---

## 1. Core flow

| Step | Status | Notes |
|------|--------|--------|
| Players join with code | ✅ Implemented | Join by code (cloud/local), claim player; `connect_screen`, `home_screen`, `cloud_player_bridge` / `player_bridge`. |
| Players wait in lobby | ✅ Implemented | Lobby phase; host and player lobby screens. |
| All players in lobby | ✅ Implemented | Host sees roster; min 4 players to start. |
| Host selects manual role assignments / automatic | ✅ Implemented | `GameStyle.manual` vs auto; `host_game_setup_screen`, `assignRole` / `autoAssignRoles`. |
| Start game | ✅ Implemented | `startGame()` in `game_provider`; setup script built; phase → setup. |
| Players receive their role and confirm | ✅ Implemented | Private state has role; player sees role reveal; `confirmRole` in session. |
| All players confirm role | ✅ Implemented | `roleConfirmedPlayerIds`; host can force-start. |
| Host selects start game | ✅ Implemented | Host advances from setup; `advancePhase()`, script feed. |
| Script feed fed to host and players | ✅ Implemented | `scriptQueue`, `currentStep`; host and player see steps; narration. |
| Role night actions pushed to character’s device | ✅ Implemented | Steps are role-scoped (`roleId`); player gets `currentStep` when it’s their role; actions via `handleInteraction`. |
| Choice recorded and displayed on host app | ✅ Implemented | `actionLog`; host sees actions; live intel / director commands. |
| Host presses next | ✅ Implemented | Host advances script index / phase. |
| Night resolution → morning phase | ✅ Implemented | `resolveNightActions`; phase → day; report and teasers. |
| Morning phase with spicy/clean recaps | ✅ Implemented | `lastNightReport` (host), `lastNightTeasers` (players); `RecapGenerator`; dual-track in `recap_generator`. |
| All actions recorded for stats | ✅ Implemented | `eventLog`, `gameHistory`; analytics / persistence; game records. |
| Next night, same format until win | ✅ Implemented | Phase loop night → day; `resolveDayVote`; win check in `game_resolution_logic`. |
| Win conditions met | ✅ Implemented | `WinResult`, phase → endGame; staff/animal/neutral wins. |

---

## 2. Role-specific mechanics

| Mechanic | Status | Notes |
|----------|--------|--------|
| **Rumour mill** | ✅ Implemented | `hasRumour` on players; Messy Bitch spreads rumour; win condition: all living have rumour + Messy Bitch alive (`game_resolution_logic`). |
| **Wallflower: method of seeing the murder recorded** | ✅ Implemented | `wallflower_observe_` step; host records PEEKED/not; `gawkedPlayerId`; private intel to wallflower; `game_provider` + `script_builder` + night resolution. |
| **Bartender alliances visualized on bartender devices** | ✅ Implemented | Bartender gets private messages with alliance intel; player app shows `_BartenderAlliancePanel` from `privateMessages[playerId]` when role is bartender (`game_screen`). |
| **Tea Spiller logic** | ✅ Implemented | `tea_spiller_reveal`, `tea_spiller_handler`; day resolution. |
| **Whore scapegoat setup at start of game** | ⚠️ Partial | Whore **picks scapegoat during night** (not setup). Scapegoat **deflection** is day-resolution. If “at start” means a **setup-phase** choice, add a whore setup step in `script_builder` (e.g. first night or a dedicated setup step). |
| **Whore scapegoat (deflection) implemented** | ✅ Implemented | `whoreDeflectionTargetId`; day resolution applies deflection on exile; `game_resolution_logic`. |
| **Second wind logic** | ✅ Implemented | `second_wind_handler`; `hasReviveToken`, `secondWindPendingConversion`. |
| **Clinger logic** | ✅ Implemented | `clinger_bond_handler`; `clingerPartnerId`; setup step; death-if-partner-dies. |
| **Creep inheritance logic** | ✅ Implemented | `creep_inheritance_handler`; creep picks target at setup; inherits on target death. |
| **Bouncer results on host and player** | ✅ Implemented | Bouncer gets private message; report to host (`addReport`); player sees intel in private messages; Ally Cat gets intercepted bouncer intel. |
| **Drama Queen: select two alive to swap on death; swapped players get secret alert** | ✅ Implemented | `drama_queen_swap`, `drama_queen_death_handler`; Drama Queen picks two at setup; on exile death, those two swap; **private messages** to swapped players: “You were swapped with X. Your new role is Y.” Consider adding “keep it secret” to that text. |
| **Sober: select one player each night to send home (exempt from kill/ability/action that night)** | ✅ Implemented | `sober_action`; `redirectedActions[targetId] = 'none'`, `protectedPlayerIds.add(targetId)`; target’s action blocked and protected. |
| **Roofie: paralyse at end of night → no talk or vote next day** | ✅ Implemented | `silencedDay` set in resolution; day vote and step handling check `silencedDay == dayCount`; player sees roofied dialog. |
| **Roofie on dealer: dealer can’t kill next night** | ✅ Implemented | `roofi_action`: if target is dealer (and only living dealer), `dealerAttacks` removed for that dealer; kill blocked. |
| **Club Manager: catalogue of identified roles, top secret** | ⚠️ Partial | Club Manager receives **private messages** per inspection (“Inspection complete: X is the Y”); `sightedByClubManager` on targets. Catalogue = history of those private messages. No dedicated “catalogue” UI yet; could add a Club Manager–only “Identified” view built from private messages or from `players.where(sightedByClubManager)`. |
| **Creep: if inherited role needs setup, setup on creep’s device after inherited role dies** | ✅ Implemented | `pendingCreepSetups` from resolution; `buildCreepInheritedSetupSteps`; creep setup steps queued in day script so creep gets steps on their device. |
| **Robust platform: players communicate with each other and host; send/receive tasks and choices** | ✅ Implemented | Bulletin/chat (host + players); actions to host via `actions` collection (cloud) or WebSocket; `currentStep` + `handleInteraction` for choices; private messages for role-specific intel. |
| **All actions displayed to host via private messages** | ✅ Implemented | Night/day resolution uses `addPrivateMessage` and `addReport`. Host sees **report** (mechanical truth) in feed/intel; **private messages** are per-player but host has **Live Intel** / “INTERCEPTED PRIVATE COMMS” in `night_action_intel_panel` and `private_messages_sheet` showing all `gameState.privateMessages`. |

---

## 3. Summary of gaps / follow-ups

1. **Whore scapegoat “at start of game”**  
   - If design is “whore chooses scapegoat in setup (before night 1)”, add a **whore setup step** in `ScriptBuilder.buildSetupScript` (similar to Clinger/Drama Queen).

2. **Drama Queen swapped players**  
   - Optional: add explicit “keep it secret” to the private message in `drama_queen_swap.dart`.

3. **Club Manager catalogue**  
   - Optional: add a dedicated “Identified roles” view for Club Manager (e.g. parse private messages or maintain a small “identified” list in state) so it’s a clear “top secret” catalogue.

4. **Host view of “all actions as private messages”**  
   - Host already sees full mechanical recap and intercepted private comms; if “all actions” should also appear in a single “private message stream” for the host, that could be a dedicated host-only feed that aggregates `actionLog` + report lines + private message summaries.

---

## 4. File reference (where to change things)

| Area | Primary files |
|------|----------------|
| Join, lobby, start game | `apps/player`: `connect_screen`, `home_screen`, `lobby_screen`; `apps/host`: `host_lobby_screen`, `host_game_setup_screen`; `game_provider.dart` |
| Script feed, steps | `script_builder.dart`, `scripting/step_key.dart`, `game_provider` (advancePhase, emitStepToFeed) |
| Role confirm | `session_provider.dart` (confirmRole, roleConfirmedPlayerIds); player `role_reveal_screen`, `game_screen` |
| Night/day resolution | `game_resolution_logic.dart`, `night_actions/`, `day_actions/resolution/` |
| Recaps | `recap_generator.dart`; host bulletin “NIGHT RECAP (HOST)”, player teasers |
| Wallflower | `script_builder` (wallflower_info, wallflower_observe), `game_provider` (wallflower_observe handling), `game_resolution_logic` (gawkedPlayerId) |
| Whore | `whore_action.dart`, `game_resolution_logic` (deflection), `game_provider` (whore_deflection step) |
| Bouncer | `bouncer_action.dart`; report + private to bouncer and Ally Cat |
| Club Manager | `club_manager_action.dart`; player private messages; optional catalogue UI in player app |
| Drama Queen | `drama_queen_swap.dart`, `drama_queen_death_handler`, `game_provider` (drama_queen_setup_), script_builder (Drama Queen setup step) |
| Sober / Roofie | `sober_action.dart`, `roofi_action.dart`; `game_resolution_logic` (silencedDay, protectedPlayerIds, redirectedActions) |
| Creep inheritance | `creep_inheritance_handler.dart`; `buildCreepInheritedSetupSteps` in script_builder |
| Host view of private messages | `night_action_intel_panel.dart`, `private_messages_sheet.dart`, `host_chat_view.dart`, `live_intel_panel.dart` |

---

**Last updated:** 2026-02-28
