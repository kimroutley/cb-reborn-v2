import 'dart:io';

void main() async {
  final file = File(r'c:\Club Blackout Reborn\STYLE_GUIDE.md');
  if (!await file.exists()) {
    print('File not found');
    return;
  }
  final lines = await file.readAsLines();

  // Find the index of "## 5. Component Styling"
  // The grep said line 102, so index 101 approx.
  final cutIndex = lines.indexWhere(
    (line) => line.trim() == '## 5. Component Styling',
  );

  if (cutIndex == -1) {
    print('Could not find split point');
    return;
  }

  final head = lines.sublist(0, cutIndex).join('\n');

  final tail = r'''
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

  await file.writeAsString(head + '\n' + tail);
}
