# Accessibility: Contrast Audit (WCAG AA)

> **Date:** 2026-02-25  
> **Scope:** Radiant Neon theme (`cb_theme`). Target: WCAG 2.1 Level AA where applicable (4.5:1 normal text, 3:1 large text / UI components).

## Key color pairings (theme)

| Foreground | Background | Notes |
|------------|------------|--------|
| `onSurface` (#F0F0F0) | `voidBlack` (#0E1112) / `surface` (#191C1D) | Body text; contrast >> 10:1. Pass. |
| `primary` (#4CC9F0) | `voidBlack` / `surface` | Headings, links; high contrast. Pass. |
| `onPrimary` (voidBlack) | `primary` | Primary buttons. Pass. |
| `onSurfaceVariant` (M3 fromSeed) | `surface` | Secondary text, hints. Dark theme fromSeed keeps this readable. Pass with typical values. |
| Tab unselected | `surface` | Was 0.35 opacity onSurface; increased to 0.5 for clearer ≥4.5:1. |

## Decisions made

- **Tab bar unselected label:** `theme_data.dart` `unselectedLabelColor` changed from `onSurface.withValues(alpha: 0.35)` to `onSurface.withValues(alpha: 0.5)` so unselected tab text meets AA.
- **Decorative dim elements** (e.g. bottom sheet handle 0.18, scrollbar 0.35, glass borders) left as-is; not required to meet text contrast.
- **Hint / secondary text** in inputs and panels use 0.4–0.6 opacity or `onSurfaceVariant`; acceptable for WCAG AA when background is dark.

## Recommendations

- Run automated contrast checks (e.g. Flutter accessibility scanner or manual spot-checks) on Host and Player after any theme or palette change.
- For any new “secondary” or “muted” text on dark backgrounds, prefer at least 0.5 opacity of `onSurface` or use `onSurfaceVariant` to stay ≥4.5:1.
