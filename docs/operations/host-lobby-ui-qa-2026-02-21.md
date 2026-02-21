# Host Lobby UI QA Checklist + Log (2026-02-21)

## Scope

This checklist validates the host lobby polish pass completed on 2026-02-21:

- Visual hierarchy and spacing rhythm updates
- Join beacon UX improvements (copy code/link, expanded QR modal)
- Bottom action tools polish (readiness status + functional start gating)
- Micro-motion behavior (status transitions and subtle readiness motion)

## Automated verification completed

- Command: `flutter analyze .` (from `apps/host`)
- Result: ✅ No issues found
- Last run: 2026-02-21

## Automated communication verification completed (Host ↔ Player)

These checks validate bridge/message paths after the cloud-link robustness patch:

- `apps/player`
  - `flutter test test/player_bridge_test.dart test/active_bridge_test.dart test/player_session_clear_on_leave_test.dart`
  - Result: ✅ All tests passed (join/claim/vote/sendAction/state_sync/reconnect/leave-cache flow)
- `apps/host`
  - `flutter test test/sync_mode_runtime_test.dart`
  - Result: ✅ All tests passed (host runtime sync behavior)
- `packages/cb_comms`
  - `flutter analyze lib test`
  - Result: ✅ No issues found
  - `flutter test`
  - Result: ✅ All tests passed (FirebaseBridge/GameSessionManager/OfflineQueue/HostServer)

> Note: `apps/host/test/cloud_host_bridge_perf_test.dart` currently fails in test harness due to Firebase app initialization in test environment (`[core/no-app]`), not due to host↔player transport logic.

## Cross-app live smoke (Host ↔ Player)

Use this quick matrix to confirm full functional communication on real builds/devices.

### F) Establish + join handshake

- [ ] Host is signed in (host account)
- [ ] Host taps **ESTABLISH LINK** and reaches verified/active cloud state
- [ ] Player opens app and joins using host join code or deep link
- [ ] Host lobby player count increments and player appears in roster

### G) Bidirectional action path

- [ ] Player claim action is received and reflected on host
- [ ] Player sends gameplay action (vote/interaction) and host state updates
- [ ] Host publishes next state and player reflects update without stale UI
- [ ] No silent failures; user-facing error appears if write/read fails

### H) Degrade/recover behavior

- [ ] Host goes offline intentionally (**GO OFFLINE**) and player cannot continue silently
- [ ] Host re-establishes link and both sides recover without app restart
- [ ] Reconnect path preserves session identity and role/claim consistency

### I) End-to-end round

- [ ] Start game from host after minimum player threshold
- [ ] Complete one full turn with at least one player action
- [ ] End round state is consistent between host and player clients
- [ ] Leave/disconnect from player clears cached session and does not ghost-rejoin

## Manual smoke checklist (Host Lobby)

### A) Join beacon + QR usability

- [ ] Join code is clearly visible and readable at normal operator distance
- [ ] **Copy code** action copies exact lobby code and shows success feedback
- [ ] QR tile opens expanded modal on tap
- [ ] Expanded modal shows large QR + correct join code
- [ ] **Copy code** from modal works
- [ ] **Copy link** from modal works
- [ ] Inline join link card supports copy and remains selectable

### B) Cloud link state presentation

- [ ] Connecting state displays `CLOUD LINK: ESTABLISHING...`
- [ ] Ready state displays `CLOUD LINK: ACTIVE`
- [ ] Error state displays retry-required text + retry affordance
- [ ] Transition between states feels smooth (no visual jump/pop)

### C) Bottom controls behavior

- [ ] Lobby readiness strip appears and updates based on player count
- [ ] Start action disabled below minimum players
- [ ] Start action enabled at/above minimum players
- [ ] Label transitions remain context-correct (`Need X More` / `Start Game`)
- [ ] Navigation grouping and labels are visually clear

### D) Typography/spacing consistency

- [ ] Header/subheader hierarchy is legible and balanced
- [ ] Inter-panel vertical spacing appears consistent
- [ ] Config option labels/values are easy to scan
- [ ] No text clipping/truncation at common host resolutions

### E) Functional flow checks

- [ ] Add Bot works in debug mode from lobby control area
- [ ] Start Game still transitions to Game screen when conditions are met
- [ ] Manual role assignment warning still blocks invalid starts when enabled

## Execution log

- Date: 2026-02-21
- Tester: Copilot (automated pass) + _TBD_ (live device pass)
- Host platform/device: _TBD_ (live run pending)
- Build/hash: Host APK release (latest local build, 2026-02-21) + _TBD_ player build id
- Outcome summary:
  - Passed:
    - ✅ Automated host/player communication test suite
    - ✅ Shared comms transport/analyze/test checks
  - Failed:
    - ⚠️ Host perf test harness (`cloud_host_bridge_perf_test.dart`) due to Firebase test setup
  - Follow-ups:
    - Run sections F–I on physical/emulator pair and record pass/fail timestamps

## Notes for handoff

- If any visual issue is found, capture a screenshot and annotate affected section (Join Beacon / Cloud Status / Bottom Controls).
- Re-run `flutter analyze .` in `apps/host` after any follow-up fix.

