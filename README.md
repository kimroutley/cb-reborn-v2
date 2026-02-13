# Club Blackout Reborn 🎭

**A high-tech, social deduction party game set in a neon-drenched nightclub.**
Track down the dealers before they take over the party!

## 🎮 About

Club Blackout Reborn is a multiplayer social deduction game where **Party Animals** must identify and eliminate the **Dealers (Club Staff)** hidden among them. The game blends the classic mechanics of Mafia/Werewolf with a modern, "Neon Glass Nightclub" aesthetic and a group chat-inspired interface.

### The Vibe: "Neon Glass Nightclub"

The game is designed to feel like you're inside a dark, upscale nightclub with neon accent lighting. The UI mimics a high-tech group chat feed, immersing players in a cyber-noir narrative.

### Key Features

- **🎭 30+ Unique Roles** - From the **Bouncer** and **Medic** to the chaotic **Messy Bitch** and **Drama Queen**.
- **💬 Chat Feed Interface** - Game events, narration, and actions are presented as a live, interactive chat stream.
- **⚡ God Mode** - The Host has full control with a **"Nerve Center" Dashboard**: **Sin Bin** (temporarily remove disruptive players), **Shadow Ban** (allow speech while hiding messages), and **Mute** (silence players instantly).
- **✨ Prismatic Glass UI** - Optional "oil slick" shimmer overlay for glass tiles (`CBGlassTile.isPrismatic`).
- **👻 Ghost Lounge** *(roadmap)* - Eliminated players enter a spectator area with a "Dead Pool" betting system.
- **📱 Biometric ID** *(roadmap)* - "Hold to Reveal" role identity header for secure, dramatic role checking.
- **☁️ Dual-Mode Sync** - Play locally via WebSocket (low latency) or online via Firebase (cloud sync).
- **📊 Spicy Recap** - Dual-track game reports: detailed truths for the Host, teasers for the players.
- **🌃 Games Night Stats** - Track sessions across multiple games with a "Spotify Wrapped" style recap.

## 🏗️ Architecture

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

### Firebase Auth Preflight (Quick Check)

Before testing sign-in, confirm all 5 are true:

- [ ] **Email/Password** provider is enabled.
- [ ] **Email link (passwordless)** provider is enabled.
- [ ] `cb-reborn.web.app` is listed in Authentication authorized domains.
- [ ] Continue URL matches implementation (`/email-link-signin?app=host|player`).
- [ ] Host/Player Android+iOS IDs in code match Firebase app registrations.

### Firebase Email Link Troubleshooting

- `auth/invalid-action-code`
   - Cause: expired/consumed/malformed email link.
   - Fix: request a fresh sign-in link and open the newest email only.
- `auth/unauthorized-continue-uri`
   - Cause: continue URL domain is not authorized in Firebase Auth.
   - Fix: add `cb-reborn.web.app` (or your custom domain) in Authentication authorized domains.
- `auth/invalid-email` or `auth/missing-email`
   - Cause: callback is opened without matching pending email context.
   - Fix: complete link sign-in on the same device/browser used to request the link, or re-enter the same email and retry.
- `auth/operation-not-allowed`
   - Cause: Email Link provider not enabled.
   - Fix: enable both **Email/Password** and **Email link (passwordless)** in Firebase Console.
- Link opens app but does not sign in
   - Cause: bundle/package IDs in `ActionCodeSettings` do not match your Firebase app registration.
   - Fix: align Host/Player Android package + iOS bundle IDs with Firebase project app settings.

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

   **Player App (Mobile/Web):**

   ```bash
   cd apps/player
   flutter run
   ```

   **Host App (Desktop/Tablet):**

   ```bash
   cd apps/host
   flutter run -d <device-id>
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

- **Key Components**: `CBMessageBubble`, `CBGlassTile`, `CBPhaseInterrupt`.
- **Typography**: Roboto Condensed (headers) + Roboto (body/labels) via `CBTypography`.
- **Colors**: Radiant neon palette (turquoise + pink) via `CBColors`, with role-hue shimmer helpers for role cards and guide surfaces.

### `cb_logic`

The brain of the operation.

- **GameProvider**: Manages the entire game state, rules, and "God Mode" logic.
- **Persistence**: Handles saving/loading games and tracking "Games Night" stats.

### `cb_comms`

The nervous system.

- **GameSessionManager**: Handles heartbeat logic, presence, and action queues.
- **Bridges**: Abstracts communication strategies (WebSocket vs. Firestore).

## ✅ Feb 12, 2026 Update (for future builds)

- **Host Android splash hang fix:** ensure Host calls `Hive.initFlutter()` before `PersistenceService.init()`.
- **Prismatic/Shimmer UI:** `CBGlassTile(isPrismatic: true)` enables the animated oil-slick overlay (“The Shimmer”).
- **Radiant palette default:** `CBColors.neonBlue/neonPink` now alias to the radiant turquoise/pink palette.
- **Role-hue shimmer exceptions:** role cards and role-guide surfaces now use role-derived shimmer (`roleColorFromHex`, `roleShimmerStops`) instead of forcing pink/turquoise only.
- **Club Bible parity:** Host guides now mirror Player trading-card style and role detail polish.
- **Global background + dynamic seed:** all screens default to the shared background asset via `CBPrismScaffold`, and Host/Player startup sample a seed color from that image with safe fallback.
- **Host build verified:** latest Host Android release APK was built successfully with these updates.

## 🔜 TODO (Next Implementation Targets)

- **Ghost Lounge + Dead Pool** (player + host experience)
- **Biometric/secure role reveal UX**
- **Multi-slot save system** (beyond single active recovery save)
- **Navigation audit** (back-stack consistency + drawer parity across screens)
- **Release signing** (proper keystore + CI build artifacts)
- **Host parity checklist** (canonical list lives in `AGENT_CONTEXT.md` → “Forward TODO (Host parity)”)

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
