# Club Blackout Reborn: The Design Bible

> **Version:** 2.0 (Radiant Neon Overhaul)
> **Date:** February 19, 2026
> **Scope:** All UI/UX elements for Host and Player applications.

This document serves as the **single source of truth** for the visual identity of Club Blackout Reborn. It defines the "Radiant Neon" aesthetic—a fusion of high-tech cyberpunk terminals and underground nightclub vibes.

---

## 1. Core Philosophy: "The Radiant Neon Terminal"

The user interface should feel like a piece of high-end hardware found in a VIP lounge of a cyberpunk nightclub.

*   **Dark-First**: The canvas is always deep, void-like black. We do not use white backgrounds.
*   **Light is Data**: Information glows. Active elements emit light; inactive elements fade into the dark.
*   **Glass & Depth**: Surfaces are semi-transparent ("frosted glass"), creating depth and context.
*   **Tactile Feedback**: Every interaction has weight. Haptics and animations confirm every tap.

---

## 2. Color System (`CBColors`)

We use a high-contrast neon palette against a void background.

### The Void (Backgrounds)
*   **`voidBlack`** (`#0E1112`): The infinite background.
*   **`surface`** (`#191C1D`): The base for cards/panels before glass effects.

### The Neons (Action & State)
These colors define the team alliances and interactive states.

| Role | Name | Hex | Usage |
| :--- | :--- | :--- | :--- |
| **Primary** | `radiantTurquoise` | `#4CC9F0` | **Club Staff**, Primary Actions, Active States. |
| **Secondary** | `radiantPink` | `#F72585` | **Party Animals**, Destructive Actions, Highlights. |
| **Tertiary** | `neonPurple` | `#B5179E` | **System**, AI Narration, "God Mode" elements. |
| **Error/Kill** | `errorRed` | `#FF0033` | Eliminations, Errors, "Dead Pool" tracking. |
| **Success** | `matrixGreen` | `#39FF14` | Confirmations, "Alive" status. |
| **Warning** | `alertOrange` | `#FF9900` | Notifications, Shadow Bans. |

### The Shimmer (Prismatic)
Used for high-value items (`isPrismatic: true`).
*   **Gradient**: Linear gradient of Primary + Secondary + Tertiary with rotation.

---

## 3. Typography (`CBTypography`)

All text is rendered in **Roboto** (Body) or **Roboto Condensed** (Headers).

*   **Headlines**: `Roboto Condensed`, FontWeight.w900, All Caps.
    *   *Effect:* Always apply `CBColors.textGlow` shadow to major headers.
*   **Body**: `Roboto`, FontWeight.w400/w500.
    *   *Color:* `ghostWhite` (`#F0F0F0`) or `onSurface` with 70% opacity.
*   **Data/Code**: `Roboto Mono`. Used for join codes, logs, and technical specs.

### Text Glow Rule
Do not use flat colors for large text.
```dart
style: textTheme.headlineSmall!.copyWith(
  color: scheme.primary,
  shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
)
```

---

## 4. Component Library (The "Legos")

All development MUST use widgets from `packages/cb_theme`. Do not build raw Material widgets.

### 4.1. Containers

#### `CBPrismScaffold`
The root of every screen.
*   **Features:** Automates the "Neon Background" (dynamic seed), SafeArea, and AppBar styling.
*   **Usage:** Replace `Scaffold` with `CBPrismScaffold`.

#### `CBGlassTile`
The primary content container.
*   **Visuals:** 
    *   Blur: `sigmaX/Y: 10.0`
    *   Fill: `surface.withValues(alpha: 0.15)`
    *   Border: `white.withValues(alpha: 0.1)`
*   **Props:**
    *   `isPrismatic`: Enables the animated oil-slick shader. Use for "Heroes", "Winners", or "Active Action" cards.
    *   `isSelected`: Adds a glowing primary border.

#### `CBPanel`
Used for grouping related fields (e.g., Settings sections, Form groups).
*   **Visuals:** Darker background than GlassTile, explicitly bordered.

### 4.2. Inputs & Actions

#### `CBPrimaryButton` / `CBGhostButton`
*   **Primary:** Filled, glowing background. Use for "Commit", "Vote", "Next".
*   **Ghost:** Outlined, transparent. Use for "Cancel", "Back", "Secondary Options".

#### `CBTextField`
*   **Style:** Filled Glass (`alpha: 0.15`).
*   **Border:** Glows with `primary` color on focus.
*   **Usage:** Join codes, Profile names, Director payloads.

### 4.3. The Feed (`CBMessageBubble`)

The game feed mimics a secure messaging app.

*   **System Messages:** Centered "Pills". Low emphasis. Used for Phase changes ("NIGHT 1").
*   **Narrative:** Centered, bold text. Medium emphasis. Used for story beats.
*   **Standard Chat:** Left/Right bubbles.
    *   **Host/Action:** Right aligned.
    *   **Player/Response:** Left aligned.
*   **Grouping:** Bubbles automatically adjust corner radii to visually group consecutive messages from the same sender.

### 4.4. Headers & Separators

*   **`CBSectionHeader`:** A boxed header with an icon and optional badge count. Use to divide dashboard sections.
*   **`CBFeedSeparator`:** A sleek line-and-text divider. Use in scrolling lists to denote time or context shifts.

---

## 5. Interaction Design

### 5.1. The "Biometric" Hold
For critical reveals (Role Card) or destructive actions (Delete Game).
*   **Gesture:** Long Press.
*   **Feedback:**
    *   **Visual:** `CircularProgressIndicator` fills up.
    *   **Haptic:** `HapticFeedback.lightImpact()` on start, `heavyImpact()` on completion.

### 5.2. Haptics (`HapticService`)
We rely heavily on haptics to sell the "physical" terminal feel.
*   **Tap:** `selectionClick()` (Standard buttons).
*   **Success:** `mediumImpact()` (Vote cast, Save complete).
*   **Error:** `vibrate()` (Invalid code, Action failed).
*   **Phase Change:** `heavyImpact()` (Night Falls).

---

## 6. Layout & Spacing

*   **Grid:** 4px baseline.
*   **Standard Padding (`CBInsets`):**
    *   Screen Edge: `16px` or `24px`.
    *   Card Internal: `16px`.
    *   Element Gap: `8px`, `12px`, `16px`.
*   **Corner Radius (`CBRadius`):**
    *   Standard Card: `16px`.
    *   Buttons: `12px`.
    *   Bubbles: `20px`.

---

## 7. Implementation Checklist

Before merging any UI code:

1.  [ ] **Is it Glass?** (Use `CBGlassTile` or `CBPanel` instead of `Card`).
2.  [ ] **Is it Glowing?** (Check headers and primary actions for shadows).
3.  [ ] **Is it Haptic?** (Add `HapticService` calls to callbacks).
4.  [ ] **Is it Themed?** (Use `Theme.of(context).colorScheme`, NEVER hardcoded `Colors.blue`).
5.  [ ] **Is the Background Void?** (Ensure `CBPrismScaffold` is the parent).

---

**"We don't just play the game. We inhabit the terminal."**
