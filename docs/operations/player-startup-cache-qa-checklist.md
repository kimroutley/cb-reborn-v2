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

1. You are running a build that includes the current player cache/bootstrap logic (e.g. commit `3c20451` or later; run `git rev-parse --short HEAD` for latest).
2. Host app and player app are both available for local-mode testing.
3. Cloud mode can connect to Firebase in your target environment.
4. You can force-close and relaunch the Player app on your test device.

## Test matrix

Run all applicable test cases in both:

- **Local mode** (`ws://...` host connection)
- **Cloud mode** (Firestore-backed join)

**Note:** Session restore on startup is **cloud-only** in the current implementation. Local-mode cache is cleared on next launch (see [Code alignment](#code-alignment) and T7).

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
- Join configuration restores automatically (cloud only).
- App reconnects without manual re-entry.
- Live state sync replaces cached snapshot once connected.

### T3: Resume while offline, then recover

1. Join and claim a player (cloud mode).
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

1. Create a cached session (join and claim in cloud mode).
2. Move device time forward more than 18 hours (or use a test build that injects an old `savedAt`).
3. Relaunch app.

Expected result:

- Cache entry is treated as expired and discarded (`PlayerSessionCacheRepository._maxEntryAge` = 18 hours).
- App starts without resume.

### T7: Local-mode host metadata restore

**Current behavior:** Session restore on bootstrap is **cloud-only**. If the cached entry has `mode: local`, bootstrap clears the cache and does **not** set a pending join URL. Local host address is therefore **not** restored after force-close.

- **If testing local mode:** After force-close and relaunch, expect **no** auto-resume; user must re-enter host address and join code.
- **Future enhancement:** To support T7 as originally described, bootstrap would need to restore local entries and set a pending URL that includes `mode=local` and `host=ws://...`.

### T8: Cloud-mode bridge restore

1. Join a cloud-mode game.
2. Force-close and relaunch app.

Expected result:

- Cloud bridge state restores from cache (`restoreFromCache` + pending join URL with `autoconnect=1`).
- App auto-connects in cloud mode and rehydrates live state.

---

## Code alignment

Cross-check of this checklist against the codebase (as of the last doc update):

| Area | Doc expectation | Code location | Status |
|------|-----------------|---------------|--------|
| Bootstrap restores session | Only when cache present and valid | `PlayerBootstrapGate._restoreCachedSession` | ✅ |
| Cloud-only restore | Only `CachedSyncMode.cloud` restored; local cleared | `player_bootstrap_gate.dart` L166–170 | ✅ |
| Pending join URL for resume | Set with `code`, `mode=cloud`, `autoconnect=1` | `player_bootstrap_gate.dart` L173–181 | ✅ |
| Stale expiry | 18 hours | `PlayerSessionCacheRepository._maxEntryAge` | ✅ |
| Leave clears cache | Both bridges call `playerSessionCacheRepository.clear()` | `player_bridge.dart` L625, `cloud_player_bridge.dart` L254 | ✅ |
| Sign-out clears cache | Auth notifier calls `PlayerSessionCacheRepository().clear()` | `auth_provider.dart` L258 | ✅ |
| Local restore (T7) | Checklist originally expected host address restore | Bootstrap clears non-cloud cache | ⚠️ Doc updated; T7 marked as current behavior |

---

## Runbook (step-by-step execution)

Use this runbook to execute T1–T8 and regression checks in order.

### Environment

- [ ] Player app build installed (release or debug).
- [ ] Host app running (same network for local; Firebase for cloud).
- [ ] Device/emulator allows force-close (swipe away or Stop).

### T1 – Fresh install / no cache

1. [ ] Uninstall Player app or clear app data (so no session cache exists).
2. [ ] Launch Player app.
3. [ ] Confirm: home/connect screen, no pre-filled join code or host.
4. [ ] Confirm: no automatic reconnect or loading toward a game.
5. [ ] Record: **Pass** / **Fail** — notes: _______________

### T2 – Resume after force close (cloud)

1. [ ] Open Player app, ensure **cloud** mode selected.
2. [ ] Enter valid join code, join game, claim a player (reach lobby or game).
3. [ ] Force-close the app (do not use in-app leave).
4. [ ] Relaunch Player app.
5. [ ] Confirm: brief “LOADING PLAYER CLIENT” / bootstrap.
6. [ ] Confirm: app reconnects and shows same game/lobby without re-entering code.
7. [ ] Record: **Pass** / **Fail** — notes: _______________

### T3 – Offline then recover (cloud)

1. [ ] Join and claim in cloud mode, then force-close app.
2. [ ] Turn off Wi‑Fi and mobile data (or use airplane mode).
3. [ ] Relaunch Player app.
4. [ ] Confirm: cached state shows; app does not crash; reconnect may show error/retry.
5. [ ] Turn network back on.
6. [ ] Confirm: app recovers and shows live state (or reconnects when user triggers connect).
7. [ ] Record: **Pass** / **Fail** — notes: _______________

### T4 – Sign-out clears cache

1. [ ] Join and claim (cloud), confirm resume works (T2), then force-close.
2. [ ] Relaunch, confirm auto-resume.
3. [ ] Sign out (profile or auth screen).
4. [ ] Force-close and relaunch again.
5. [ ] Confirm: no join code or game restored; fresh unauthenticated flow.
6. [ ] Record: **Pass** / **Fail** — notes: _______________

### T5 – Leave clears cache

1. [ ] Join and claim a player.
2. [ ] Use in-app **Leave** (e.g. from lobby or game menu).
3. [ ] Force-close and relaunch.
4. [ ] Confirm: no auto-resume; previous game not restored.
5. [ ] Record: **Pass** / **Fail** — notes: _______________

### T6 – Stale cache expiry

1. [ ] Join and claim in cloud; force-close (cache exists).
2. [ ] Set device time **forward by >18 hours** (or use test that saves old `savedAt`).
3. [ ] Relaunch Player app.
4. [ ] Confirm: no resume; app starts as if no cache (connect/home).
5. [ ] Restore device time.
6. [ ] Record: **Pass** / **Fail** — notes: _______________

### T7 – Local-mode (no restore)

1. [ ] Select **local** mode, enter host address and join code, join and claim.
2. [ ] Force-close and relaunch.
3. [ ] Confirm: **no** auto-resume; join code and host address **not** pre-filled.
4. [ ] Record: **Pass** / **Fail** — notes: _______________

### T8 – Cloud bridge restore

1. [ ] Same as T2: join cloud, claim, force-close, relaunch.
2. [ ] Confirm: cloud bridge state restored (e.g. phase, players), then live sync.
3. [ ] Record: **Pass** / **Fail** — notes: _______________

### Regression checks

1. [ ] Player claim flow: join → claim player → see correct name/role in lobby.
2. [ ] Join rejection: invalid code or host rejection shows clear error.
3. [ ] No timer leaks: leave app in lobby/game for 1–2 min, return; no obvious duplicate timers or freezes.
4. [ ] Run: `cd apps/player && flutter analyze` — no errors.
5. [ ] Run: `cd apps/player && flutter test` — all tests pass.

---

## Automation outline

What can be automated today and what would need extra work:

### Already covered by tests

| Check | Test / location | Notes |
|-------|------------------|--------|
| Cache save/load | `player_session_cache_test.dart` | Save and load entry. |
| Stale entry dropped | `player_session_cache_test.dart` | Entry older than 18h (test uses 2 days) returns null. |
| Sign-out clears cache | `auth_provider_cache_test.dart` | After signOut(), loadSession() is null. |
| Leave clears cache | `player_session_clear_on_leave_test.dart` | After bridge.leave(), loadSession() is null (local and cloud). |
| Bootstrap no cache → no URL | `player_bootstrap_gate_test.dart` | No cache → pending join URL not set. |
| Bootstrap ignores local cache | `player_bootstrap_gate_test.dart` | Local entry → cache cleared, cloud bridge not restored. |
| Bootstrap restores cloud + URL | `player_bootstrap_gate_test.dart` | Cloud entry → restoreFromCache + pending URL. |
| Resume retry delay | `home_screen_resume_test.dart` | resumeRetryDelayForAttempt, shouldAcceptJoinUrlEvent. |

### Good candidates for more automation

1. **Expiry boundary (18h)**  
   - Add a test that saves an entry with `savedAt = now - 17 hours` → load returns entry; `savedAt = now - 19 hours` → load returns null.  
   - File: extend `player_session_cache_test.dart` or add `player_session_cache_expiry_test.dart`.

2. **Bootstrap timeout**  
   - Bootstrap has a 30s overall timeout and 5s for loadSession.  
   - Optional: widget test that simulates slow loadSession and asserts loader completes or times out without crash.

3. **CI regression**  
   - In CI: run `flutter analyze` and `flutter test` in `apps/player` on every PR (already common); call out in this doc as the “Regression checks” automation.

### Manual-only (for now)

- T2, T3, T5, T8: force-close and relaunch, network toggling — require real device/emulator and manual steps.
- T4: full sign-out flow and relaunch — can be partially covered by `auth_provider_cache_test.dart`; full UI flow is manual.
- T6: changing device time — can be unit-tested by injecting a repository that returns an old entry; real “move time forward” is manual.
- T7: local no-restore — covered by “bootstrap ignores local cache” widget test; manual check that UI does not pre-fill host/join is optional.

### Suggested script (CI)

```bash
# From repo root
cd apps/player
flutter analyze --no-fatal-infos
flutter test
```

Add to GitHub Actions / CI so that every run validates the regression checks above.

---

## Evidence to capture

For each test case, attach:

- Device/platform and build version.
- Mode (`local` or `cloud`).
- Pass/fail result.
- Short notes for unexpected behavior.
- Screenshot or short recording for failures.

## Sign-off

Release candidate is ready when:

1. All applicable T1–T8 pass in local mode (T7: expect no restore).
2. All applicable T1–T8 pass in cloud mode.
3. No critical or high-severity regressions remain open.
4. `flutter analyze` and `flutter test` pass in `apps/player`.
