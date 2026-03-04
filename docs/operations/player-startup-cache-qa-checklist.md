# Player startup cache and resume QA checklist

Use this checklist to validate that the Player app restores cached sessions,
reconnects quickly, and safely clears stale or invalid cache data.

## Scope

This checklist covers:

- Startup bootstrap flow (`PlayerBootstrapGate`).
- Local and cloud session cache restore.
- Auto-reconnect from restored pending join URL.
- Cache clearing on leave and sign-out.
- Stale cache expiry behavior.

## Preconditions

Before testing, confirm:

1. You are running a build that includes commit `a0844a4` or later.
2. Host app and player app are both available for local-mode testing.
3. Cloud mode can connect to Firebase in your target environment.
4. You can force-close and relaunch the Player app on your test device.

## Test matrix

Run all test cases in both:

- `Local mode` (`ws://...` host connection)
- `Cloud mode` (Firestore-backed join)

## Test cases

### T1: Fresh install / no cache path

1. Launch Player app with no existing session cache.
2. Verify app reaches normal auth/home flow.
3. Verify no auto-connect occurs.

Expected result:

- App does not prefill join state from a previous session.
- No background reconnect attempt is triggered.

### T2: Resume after force close while connected

1. Join a game and claim a player.
2. Force-close the app during lobby or active game.
3. Relaunch app.

Expected result:

- Startup loader appears briefly.
- Join configuration restores automatically.
- App reconnects without manual re-entry.
- Live state sync replaces cached snapshot once connected.

### T3: Resume while offline, then recover

1. Join and claim a player.
2. Force-close app.
3. Disable network.
4. Relaunch app.
5. Re-enable network.

Expected result:

- Cached state renders first.
- App remains stable while reconnect fails/retries.
- App resumes live state when network returns.

### T4: Sign-out clears cache

1. Join a game and confirm cache-backed resume works.
2. Sign out from Player app.
3. Fully close and relaunch app.

Expected result:

- No prior join code/host/player identity is restored.
- App starts as a fresh unauthenticated session.

### T5: Leave game clears cache

1. Join game and claim a player.
2. Use in-app leave action.
3. Force-close and relaunch app.

Expected result:

- No auto-resume occurs.
- Previous game state is not restored.

### T6: Stale cache expiry

1. Create a cached session.
2. Move device time forward more than 18 hours.
3. Relaunch app.

Expected result:

- Cache entry is treated as expired and discarded.
- App starts without resume.

### T7: Local-mode host metadata restore

1. Join a local-mode game using host address.
2. Force-close and relaunch app.

Expected result:

- Restored local join flow includes host address.
- Auto-connect targets the same host endpoint.

### T8: Cloud-mode bridge restore

1. Join a cloud-mode game.
2. Force-close and relaunch app.

Expected result:

- Cloud bridge state restores from cache.
- App auto-connects in cloud mode and rehydrates live state.

## Regression checks

After T1-T8, confirm:

1. Player claim flow still works.
2. Join rejection and error messaging still render correctly.
3. Widget smoke test behavior is unchanged (no timer leaks).
4. `apps/player` analyze and tests still pass in CI/local runs.

## Evidence to capture

For each test case, attach:

- Device/platform and build version.
- Mode (`local` or `cloud`).
- Pass/fail result.
- Short notes for unexpected behavior.
- Screenshot or short recording for failures.

## Sign-off

Release candidate is ready when:

1. All T1-T8 pass in local mode.
2. All T1-T8 pass in cloud mode.
3. No critical or high-severity regressions remain open.

---

## Runbook (manual execution)

Use this runbook for a structured manual pass. Run once per mode (local, then cloud).

### Setup

1. **Build:** From repo root, `flutter build apk` (or your target) for the player app. Note build version and commit.
2. **Device:** Note device model, OS version, and that you can force-close and relaunch the app.
3. **Local mode:** Host app running and reachable (e.g. same network); note host URL (e.g. `ws://192.168.1.x`).
4. **Cloud mode:** Firebase project configured; join code from a live host lobby.

### Execution order

| Step | Test | Action |
|------|------|--------|
| 1 | T1 | Uninstall or clear app data; launch → confirm auth/home, no auto-connect. |
| 2 | T2 | Join (local or cloud), claim player; force-close; relaunch → confirm loader, restore, reconnect. |
| 3 | T3 | Same as T2, then disable network, relaunch; re-enable network → confirm cached UI then live state. |
| 4 | T4 | After a good T2 run, sign out; close and relaunch → confirm no restore. |
| 5 | T5 | Join and claim; use in-app leave; force-close and relaunch → confirm no restore. |
| 6 | T6 | Join and claim; set device time +20h; relaunch → confirm no restore (then set time back). |
| 7 | T7 | **Local only:** Join via host address; force-close; relaunch → confirm host field prefilled and same endpoint used. |
| 8 | T8 | **Cloud only:** Join cloud game; force-close; relaunch → confirm cloud reconnect and state rehydrated. |
| 9 | Regression | Claim flow, join rejection UI, no leaks; run `flutter test apps/player` and `flutter analyze apps/player`. |

### Evidence template (per test)

```text
T#: [PASS|FAIL]
Mode: local | cloud
Device: <model> / <OS>
Build: <version> / <commit>
Notes: <one line or "None">
Attachment: <screenshot or recording path if FAIL>
```

---

## Evidence logging (for automation or debug)

To support evidence capture and debugging:

- **Bootstrap:** `PlayerBootstrapGate` runs `_restoreCachedSession()`; when a cache entry is restored (cloud or local), the app sets `pendingJoinUrlProvider`. You can add a single debug log here, e.g. `debugPrint('[Bootstrap] Restored ${entry.mode.name} session code=${entry.joinCode}')`, and when no entry is restored, `debugPrint('[Bootstrap] No cache restored')`. This helps confirm T1 (no log for restore) vs T2/T7/T8 (one log line per restore).
- **Cache clear:** Sign-out and leave both call `PlayerSessionCacheRepository.clear()`. Optional: `debugPrint('[SessionCache] Cleared')` in `clear()` when running in debug/profile so logs show T4/T5 behavior.
- **Stale expiry:** In `PlayerSessionCacheRepository.loadSession()`, when entry is dropped due to age, the code already calls `clear()` and returns null; optional `debugPrint('[SessionCache] Dropped stale entry age=${entry.savedAt}')` for T6 evidence.

These logs are optional; the runbook and evidence template above work with or without them. For CI, the unit tests in `apps/player/test/player_startup_cache_checklist_test.dart` (and related cache tests) cover T1, T4, T5, T6, and the bootstrap restore behavior for T7/T8; T2 and T3 remain manual.
