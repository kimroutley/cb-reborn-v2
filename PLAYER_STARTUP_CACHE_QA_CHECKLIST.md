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
