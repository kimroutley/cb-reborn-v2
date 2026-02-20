# Player App Stabilization Plan

Now that the Host App is stabilized, we turn our attention to the Player App. This app shares many packages with the Host but has its own unique UI challenges aimed at mobile usage.

> Status refresh (Feb 17, 2026): analysis/tests are passing, player web build + Firebase hosting deploy succeeded, and join/registration flow has been stabilized across local/cloud transports.

## 1. Initial Analysis

- [x] Run `flutter analyze apps/player` to identify compilation errors.
- [x] List all immediate breakages (missing imports, API changes in shared packages).

## 2. Shared Logic Sync

- [x] Ensure `cb_models` and `cb_logic` changes made during Host refactor are correctly utilized in Player.
- [x] Fix any `GamePhase` or `GameState` API mismatches (e.g., `currentPhase` vs `phase`).

## 3. User Interface & Theme Migration (Material 3)

- [x] **Scan for `CBColors`**: Replace hardcoded neon colors with `Theme.of(context).colorScheme` equivalents.
- [x] **Scan for `withOpacity`**: Replace with `Color.withValues(alpha: ...)`.
- [x] **Typography**: Ensure `Theme.of(context).textTheme` is used instead of manual `TextStyle` where possible.

## 4. Widget Stabilization

- [x] Check core player widgets (`PlayerCard`, `ActionSheet`, `VotePanel`) for robustness.
- [x] Ensure `ConsumerWidget` usage is correct for Riverpod 2.0.

## 5. Deployment Verification

- [x] Verify `firebase.json` and web/mobile build configurations (if accessible).
