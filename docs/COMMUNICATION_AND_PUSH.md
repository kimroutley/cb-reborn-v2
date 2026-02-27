# Host–Player Communication and Push Notifications

This document is the **single source of truth** for how the host and player apps communicate, current gaps, and the push-notification event catalog. It supports the "Host–Player Communication Audit and Push Notifications" plan.

---

## 1. Current Communication Flow

### 1.1 How host and player communicate today

- **Cloud mode (Firebase):** The host publishes game state to Firestore; players subscribe via realtime listeners. There are **no push notifications** in the codebase unless explicitly added.

| Direction | Mechanism | Where |
|----------|------------|--------|
| Host → Players | Firestore writes | `apps/host/lib/cloud_host_bridge.dart`: `publishState()` writes to `games/{joinCode}` and `games/{joinCode}/private_state/{playerId}`. Triggered by `ref.listen(gameProvider)` and `ref.listen(sessionProvider)`. |
| Players → Host | Firestore writes | `packages/cb_comms/lib/src/firebase_bridge.dart`: players write to `games/{joinCode}/actions` and `games/{joinCode}/joins`. Host listens via `subscribeToActions()` and `subscribeToJoinRequests()`. |
| Player receives updates | Realtime listeners only | `apps/player/lib/cloud_player_bridge.dart`: `subscribeToGame().listen()` and `subscribeToPrivateState(playerId).listen()`. |

When the player closes the browser tab or the PWA, those listeners are torn down. State is **not** pushed to the device; the user must reopen the app to see new data (and will get the latest state from Firestore on reconnect).

### 1.2 Gaps (pre–push implementation)

- **No FCM / Web Push:** No `firebase_messaging` (or equivalent) in the player app. No service-worker push handling.
- **No Firebase Cloud Functions:** The repo includes a `functions/` folder only when the push backend is added; otherwise there is no server-side trigger to send push when Firestore updates.
- **No stored push targets:** Players do not register a push subscription or FCM token, so nothing can "wake" them when the app is closed.

---

## 2. Push Notification Event Catalog

For "all push notifications are being sent," these are the logical events to consider. The **Implemented** column is updated as the Cloud Function and client flows are completed.

| Event | Who gets notified | Rationale | Implemented |
|-------|-------------------|-----------|-------------|
| Role assigned | That player | Confirm your role / open app to see role. | Yes (see functions) |
| Game started (phase → setup/night) | All players in game | Game is starting. | Yes |
| Phase → day | All living players | Day discussion / vote. | Yes |
| Phase → night | Players with a night action (or all) | Your turn / night phase. | Yes |
| New bulletin (non–host-only) | All players (or per-role if needed) | New in-game message. | Yes |
| Rematch offered | All players in that game | Host started a rematch; rejoin. | Yes |
| Host-only / spicy content | — | Do **not** push (privacy). | N/A |

### Implementation status (Cloud Functions)

The following are implemented in `functions/index.js`:

- **Role assigned**: `onPrivateStateUpdated` fires when `games/{joinCode}/private_state/{playerId}` is updated with a new `roleId`; that player receives a push.
- **Game started**: `onGameUpdated` detects phase transition to `setup` or `night` and sends to all players in the game.
- **Phase → day / night**: `onGameUpdated` detects phase transitions to `day` or `night` and sends to living players (day) or all (night).
- **Rematch offered**: `onGameUpdated` detects `rematchOffered` becoming true and sends to all players.
- **New bulletin**: `onGameUpdated` detects an increase in the length of the public `bulletinBoard` and sends the latest entry’s title/body to all players.

VAPID keys must be set (see `functions/README.md`). The player app must have the same public key in `push_subscription_register.dart` and must run the service-worker append step so push is received when the app is closed.

---

## 3. Target Architecture (Push + PWA)

- **Player (web):** Requests notification permission (and optionally "Add to Home Screen"). Registers a Web Push subscription (VAPID) or FCM token and stores it in Firestore (e.g. under that player's `private_state` or `push_subscriptions` subcollection).
- **Backend:** A Firebase Cloud Function runs on relevant Firestore writes (e.g. `games/{joinCode}` or `private_state/{playerId}`). It decides which events warrant a notification (using the catalog above), looks up subscriptions for the target players, and sends via Web Push API or FCM.
- **When app/browser is closed:** The service worker (or FCM) receives the push and shows a notification; tapping opens the app URL so the game can continue after reopen.
- **Host:** The host app does **not** send push itself; it only writes to Firestore. The Cloud Function reacts to those writes and sends notifications.

---

## 4. Service worker (push when app is closed)

The Flutter-built service worker does not handle `push` by default. To show notifications when the browser/PWA is closed:

1. Build the player web app: `cd apps/player && flutter build web`
2. Append the push handler: from repo root, `node scripts/append_push_to_sw.js`
3. Deploy the contents of `apps/player/build/web/` (including the modified `flutter_service_worker.js`)

The script concatenates `apps/player/web/push_handler.js` (push + notificationclick listeners) onto the built `flutter_service_worker.js`. The Cloud Function must send payloads with `title` and `body` (and optionally `tag`) so the handler can show the notification.

## 5. Related Files

- Host publish: `apps/host/lib/cloud_host_bridge.dart`
- Player subscribe: `apps/player/lib/cloud_player_bridge.dart`
- Firebase bridge (player writes, host listens): `packages/cb_comms/lib/src/firebase_bridge.dart`
- Player web manifest: `apps/player/web/manifest.json`
- Push handler (append to SW): `apps/player/web/push_handler.js`
- Append script: `scripts/append_push_to_sw.js`
- Cloud Functions (push sender): `functions/` (when present)
