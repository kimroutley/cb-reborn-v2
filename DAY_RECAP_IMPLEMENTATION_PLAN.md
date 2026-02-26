# Day Recap (Player + Host) — Unified Card + Expand (Implementation Plan)

## Objective
Implement a **Day Recap** that appears in both:
- **Player app**: recap is **redacted / safe** (no real player names, no role reveals)
- **Host app**: recap is **unredacted / spicy** (may include real player names, roles, and heated phrasing)

Both apps must display the recap in the **same visual layout** (same widget), with a **brief collapsed card** and an **expand option**.

The recap is currently delivered via `dayReport` (players get it as a message; host gets it as a notification). This plan preserves `dayReport` as the canonical history, and also emits a single recap “card event” into the feed.

---

## Non-negotiables (Repo rules)
- Follow `STYLE_GUIDE.md` for all UI changes.
- No hardcoded colors; use `Theme.of(context).colorScheme` and existing `cb_theme` widgets.
- Prefer shared widgets (`CBGlassTile`, `CBPanel`, `CBPrimaryButton`, etc.) over raw widgets.
- Do not edit generated files (`*.g.dart`, `*.freezed.dart`).
- Run `flutter test` in the relevant package(s) after changes.

---

## Current architecture mapping (what exists)
- Player receives `GameMessage.stateSync` with `dayReport` and renders feed via `bulletinBoard`.
- Host maintains authoritative `GameState` in `packages/cb_logic`.
- `packages/cb_logic/lib/src/game_provider.dart` resolves day flow in `advancePhase()` → `case GamePhase.day:`.
- Day resolution writes `lastDayReport`:
  - `res.report` from `GameResolutionLogic.resolveDayVote(...)`
  - plus `dayResolution.lines` from `DayResolutionStrategy().execute(...)`
- Both Player and Host render `bulletinBoard` (player via `apps/player/lib/widgets/bulletin_board.dart`, host via `apps/host/lib/widgets/host_main_feed.dart`).

---

## Design decision
### Keep `dayReport` as canonical
- Continue writing `lastDayReport` / `dayReport` as currently.

### Add a recap card event into `bulletinBoard`
- Emit exactly **one** `BulletinEntry` when the day resolves.
- Use a dedicated entry type: `type: 'dayRecap'`.
- Store a **structured JSON payload** in `BulletinEntry.content`.

This achieves:
- same recap shown in both apps
- expandable UI
- no string-parsing hacks
- redaction safety

---

## Deliverables

### 1) Model: `DayRecapCardPayload` (in `cb_models`)
Create a new file:
- `packages/cb_models/lib/src/day_recap_card_payload.dart`

Model fields (JSON serializable):
- `int v` (version, start at 1)
- `int day`
- `String playerTitle`
- `List<String> playerBullets` (redacted)
- `String hostTitle`
- `List<String> hostBullets` (spicy)

Helpers:
- `Map<String, dynamic> toJson()`
- `DayRecapCardPayload.fromJson(Map<String, dynamic>)`
- `String toJsonString()`
- `static DayRecapCardPayload? tryParse(String raw)` (safe parse with `jsonDecode` and map casting)

Export it from `cb_models`’ barrel (`packages/cb_models/lib/cb_models.dart` or whichever export file exists) so apps can consume it.

---

### 2) Logic: Build and dispatch recap card at day resolution (in `cb_logic`)
Add a small helper in `cb_logic` (either inline private methods in `GameProvider`, or a dedicated file):

Recommended approach:
- Add private method(s) in `packages/cb_logic/lib/src/game_provider.dart`:
  - `_buildDayRecapPayload({ required int day, required List<String> dayReportLines, required List<Player> players })`
  - `_dispatchDayRecapCard(DayRecapCardPayload payload)`

Where to hook:
- In `advancePhase()` → `case GamePhase.day:` after this state update:
  - `state = state.copyWith(lastDayReport: [...res.report, ...dayResolution.lines], ...)`
  - and before incrementing `dayCount`, or compute `resolvedDay = state.dayCount` prior to increment.

What to include:
- `playerBullets`: derived from the **final day report lines** (existing safe text)
  - Example: `final playerBullets = dayReportLines.map((e) => '• $e').take(N).toList()`
- `hostBullets`: build from same lines but “enrich”:
  - include name + role summaries
  - include vote breakdown (if available) — `dayVotesSnapshot` exists in scope
  - optionally include a “top mistake / spicy line”

Important safety:
- Player content must never use `players[i].name` or `players[i].role.name`.
- Only host content may include those.

Dispatch behavior:
- call existing `dispatchBulletin(...)` with:
  - `title: 'DAY $day RECAP'`
  - `content: payload.toJsonString()`
  - `type: 'dayRecap'`
  - `roleId: null`
  - `isHostOnly: false` (because payload includes both player+host; the renderer selects)

Deduping:
- Ensure one recap card per day resolution. Use a stable ID or just rely on chronological appends.

---

### 3) Shared UI: `CBDayRecapCard` (in `cb_theme`)
Create a shared widget:
- `packages/cb_theme/lib/src/widgets/cb_day_recap_card.dart`

Widget requirements:
- Accepts:
  - `String title`
  - `List<String> bullets`
  - optional `Color? accentColor` (default to `scheme.primary`)
  - `int collapsedBulletCount = 3`
- Display:
  - a header row (icon + title)
  - bullet list (collapsed shows first N; expanded shows all)
  - a small CTA row/button: `EXPAND` / `COLLAPSE`
- Use:
  - `CBGlassTile`
  - typography from theme/`CBTypography`
  - accent colors from `ColorScheme`
- No hardcoded colors.

Export widget from `cb_theme` public exports if needed.

---

### 4) Player rendering: integrate `dayRecap` type into `CBBulletinBoard`
File:
- `apps/player/lib/widgets/bulletin_board.dart`

Update `itemBuilder`:
- If `entry.type == 'dayRecap'`:
  1. parse `DayRecapCardPayload.tryParse(entry.content)`
  2. if parse fails → fallback tile `CBMessageBubble` or `CBGlassTile` with "RECAP UNAVAILABLE"
  3. else render `CBDayRecapCard` using:
     - `title = payload.playerTitle.isNotEmpty ? payload.playerTitle : 'DAY ${payload.day} RECAP'`
     - `bullets = payload.playerBullets`

- Else fallback to existing rendering.

Do not expose host bullets in player app.

---

### 5) Host rendering: integrate `dayRecap` type in `HostMainFeed`
File:
- `apps/host/lib/widgets/host_main_feed.dart`

Add a case before default bubble rendering:
- If `entry.type == 'dayRecap'`:
  1. parse `DayRecapCardPayload.tryParse(entry.content)`
  2. if parse fails → fallback tile
  3. else render `CBDayRecapCard` using:
     - `title = payload.hostTitle.isNotEmpty ? payload.hostTitle : 'DAY ${payload.day} RECAP (HOST)'`
     - `bullets = payload.hostBullets`

Host version may include names + roles.

---

## Optional enhancements (post-MVP)
- Add tap-to-open full-screen recap modal, instead of inline expand.
- Add a “copy to clipboard” button for host.
- Include a stable recap id and prevent duplicates on replays/reconnect.

---

## Testing checklist
1. **Logic unit test** (`packages/cb_logic/test/...`):
   - When day resolves, `bulletinBoard` gains one entry of `type == 'dayRecap'`.
   - Payload parses.
   - `playerBullets` contain no player names and no role names (in a test roster).

2. **Widget test** (`packages/cb_theme/test/...`):
   - `CBDayRecapCard` shows collapsed bullets.
   - Press expand → shows all bullets.

3. **App tests**:
   - Player: `flutter test` in `apps/player`
   - Host: `flutter test` in `apps/host` (if present)

---

## Implementation order (suggested)
1. Add `DayRecapCardPayload` model + export.
2. Add `CBDayRecapCard` widget + export.
3. Dispatch recap card in `GameProvider.advancePhase()` at day resolution.
4. Update Player `CBBulletinBoard` rendering.
5. Update Host `HostMainFeed` rendering.
6. Add tests.

---

## Acceptance criteria
- At the end of a day, both apps show a **Day Recap card** in the feed.
- Card is **collapsed by default** and can be **expanded**.
- Player card is **redacted** (no names/roles).
- Host card shows **spicy details** with names/roles.
- No crashes if payload parsing fails.
- `flutter test` passes for relevant packages.
