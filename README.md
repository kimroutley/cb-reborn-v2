# Club Blackout Reborn 🎭

**A high-tech, social deduction party game set in a neon-drenched nightclub.**
Track down the dealers before they take over the party!

## 🎮 About

Club Blackout Reborn is a multiplayer social deduction game where **Party Animals** must identify and eliminate the **Dealers (Club Staff)** hidden among them. The game blends the classic mechanics of Mafia/Werewolf with a modern, "Neon Glass Nightclub" aesthetic and a group chat-inspired interface.

### The Vibe: "Neon Glass Nightclub"

The game is designed to feel like you're inside a dark, upscale nightclub with neon accent lighting. The UI mimics a high-tech group chat feed, immersing players in a cyber-noir narrative.

### Key Features

- **🎭 30+ Unique Roles** - From the **Bouncer** and **Medic** to the chaotic **Messy Bitch** and **Drama Queen**.
- **🤖 Autonomous Bots** - Host can add bot players to fill the roster. Bots play autonomously (voting, using abilities) via the "Simulate Bots" command, allowing for single-device testing and gameplay simulation.
- **💬 Chat Feed Interface** - Game events, narration, and actions are presented as a live, interactive chat stream.
- **⚡ God Mode** - The Host has full control with a **"Nerve Center" Dashboard**: **Sin Bin** (temporarily remove disruptive players), **Shadow Ban** (allow speech while hiding messages), and **Mute** (silence players instantly).
- **✨ Prismatic Glass UI** - Optional "oil slick" shimmer overlay for glass tiles (`CBGlassTile.isPrismatic`).
- **📱 Biometric ID Cards** - Immersive role reveal cards and "Club Bible" operatives list featuring "Hold to Reveal" style secure identity headers.
- **☁️ Dual-Mode Sync** - Play locally via WebSocket (low latency) or online via Firebase (cloud sync).
- **📊 Spicy Recap** - Dual-track game reports: detailed truths for the Host, teasers for the players.
- **🌃 Games Night Stats** - Track sessions across multiple games with a "Spotify Wrapped" style recap.

## 🏗️ Architecture

> **⚠️ Developers & Agents:** Please read [`AGENT_CONTEXT.md`](./AGENT_CONTEXT.md) for critical implementation details, build order constraints, and known issues.

This project is a **Flutter monorepo** containing:

```text
cb_reborn/
├── packages/           # Shared packages
│   ├── cb_logic/      # Game engine, Riverpod providers, & persistence
│   ├── cb_models/     # Freezed data models, enums, & role catalog
│   ├── cb_theme/      # M3 "Neon Glass" design system & UI components
│   └── cb_comms/      # Firebase & WebSocket communication layer
└── apps/              # Applications
    ├── player/        # Player mobile/web app (Flutter)
    └── host/          # Host dashboard app (Flutter Desktop/Tablet)
```

### Tech Stack

- **Framework**: Flutter 3.35+
- **Language**: Dart 3.9+
- **State Management**: Riverpod 3.x
- **Data Models**: Freezed, JSON Serializable
- **Persistence**: Hive CE
- **Cloud**: Firebase (Firestore, Auth, Hosting)
- **Theming**: Material 3 with `dynamic_color` and custom extensions

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.35.0 or higher
- Dart 3.9.0 or higher
- Firebase CLI (for deployment)

### Firebase Auth Setup (Email Link)

Both Host and Player now use **Firebase Email Link (passwordless)** sign-in.

1. In Firebase Console → **Authentication** → **Sign-in method**:
   - Enable **Email/Password**
   - Enable **Email link (passwordless sign-in)**
2. In Authentication settings, make sure authorized domains include:
   - `cb-reborn.web.app`
3. The app currently sends links with these continue URLs:
   - Host: `https://cb-reborn.web.app/email-link-signin?app=host`
   - Player: `https://cb-reborn.web.app/email-link-signin?app=player`
4. App identifiers used in `ActionCodeSettings`:
   - Host Android: `com.clubblackout.cb_host`
   - Host iOS: `com.clubblackout.cbHost`
   - Player Android/iOS: `com.clubblackout.player`
5. For Host iOS email-link completion, enable Associated Domains with:
   - `applinks:cb-reborn.web.app`

If these package/bundle IDs differ in your Firebase projects, update the auth gate settings before release.

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourorg/club-blackout-reborn.git
   cd club-blackout-reborn
   ```

2. **Install dependencies**

   ```bash
   # Install package dependencies first
   cd packages/cb_models && flutter pub get && cd ../..
   cd packages/cb_logic && flutter pub get && cd ../..
   cd packages/cb_theme && flutter pub get && cd ../..
   cd packages/cb_comms && flutter pub get && cd ../..

   # Install app dependencies
   cd apps/player && flutter pub get && cd ../..
   cd apps/host && flutter pub get && cd ../..
   ```

3. **Generate code**
   Run the build runner for models, logic, and host app:

   ```bash
   cd packages/cb_models
   dart run build_runner build --delete-conflicting-outputs

   cd ../cb_logic
   dart run build_runner build --delete-conflicting-outputs

   cd ../../apps/host
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run tests**

   ```bash
   cd packages/cb_logic
   flutter test
   ```

5. **Launch the apps**

   **Gemini API key (required for AI narration):**

   ```powershell
   # Current key for this environment
   $env:GEMINI_API_KEY="<YOUR_GEMINI_API_KEY>"
   ```

   **Player App (Mobile/Web):**

   ```bash
   cd apps/player
   flutter run --dart-define=GEMINI_API_KEY=$env:GEMINI_API_KEY
   ```

   **Host App (Desktop/Tablet):**

   ```bash
   cd apps/host
   flutter run -d <device-id> --dart-define=GEMINI_API_KEY=$env:GEMINI_API_KEY
   ```

### Build + Install (Android Host, Windows)

PowerShell note: use `;` to chain commands (PowerShell 5.1 does not support `&&`).

#### Debug APK

```powershell
cd apps/host
flutter build apk --debug
adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
```

#### Release APK

```powershell
cd apps/host
flutter build apk --release
adb install -r "build\app\outputs\flutter-apk\app-release.apk"
```

### One-Click Firebase Deploy (Windows)

From repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_firebase.ps1
```

Options:

```powershell
# deploy hosting only
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_firebase.ps1 -HostingOnly

# deploy Firestore rules only
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_firebase.ps1 -RulesOnly

# skip web build and deploy using existing apps/player/build/web output
powershell -ExecutionPolicy Bypass -File .\scripts\deploy_firebase.ps1 -SkipBuild
```

Notes:
- Script uses `GOOGLE_APPLICATION_CREDENTIALS` if set.
- If not set, it automatically falls back to `.secrets/firebase-adminsdk.json`.
- Requires Firebase CLI (`npm install -g firebase-tools`).

## 📦 Package Overview

### `cb_theme`

The visual heart of the app. Implements the "Neon Glass" aesthetic using Material 3.

- **Key Components**: `CBMessageBubble`, `CBGlassTile`, `CBPhaseInterrupt`, `CBRoleIDCard`.
- **Typography**: Roboto Condensed (headers) + Roboto (body/labels) via `CBTypography`.
- **Colors**: Radiant neon palette (turquoise + pink) via `CBColors`, with role-hue shimmer helpers for role cards and guide surfaces.

### `cb_logic`

The brain of the operation.

- **GameProvider**: Manages the entire game state, rules, "God Mode" logic, and **Bot Simulation**.
- **Persistence**: Handles saving/loading games and tracking "Games Night" stats.

### `cb_comms`

The nervous system.

- **GameSessionManager**: Handles heartbeat logic, presence, and action queues.
- **Bridges**: Abstracts communication strategies (WebSocket vs. Firestore).

## ✅ Latest Updates (Feb 2026)

- **Autonomous Bots:** Added capability to add bot players in Lobby and simulate their turns in Game Control. Useful for solo testing and filling rosters.
- **Streamlined Auth & Onboarding:**
    - **Player App:** "Guest List Check" -> "VIP Pass" flow. Merged connection screen into Home for a seamless "Lobby" feel.
    - **Host App:** "Biometric Security" -> "Manager License" flow.
- **Navigation Overhaul:** Host App now uses a robust `NavigationDrawer` with Riverpod state management, eliminating "double scaffold" visual bugs.
- **Club Bible Polish:** The "Operatives" tab now uses the high-fidelity `CBRoleIDCard` widget for a consistent visual identity.
- **Prismatic/Shimmer UI:** `CBGlassTile(isPrismatic: true)` enables the animated oil-slick overlay (“The Shimmer”).
- **Global background + dynamic seed:** all screens default to the shared background asset via `CBPrismScaffold`.

## 🔜 TODO (Next Implementation Targets)

- **Ghost Lounge + Dead Pool** (full player + host experience integration)
- **Multi-slot save system** (beyond single active recovery save)
- **Release signing** (proper keystore + CI build artifacts)
- **Host parity checklist** (canonical list lives in `AGENT_CONTEXT.md`)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This workspace does not include a single root `LICENSE` file. See the package-level LICENSE files under `packages/`.

---

**Play responsibly. Trust no one. Find the dealers.** 🎭
