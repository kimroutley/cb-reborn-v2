# Player App Stabilization Plan

Now that the Host App is stabilized, we turn our attention to the Player App. This app shares many packages with the Host but has its own unique UI challenges aimed at mobile usage.

## 1. Initial Analysis
- [ ] Run `flutter analyze apps/player` to identify compilation errors.
- [ ] List all immediate breakages (missing imports, API changes in shared packages).

## 2. Shared Logic Sync
- [ ] Ensure `cb_models` and `cb_logic` changes made during Host refactor are correctly utilized in Player.
- [ ] Fix any `GamePhase` or `GameState` API mismatches (e.g., `currentPhase` vs `phase`).

## 3. User Interface & Theme Migration (Material 3)
- [ ] **Scan for `CBColors`**: Replace hardcoded neon colors with `Theme.of(context).colorScheme` equivalents.
- [ ] **Scan for `withOpacity`**: Replace with `Color.withValues(alpha: ...)`.
- [ ] **Typography**: Ensure `Theme.of(context).textTheme` is used instead of manual `TextStyle` where possible.

## 4. Widget Stabilization
- [ ] Check core player widgets (`PlayerCard`, `ActionSheet`, `VotePanel`) for robustness.
- [ ] Ensure `ConsumerWidget` usage is correct for Riverpod 2.0.

## 5. Deployment Verification
- [ ] Verify `firebase.json` and web/mobile build configurations (if accessible).
