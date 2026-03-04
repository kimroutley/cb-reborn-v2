# Club Blackout Reborn: The Design Bible

> **Version:** 2.1 (Radiant Neon Overhaul - Production Spec)
> **Date:** March 03, 2026
> **Scope:** All UI/UX elements for Host and Player applications.

This document serves as the **single source of truth** for the visual identity of Club Blackout Reborn. It defines the "Radiant Neon" aesthetic—a fusion of high-fidelity cyberpunk terminals and underground nightclub vibes.

---

## 1. Core Philosophy: "The Void & The Glow"

The user interface should feel like a piece of high-end hardware found in a VIP lounge of a cyberpunk nightclub.

*   **Void Black (Depth)**: Backgrounds are non-negotiable `#0E1112`. This creates infinite contrast for glowing elements. Do not use white or light-grey backgrounds.
*   **Light is Data**: Information glows. Active elements emit light; inactive elements fade into the dark.
*   **Glass & Depth**: Surfaces are semi-transparent ("frosted glass"), creating depth and context.
*   **Tactile Feedback**: every interaction has weight. Haptics and animations confirm every tap.

---

## 2. Technical Token System

### 2.1. Color Palette (`CBColors`)

We use a high-contrast neon palette against a void background. Use `Theme.of(context).colorScheme` primarily, fallback to `CBColors` for specific effects.

| Tier | Name | Hex | Usage |
| :--- | :--- | :--- | :--- |
| **Primary** | `radiantTurquoise` | `#4CC9F0` | **Club Staff**, Primary CTA, Connectivity, Active States. |
| **Secondary** | `radiantPink` | `#F72585` | **Party Animals**, Destructive Actions, Highlights. |
| **Tertiary** | `neonPurple` | `#B5179E` | **System Intelligence**, AI Narration, Overlays. |
| **Success** | `matrixGreen` | `#39FF14` | Confirmation, Survival, "Alive" state indicators. |
| **Error** | `errorRed` | `#FF0033` | Elimination, "Dead Pool" tracking, System Failure. |
| **Warning** | `alertOrange` | `#FF9900` | Notifications, Shadow Bans, Restricted states. |

**The Shimmer Rule**: Use `CBColors.oilSlickGradient` or `CBGlassTile(isPrismatic: true)` for high-value items like Winners, Heroes, or active gameplay actions.

### 2.2. Spacing & Layout (`CBSpace` / `CBInsets`)

*   **Baseline**: 4px grid.
*   **Tokens**:
    *   `CBSpace.x1` (4px), `x2` (8px), `x3` (12px), `x4` (16px), `x6` (24px), `x8` (32px), `x12` (48px).
*   **Insets**:
    *   **`CBInsets.screen`**: `16px` all sides (Standard edge padding).
    *   **`CBInsets.panel`**: `24px` all sides (Spacious content blocks).
    *   **`CBInsets.sheet`**: Custom asymmetrical padding for Bottom Sheets.

### 2.3. Radii (`CBRadius`)

*   **`xs` (8px)**: Small chips, mini-tags, status badges.
*   **`sm` (12px)**: Buttons, context menus, input fields.
*   **`md` (16px)**: Standard panels, frosted containers.
*   **`lg` (24px)**: High-impact glass tiles, Main Roster cards (Squircle vibe).
*   **`dialog` (28px)**: Main modals and persistent bottom sheets.

---

## 3. Typography (`CBTypography`)

All text is rendered in **Roboto** (Body) or **Roboto Condensed** (Headers).

*   **Headers (Headline/Display)**: `Roboto Condensed`, FontWeight.w900, All-Caps.
    *   **Constraint**: Must apply `CBColors.textGlow(color, intensity: 0.4-0.6)` to all major headers.
*   **Labels/UI Elements**: `Roboto`, All-Caps, FontWeight.w700-w900.
*   **Body**: `Roboto`, FontWeight.w400-w600.
    *   *Color:* `onSurface` (Ghost White) with 70-90% opacity.
*   **Data/Code**: `Roboto Mono`. Used for join codes, logs, and technical metrics.

---

## 4. Component Library (The "Legos")

All development MUST use widgets from `packages/cb_theme`. Do not build raw Material widgets.

### 4.1. Scaffolding: `CBPrismScaffold`
The root of every user-facing screen.
*   **Features**: Automates the dynamic neon background, SafeArea, and AppBar styling.
*   **Usage**: Replace `Scaffold` with `CBPrismScaffold`.

### 4.2. Containment
*   **`CBGlassTile`**: The primary interactive container. (Frosted blur: 10, Border: 1px low-alpha white).
*   **`CBPanel`**: For grouping logic or non-frosted form sections. (Darker background, explicit border).
*   **Note**: Standard Flutter `Card` widgets are prohibited.

### 4.3. Interactive Elements
*   **`CBPrimaryButton`**: Filled, glowing button for "Commit", "Start", "Next".
*   **`CBGhostButton`**: Outlined, transparent button for "Cancel", "Back", "Secondary".
*   **`CBTextField`**: Filled glass input with glowing focus borders.

---

## 5. Interaction Mechanics

### 5.1. Haptics (`HapticService`)
We rely on tactile feedback to sell the "Hardware Terminal" feel.
*   **Selection**: `selectionClick()` - Tabs, avatar chips, simple toggles.
*   **Light**: `lightImpact()` - Menu navigation, data sync, side-bars.
*   **Medium**: `mediumImpact()` - Message sent, Vote cast, Identity confirmed.
*   **Heavy**: `heavyImpact()` - Start game, Phase transition (Night Falls), Elimination.

### 5.2. Motion (`CBMotion`)
*   **Micro (250ms)**: Component-level pop/scale animations.
*   **Transition (400ms)**: Page routes and sliding panels.
*   **Curve**: Always use `emphasizedCurve` (`Curves.easeOutCubic`) for high-performance feel.

---

## 6. Feed & Security Protocol

### 6.1. Messaging Aesthetics
*   **System Messages**: Centered pills using `Secondary` (Pink).
*   **AI Narration**: High-fidelity blocks using `Tertiary` (Purple).
*   **Public Chat**: `Primary` (Turquoise) for outgoing, `onSurface` for incoming.

### 6.2. Information Hierarchy
*   **Classification**: Host-only messages must be tagged with `SPICY` (Red) or `CLASSIFIED` (Orange) mini-tags.
*   **Sync**: Use `CBPhaseOverlay` (pulsing vignette) to denote Night/Day states consistently in both apps.

---

**"We don't just play the game. We inhabit the terminal."**
