# Player startup cache — code trace and scenario mapping

This document maps the [Player startup cache QA checklist](player-startup-cache-qa-checklist.md) test cases (T1–T8) to implementation and notes any gaps.

## Data flow summary

| Component | Role |
|----------|------|
| **PlayerSessionCacheRepository** (`player_session_cache.dart`) | Load/save/clear `PlayerSessionCacheEntry` (joinCode, mode, hostAddress, playerName, savedAt, state) in SharedPreferences key `player_session_cache_v1`. Stale entries (>18h) are cleared on load. |
| **PlayerBootstrapGate** (`bootstrap/player_bootstrap_gate.dart`) | On startup: runs persistence init, Firestore cache config, then `_restoreCachedSession()`. Only **cloud** entries are restored; cloud bridge gets `restoreFromCache(entry)` and `pendingJoinUrlProvider` is set with `code`, `mode=cloud`, `autoconnect=1`. |
| **pendingJoinUrlProvider** (`join_link_state.dart`) | Holds a join URL string (or null). Set by bootstrap after restore, or by app-link handler. Consumed by `HomeScreen` in a post-frame callback to run `_handlePendingJoinUrl` → `_applyPendingJoinUrl` → `_connect()` when `autoconnect=1`. |
| **HomeScreen** (`screens/home_screen.dart`) | Parses pending URL (code, mode, host, autoconnect). For cloud: sets sync mode cloud and triggers `_connect()`. For local: sets sync mode local and prefills host from `host` query param, then `_connect()`. |
| **PlayerBridge** (`player_bridge.dart`) | Local WebSocket bridge. `restoreFromCache` sets _cachedJoinCode, _cachedPlayerName, _cachedHostAddress, state. `leave()` calls `playerSessionCacheRepository.clear()`. `_persistSessionCache()` saves entry with `CachedSyncMode.local` and `hostAddress`. |
| **CloudPlayerBridge** (`cloud_player_bridge.dart`) | Cloud Firestore bridge. `restoreFromCache` sets _cachedJoinCode, _cachedPlayerName, state. `leave()` calls `playerSessionCacheRepository.clear()`. `_persistSessionCache()` saves with `CachedSyncMode.cloud`. |
| **Auth sign-out** (`auth/auth_provider.dart`) | Calls `PlayerSessionCacheRepository().clear()` so cache is cleared on sign-out. |

---

## Scenario mapping

### T1: Fresh install / no cache path

- **Expected:** No cache, normal auth/home, no auto-connect.
- **Implementation:** `PlayerSessionCacheRepository.loadSession()` returns `null` when prefs have no key or invalid data. Bootstrap `_restoreCachedSession()` returns early when `entry == null`; `pendingJoinUrlProvider` is never set. Home screen has no pending URL, so no auto-connect.
- **Status:** Implemented.

### T2: Resume after force-close while connected

- **Expected:** Startup loader, join config restores, app reconnects, live state replaces cache.
- **Implementation:** (Cloud) Bootstrap loads cache, restores cloud bridge state, sets `pendingJoinUrl` with code + mode=cloud + autoconnect=1. Home screen’s listener runs `_handlePendingJoinUrl` → `_applyPendingJoinUrl` (mode=cloud, autoConnect=true) → `_connect(fromResumeAutoReconnect: true)`. Cloud bridge reconnects via Firestore; live state overwrites cached snapshot.
- **Status:** Implemented for **cloud**. For **local**, see T7.

### T3: Resume while offline, then recover

- **Expected:** Cached state shows first, stable while offline, live state when network returns.
- **Implementation:** Same restore path as T2. Cached state is already in the active bridge after restore; UI shows it. When `_connect()` runs (e.g. on retry or when user taps connect), connection fails until network is back; once connected, live state replaces cache. Resume retry logic in `HomeScreen` (`_resumeRetrySchedule`) drives retries.
- **Status:** Implemented (cloud). Local: same idea once T7 is in place.

### T4: Sign-out clears cache

- **Expected:** After sign-out and relaunch, no prior join/identity restored.
- **Implementation:** `auth_provider` sign-out calls `PlayerSessionCacheRepository().clear()`. Next launch has no cache (T1 path).
- **Status:** Implemented. Covered by `auth_provider_cache_test.dart`.

### T5: Leave game clears cache

- **Expected:** After in-app leave and relaunch, no auto-resume.
- **Implementation:** `PlayerBridge.leave()` and `CloudPlayerBridge.leave()` both call `playerSessionCacheRepository.clear()` before disconnecting. Next launch has no cache.
- **Status:** Implemented. Covered by `player_session_clear_on_leave_test.dart`.

### T6: Stale cache expiry

- **Expected:** Cache older than 18h discarded on load, no resume.
- **Implementation:** `PlayerSessionCacheRepository.loadSession()` checks `DateTime.now().difference(entry.savedAt) > _maxEntryAge` (18 hours); if true, calls `clear()` and returns `null`. Bootstrap then gets no entry.
- **Status:** Implemented. Covered by `player_session_cache_test.dart` (stale entry returns null).

### T7: Local-mode host metadata restore

- **Expected:** Restored local join includes host address; auto-connect targets same host.
- **Implementation (current):** Bootstrap `_restoreCachedSession()` only restores when `entry.mode == CachedSyncMode.cloud`. For `CachedSyncMode.local` it currently clears the cache and returns, so **local cache is never restored at startup**.
- **Implementation:** Bootstrap now restores local entries: calls `ref.read(playerBridgeProvider.notifier).restoreFromCache(entry)` and sets `pendingJoinUrlProvider` with `code`, `mode=local`, `host=entry.hostAddress` (when present), `autoconnect=1`. HomeScreen then prefills host and triggers auto-connect to the same endpoint.
- **Status:** Implemented.

### T8: Cloud-mode bridge restore

- **Expected:** Cloud bridge state restores from cache; app auto-connects in cloud mode and rehydrates.
- **Implementation:** Bootstrap restores cloud entry into `CloudPlayerBridge` and sets pending URL with mode=cloud and autoconnect=1. Home runs `_connect()` with cloud bridge; Firestore subscription rehydrates state.
- **Status:** Implemented.

---

## Regression checks (from checklist)

1. **Player claim flow** — Unchanged; claim happens after connect/join in Connect/Claim flow.
2. **Join rejection and error messaging** — Rendered from `state.joinError` / `state.claimError`; no change to cache flow.
3. **Widget smoke / timer leaks** — Resume retry timer in HomeScreen is cancelled in `dispose` and when leaving; no cache-specific timers.
4. **`flutter analyze` and tests** — Run `flutter analyze apps/player` and `flutter test apps/player` after any cache changes.

---

## Files reference

| File | Purpose |
|------|--------|
| `apps/player/lib/player_session_cache.dart` | Cache entry type, repository (load/save/clear, 18h expiry). |
| `apps/player/lib/bootstrap/player_bootstrap_gate.dart` | Startup: restore cloud or local from cache, set pendingJoinUrl. |
| `apps/player/lib/join_link_state.dart` | pendingJoinUrlProvider. |
| `apps/player/lib/screens/home_screen.dart` | Handles pendingJoinUrl; _connect() for local vs cloud. |
| `apps/player/lib/player_bridge.dart` | Local bridge: restoreFromCache, leave clears cache, _persistSessionCache. |
| `apps/player/lib/cloud_player_bridge.dart` | Cloud bridge: restoreFromCache, leave clears cache, _persistSessionCache. |
| `apps/player/lib/auth/auth_provider.dart` | Sign-out clears cache. |
