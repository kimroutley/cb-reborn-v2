# Host App UI Polish Recommendations

> **Date:** February 22, 2026  
> **Status:** Proposed  
> **Target:** Host Dashboard & Group Messaging Platform (The Feed)

This document outlines stylistic recommendations to further elevate the "God Mode" feel of the host app while maintaining a seamless tie-in with the player app's "Radiant Neon" aesthetic.

---

## 1. Tactical Information Density
While the player app prioritizes large, immersive chat bubbles, the host needs a "Command Center" view that favors information density.

*   **Recommendation**: Implement a **"Tactical Feed"** mode for the host dashboard. This would use a version of `CBMessageBubble` with reduced vertical padding and a slightly smaller font size for body text.
*   **Impact**: Allows the host to see 20–30% more history on a tablet or desktop screen without losing the high-tech terminal feel.

## 2. Live Metadata Layering
The host should be able to see the status of a player directly on their chat messages.

*   **Recommendation**: Use the existing `MiniTag` widget (from `roster_tile.dart`) to overlay tiny, semi-transparent status indicators on chat bubbles.
*   **Example**: If a player who is currently "Shadow Banned" sends a message, their bubble in the host feed should have a tiny `MiniTag(text: 'GHOSTED', color: scheme.tertiary)` attached to the corner. This provides instant tactical context without switching tabs.

## 3. The "Prismatic" Authority
The host's own system messages and narrative beats should feel more "physical" and authoritative.

*   **Recommendation**: Use the `isPrismatic: true` property on `CBGlassTile` for any system-wide announcements or phase change dividers.
*   **Visual Hook**: When the host triggers a "System Glitch" or "Neon Flicker," the corresponding message in the feed should pulse with a `matrixGreen` or `radiantPink` glow and trigger a `HapticService.heavyImpact()`.

## 4. Direct Action Integration
The feed should be more than just a log; it should be an interactive control surface.

*   **Recommendation**: Enable **"Message Context Actions."** Tapping a player's message in the host feed should open a themed bottom sheet (using `showThemedBottomSheet`) with quick-access God Mode controls like **Sin Bin**, **Mute**, or **View Role**.
*   **Impact**: Allows for management of the room directly from the flow of the conversation.

## 5. Narrator-Specific Accents
Since the host can choose different AI Narration personalities, the feed should reflect that choice.

*   **Recommendation**: Apply a subtle color-shift to the narrative bubbles based on the active personality.
*   **Example**:
    *   **"The Ice Queen"**: Colder `radiantTurquoise` glow.
    *   **"Protocol 9"**: Corrupted `neonPurple` tertiary color with a subtle "glitch" jitter animation on the text.

## 6. Enhanced Phase Dividers
Phase changes are the most important narrative shifts in the game.

*   **Recommendation**: Enhance the `CBFeedSeparator` to be more cinematic.
*   **Visual Hook**: Instead of a simple line, use a wide glass panel that spans the feed, utilizing the `radiantTurquoise` (Day) or `neonPurple` (Night) colors with the `CBTypography.headlineSmall` style and a `CBColors.textGlow` effect.

---

## Component Mapping Summary

| Element | Recommendation | Component |
| :--- | :--- | :--- |
| **System Alerts** | Use `isPrismatic: true` for "God Mode" messages. | `CBGlassTile` |
| **Player Context** | Attach status indicators to chat bubbles. | `MiniTag` |
| **Narrative** | Color-code based on the selected AI Personality. | `CBMessageBubble` |
| **History** | Increase density for tablet/desktop views. | `CBMessageBubble` |