# cb_comms

Communication layer for Club Blackout Reborn — Firebase integration, local
WebSocket networking, and player profile management.

## Responsibilities

- **Firebase Bridge** (`firebase_bridge.dart`) — Firestore read/write
  abstraction for cloud-synced game sessions (state, actions, bulletins,
  heartbeats).
- **Host Server** (`host_server.dart`) — WebSocket server running on the host
  device for LAN-mode play. Broadcasts state to connected players over
  `ws://<host-ip>:<port>`. *Depends on `dart:io`; excluded from web builds via
  `cb_comms_player.dart`.*
- **Player Client** (`player_client.dart`) — WebSocket client used by the
  player app to connect to the host server.
- **Game Session Manager** (`game_session_manager.dart`) — Session lifecycle
  orchestration: connection health (heartbeat), offline action queuing,
  automatic reconnection, and connectivity monitoring.
- **Offline Queue** (`offline_queue.dart`) — Persistent queue backed by
  `SharedPreferences` for actions submitted while offline.
- **Game Message** (`game_message.dart`) — Typed message envelope shared
  between host and player for WebSocket payloads.
- **Profile Repository** (`profile_repository.dart`) — Player profile CRUD
  backed by Firestore.
- **Profile Form Validation** (`profile_form_validation.dart`) — Shared
  validation rules for profile editing.
- **Profile Avatar Catalog** (`profile_avatar_catalog.dart`) — Predefined
  avatar options for player profiles.

## Exports

| Entry point | Audience | Notes |
|-------------|----------|-------|
| `cb_comms.dart` | Host app | Full API including `HostServer` (`dart:io`). |
| `cb_comms_player.dart` | Player app / Web | Excludes `HostServer` for web compatibility. |

## Dependencies

- `cb_models` (sibling package)
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `web_socket_channel`
- `shared_preferences`
- `connectivity_plus`
