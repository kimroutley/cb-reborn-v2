# Release Handoff Report - 2026-02-19

> **Status:** Release Candidate (RC-1)
> **Focus:** UI Polish ("Radiant Neon"), Narrative Feed Overhaul, Role Mechanics Audit, Host/Player Onboarding

This document summarizes the extensive UI/UX polish and logic refactors completed today. Use this to orient yourself before starting new tasks.

---

## 1. Major UI Overhaul ("Radiant Neon")

The entire application (Host & Player) has been visually aligned with the `cb_theme` "Radiant Neon" design system.

### Key Components Upgraded
*   **`CBPrismScaffold`**: All screens now use this shared scaffold with the dynamic background seed.
*   **`CBGlassTile` & `CBPanel`**: Replaced standard cards/containers with glassmorphism variants. `isPrismatic: true` is used for high-value items (e.g., active bets, save slots).
*   **`CBMessageBubble`**: Completely rewritten to support a "Messaging App" aesthetic.
    *   **System/Narrative:** Centered, pill-shaped markers.
    *   **Chat/Action:** Standard left/right bubbles with dynamic grouping (top/middle/bottom corners).
    *   **Avatar Integration:** Avatars are now aligned with the message row.
*   **`CBTextField`**: Default style is now "filled glass" with glowing borders on focus.

### Screen-Specific Polish
*   **Player App**:
    *   **Lobby:** New glassmorphism bottom bar for status.
    *   **Game Terminal:** Split into "History Feed" (top) and "Action Bar" (bottom, glass overlay).
    *   **Biometric Header:** "Hold to Reveal" now features a blurred glass effect + breathing animation.
    *   **Ghost Lounge:** dedicated `CBPrismScaffold` with a high-fidelity Dead Pool betting panel.
*   **Host App**:
    *   **Dashboard:** "God Mode" and "Director Commands" are now high-stakes terminal interfaces with `CBGlassTile` buttons.
    *   **Feed:** Auto-grouped messages with `CBFeedSeparator` for phase changes.
    *   **Lobby:** Interactive player chips for rename/merge/eject actions.

---

## 2. Logic & Scripting Refactor (`cb_logic`)

The game script engine was refactored to support the new UI and fix critical flow issues.

*   **Feed De-duplication**: The `ScriptBuilder` now tracks consecutive actions by the same role.
    *   *Result:* Narrative ("Dealers, wake up...") plays **once**. Subsequent players get a clean prompt without repetitive text.
*   **Instruction Clarity**: Split `readAloudText` (Host narrative) from `instructionText` (Player imperative command).
    *   *Example:* Host sees "Ask the medic...", Player sees "SELECT A PLAYER TO SAVE".
*   **Host-Mediated Actions**:
    *   **Second Wind**: Converted to a Host-only input (`roleId: null`). The Host asks the Dealers verbally and inputs the choice (Convert/Execute) to prevent blocking on a specific device.
    *   **Wallflower**: "Host Observation" step is inserted *after* the last Dealer action to preserve narrative flow.
*   **Action Log Hardening**: Fixed a bug in `GameProvider` where special steps (Second Wind, Wallflower) executed logic but failed to update `actionLog`, causing `advancePhase` to stall.

---

## 3. Onboarding & First-Run Experience

New "Cold Open" screens were added to set the mood immediately.

*   **Intro Screens**:
    *   **Host**: "Command the Night" splash with admin iconography.
    *   **Player**: "Survive the Night" splash with suspenseful copy.
*   **Persistence**: Uses `SharedPreferences` to show these screens (and the subsequent "Guide" dialogs) only once per install.

---

## 4. Pending / Next Steps

*   **Validation**: The new `CBMessageBubble` grouping logic needs visual verification on a real device with varying text lengths.
*   **Cloud Sync**: Verify that the `roleId: null` Host actions (Second Wind) correctly propagate via Firestore/WebSocket without expecting a player ACK.
*   **Audio**: The "Radiant Neon" UI implies a certain soundscape. Ensuring `SoundService` triggers match the new visual intensity (e.g., prism shimmer = subtle hum?) is a potential polish item.

---

**Codebase State**: Stable. Analysis clean. Tests passing (logic).
**Design System**: `packages/cb_theme` is the single source of truth. Do not hardcode colors in apps.
