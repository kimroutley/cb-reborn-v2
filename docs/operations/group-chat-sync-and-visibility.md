# Group Chat Sync and Visibility (Host vs Player)

This doc confirms how group chat stays in sync between host and player apps and who sees what (spicy vs clean, identity rules). **The same public feed is mirrored in both apps**; the host additionally sees host-only entries.

## Where the feed appears (mirroring checklist)

| App    | Location | Source | Notes |
|--------|----------|--------|--------|
| **Host** | **HostMainFeed** | `gameProvider` → `gameState.bulletinBoard` | Main game screen feed; full bulletin + ghost interleave. |
| **Host** | **HostChatView** | `gameState.bulletinBoard` (from parent) | Comms tab “LIVE FEED”; full bulletin. |
| **Player** | **Connect screen** (after join) | `activeBridgeProvider.state` → `buildBulletinList(...)` | Group chat visible as soon as link is established. |
| **Player** | **Lobby screen** | `bridgeState` / `gameState` → `buildBulletinList(...)` | Same feed in lounge. |
| **Player** | **Game screen** | `gameState` → `_buildBulletinList(...)` | In-game feed; same public entries + role filter. |
| **Player** | **ChatWidget** (if used) | `gameProvider` + sanitize + role filter | Uses same sanitize + targetRoleId filter. |

- **Host**: Both HostMainFeed and HostChatView read from the same `gameState.bulletinBoard` (gameProvider). New posts (host or player) go into that bulletin and are published to cloud (public entries only).
- **Player**: Connect, Lobby, and Game screen all read from **bridge state** (`PlayerGameState.bulletinBoard`), which is the public bulletin received from the host (and sanitized). So the **public part of the feed is mirrored**: same entries, same order; players additionally have role-targeted filtering (messages with `targetRoleId` only show to that role).

## Sync

- **Single source of truth**: Host holds full `bulletinBoard` in game state. Host syncs public bulletin to Firestore (e.g. in `cloud_host_bridge`).
- **What gets written to cloud**: When the host writes game state to Firestore, bulletin entries are filtered to **exclude host-only** before sending:
  - `bulletinBoard.where((e) => !e.isHostOnly)` (see `apps/host/lib/cloud_host_bridge.dart`).
- **What the player receives**: The player app receives the same public bulletin from Firestore and applies **defense-in-depth** sanitization:
  - `PlayerGameState.sanitizePublicBulletinEntries(bulletinBoard)` (see `apps/player/lib/player_bridge.dart` and `apps/player/lib/cloud_player_bridge.dart`).
- **Sanitization rules** (player-side): Entries are shown only if:
  - `!entry.isHostOnly`
  - `entry.type != 'hostIntel'`
  - `entry.type != 'ghostChat'`
  So host-only, host intel, and ghost chat are never shown in the player’s main group chat feed.
- **Role-targeted messages**: Entries with `targetRoleId` set are shown only to players whose role matches; all other players hide them. This filtering is applied in `buildBulletinList` / `_buildBulletinList` and in ChatWidget so the feed is consistent everywhere on the player app.

## Who sees what

### Host app

- **Spicy / full view**: Host sees the **entire** bulletin (all messages, including host-only and hostIntel).
- **Display**: Uses full `gameState.bulletinBoard` with no sanitization (e.g. `HostMainFeed`, `HostChatView`).
- Host-only entries (e.g. spicy recaps, internal intel) are **never sent to the cloud**, so players cannot receive them.

### Player app (normal roles)

- **Clean view**: Players see only **player-safe** entries (no host-only, no hostIntel, no ghostChat in the main feed).
- **Identity**: Messages are shown by **character/role name** (e.g. “The Bartender”), not by real player name, so identities are not given away in group chat.
- **Sending**: When a player sends a group chat message, the client uses **role name** as the public title (e.g. `sendBulletin(title: player.roleName, ...)` in `game_screen.dart`), so the bulletin is stored and displayed under the character name.

### Player app – Club Manager

- **Exception**: If the viewer is the **Club Manager**, the app **reveals the real player name** for other senders in the feed.
- **Display**: Sender is shown as `"Role Name (Real Player Name)"` (e.g. “The Bartender (Alice)”) for other players’ messages. Own messages stay as role name.
- **Where**: Same logic in:
  - In-game feed: `apps/player/lib/screens/game_screen.dart` (`_buildBulletinList`, `isClubManager`).
  - Lobby feed: `apps/player/lib/screens/lobby_screen.dart` (`_buildBulletinList`, `isClubManager`).

## Summary

| Viewer       | Bulletin content      | Sender identity in feed      |
|-------------|------------------------|------------------------------|
| Host        | Full (spicy + all)     | As stored (role/host name)   |
| Player      | Clean (public only)    | Role name only               |
| Club Manager| Clean (public only)    | Role name + real name in ()  |

Group chat is synced via the same public bulletin; the host shows the spicy feed and the player app shows the clean feed and does not reveal identities except for the Club Manager role as above.

**Mirroring confirmed**: The public bulletin (non–host-only entries) is the single source sent from host to players. Every place that displays “group chat” on the player app (Connect after join, Lobby, Game screen, and ChatWidget) reads from that same bridge bulletin list (sanitized + role-filtered). The host always reads from `gameState.bulletinBoard` in both HostMainFeed and HostChatView, so the feed is mirrored in both apps.
