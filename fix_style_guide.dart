import 'dart:io';

void main() {
  final content = r'''# Club Blackout Reborn: UI Style Guide

> **Last Updated:** February 12, 2026
> **Source of Truth:** This guide reflects the actual `cb_theme` package implementation.

---

## 0. Guiding Principles

This style guide defines the **"Radiant Neon"** aesthetic — the visual identity of Club Blackout Reborn. The UI must be modern, immersive, and evoke a sense of vibrant, pulsating energy. It's a fusion of neo-noir nightclub darkness with the electrifying glow of a digital realm.

-   **Dark-first & Dynamic:** The core is a deep, void-like black, providing the perfect canvas for our neon colors to shine. Surfaces are not just static; they breathe and radiate with subtle animations.
-   **Glowing, Breathing Spectrums:** The primary colors are not flat. They are gradients and animated effects of **Neon Pink** and **Turquoise**, creating a living, breathing interface.
-   **Consistent & Thematic:** All UI elements MUST derive their style from the `cb_theme` package. This ensures a cohesive and immersive experience across both the host and player apps.

---

## 1. Color System

The color system is built around a fixed, high-contrast palette of glowing neons against a dark void.

### Primary Palette

| Role | CB Name | Hex/Gradient | Usage |
|:-----|:--------|:----|:------|
| `primary` | `radiantTurquoise` | `linear-gradient(to right, #00F5A0, #00D9E0)` | Primary actions, highlights, focus indicators, Staff team. |
| `secondary` | `radiantPink` | `linear-gradient(to right, #F700FF, #E0007F)` | Secondary actions, accents, destructive actions, Party Animal team. |
| `surface` | `voidBlack` | `#0A0A0A` | Base background for all screens and surfaces. |
| `onSurface` | `ghostWhite` | `#F0F0F0` | Default text color. |
| `onSurfaceVariant` | `coolGrey` | `#A0A0B0` | Secondary text, subtitles, disabled text. |

### Semantic & Game Colors

| Purpose | Name | Hex | Usage |
|:--------|:-----|:----|:------|
| Success | `matrixGreen` | `#00FF41` | Success feedback, confirmation. |
| Warning | `alertOrange` | `#FFAB40` | Warnings, special states. |
| Error | `errorRed` | `#FF4040` | Error messages and states. |
| Dead | `deadGrey` | `#606060` | Eliminated players, disabled states. |

### Usage Rule

Always use the defined `CBColors` from the `cb_theme` package. Do not hardcode hex values. The theme is fixed and does not adapt to system colors to maintain its strong identity.

### 1.1 The Shimmer Palette (Biorefraction)

The Shimmer introduces a biorefractive quality to the visual language, representing mutation or anomaly. It uses a darker, iridescent palette that feels alien compared to the clean neons.

| Name | Hex | Usage |
|:-----|:----|:------|
| `deepSwamp` | `#0A1412` | Dark, organic background base for shimmer components. |
| `magentaShift` | `#9900FF` | Primary shimmer accent, shifting towards purple. |
| `cyanRefract` | `#00FFCC` | High-light refraction color for edges and active states. |

---

## 2. Glows and Breathing Effects

The "Radiant Neon" theme comes alive through animated glows and subtle breathing effects. These are not just decorative; they provide feedback and guide the user's attention.

-   **Breathing Glow:** Buttons and interactive elements should have a subtle, slow "breathing" glow effect that intensifies on hover or focus. This is achieved using animated `BoxShadow`s with pulsating blur radius and color opacity.
-   **Radiating Spectrums:** Backgrounds and large surfaces can feature slow-moving, large-scale radial gradients of pink and turquoise, giving the impression of light radiating from an unseen source.
-   **Neon Borders:** Key containers and focused elements use a 1.5px border colored with the `radiantTurquoise` or `radiantPink` gradient.

---

## 3. Typography

All text MUST use a style defined in `CBTypography`.

-   **Roboto Condensed** — Headers/display text. Bold, impactful, and often styled with a neon glow.
-   **Roboto** — Body/labels/info. Clean, modern, and highly readable.

| Style | Font | Size/Weight | Usage |
|:------|:-----|:------------|:------|
| `displayLarge` | Roboto Condensed | 40/bold | Major phase titles ("NIGHT FALLS"), with a strong neon glow. |
| `displayMedium` | Roboto Condensed | 28/bold | Large headlines ("ELIMINATED"), with a neon glow. |
| `headlineLarge` | Roboto Condensed | 24/bold | Screen-level headings. |
| `labelLarge` | Roboto | 16/w700 | Primary button text. |
| `bodyLarge` | Roboto | 16/w400 | Main content text. |
| `code` | Roboto Mono | 32/w700 | Join codes (`NEON-XXXX`) with a distinct, monospaced look. |

### Glow Effect

Display and headline styles should incorporate a subtle text shadow to create a neon glow effect.
```dart
shadows: [Shadow(color: CBColors.radiantTurquoise.withOpacity(0.5), blurRadius: 8.0)]
```

---

## 4. Spacing & Layout

A consistent 4px grid system is used.

-   **Standard Padding:** `16px` for screen edges.
-   **Component Padding:** `24px` inside dialogs and cards for a more spacious feel.
-   **Gaps:** `12px` or `16px` between components.

---

## 5. Component Styling

All UI is constructed from the `cb_theme` widget library.

### `CBPrismScaffold`
-   **Purpose:** The primary scaffold wrapper for all screens.
-   **Style:** Includes `CBNeonBackground`, `extendBodyBehindAppBar`, themed AppBar with transparency.

### `CBPanel`
-   **Purpose:** The primary container for grouping related content.
-   **Style:** Rounded corners (16px), `1px` border, dark surface background, `16px` internal padding. The `borderColor` SHOULD match context: `primary` for neutral, `secondary` for voting, `matrixGreen` for intel.

### `CBTextField`
-   **Style:** `OutlineInputBorder` with `12px` border radius. Border color indicates state:
    -   **Enabled:** radiantTurquoise (primary)
    -   **Focused:** radiantPink (secondary)
    -   **Error:** errorRed

### 5.1 CBGlassTile

`CBGlassTile` is the fundamental building block for list items, interactive cards, and status displays.

-   **Glassmorphism:** It uses a semi-transparent background with a subtle border to create a "glass" effect over the dark void background.
-   **Effect:** `BoxDecoration` with `voidBlack` at reduced opacity and a border of `coolGrey` (or thematic color).

#### properties: `isPrismatic` (The Oil Slick Effect)

When `isPrismatic: true` is set on a `CBGlassTile`, the component enters "The Shimmer" mode.

-   **Visuals:** Instead of the standard glass background, the tile renders a dynamic gradient using `deepSwamp`, `magentaShift`, and `cyanRefract`.
-   **Animation:** This gradient should slowly shift or rotate, creating an "Oil Slick" effect that implies an unstable, biorefractive surface.
-   **Usage:** Use this for items affected by glitches, anomalies, or rare "Shiny" statuses.

---

## 6. Iconography

-   **Source:** Standard Material Icons (`Icons.*`), prefer rounded variants (`Icons.*_rounded`).
-   **Standard Size:** `24px`.
-   **Small Size:** `16px`–`18px` inside buttons or list items.
-   **Large Size:** `64px` for status overlays.
-   **Color:** Contextual — derive from theme or match surrounding text.

---

## 7. Animation & Motion

Animations should be subtle and functional.

-   **Micro-interactions:** `250ms` (color changes, hover states).
-   **Screen transitions:** `400ms` for major state changes.
-   **Standard Curve:** `Curves.easeInOut`.
-   **Recommended Widgets:**
    -   `AnimatedContainer` — For color, border, padding changes.
    -   `AnimatedSwitcher` — Cross-fade between states (e.g., waiting vs. voting).
    -   `FadeIn` — Stagger list item appearance (300ms fade + slide).
-   **Page Transitions (`CBPageTransitions`):** `slideFromRight`, `slideFromBottom`, `fadeAndScale`, `instant`.

---

## 8. Haptic Feedback (`HapticService`)

Game events trigger contextual haptic patterns:

| Pattern | Usage |
|:--------|:------|
| `success` | Positive game events |
| `error` | Errors, eliminations |
| `nightAction` | Night action prompts |
| `voteCast` | Vote submission |
| `alertDispatch` | Bulletin dispatch |
| `eyesOpen` | Role wake-up |
| `eyesClosed` | Role sleep |
| `selection` | UI selection feedback |
| `medium` | General medium haptic |

---

## 9. Dynamic Theming

Both apps wrap in `DynamicColorBuilder` to support device-specific color tinting:

```dart
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    final scheme = CBTheme.buildColorScheme(
      darkDynamic?.primary ?? CBTheme.defaultSeedColor,
    );
    return MaterialApp(
      theme: CBTheme.buildTheme(scheme),
      // ...
    );
  },
);
```

This allows the neon palette to subtly adapt to the device's Material You colors while maintaining the core identity.
''';

  File(r'c:\Club Blackout Reborn\STYLE_GUIDE.md').writeAsStringSync(content);
}
