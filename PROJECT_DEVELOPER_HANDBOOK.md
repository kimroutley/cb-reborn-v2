# Club Blackout Reborn: Developer Handbook

> **Last Updated:** February 19, 2026 (UI Overhaul + Release Hardening)
> **Project Location:** `C:\Club Blackout Reborn\`
> **Technical Reference:** See [`AGENT_CONTEXT.md`](./AGENT_CONTEXT.md) for deep technical details, build order, and known issues.

---

## 0. Project Overview & Vision

### About Club Blackout Reborn

Club Blackout is a **social deduction party game** set in a neon-drenched nightclub. It features a high-utility **Host App** (Command Center) and a high-fidelity **Player App** (Companion).

**Core Gameplay Loop:**
1. **Lobby** — Dynamic join via IP/QR or Cloud Code. **Bot Support**: Hosts can add automated bots to fill the roster.
2. **Setup** — Lore-driven role assignment with immersive flicker effects.
3. **Night** — Synced cinematic narration. Host triggers global effects (Bass Drops, Glitches).
4. **Day** — Casualty reports and social deduction. **Bot Simulation**: Bots can autonomously vote and perform roles via the Host's "Simulate Bots" command.
5. **Resolution** — Death triggers and win condition checks.

### Alliances & Lore (Strict Enforcement)
- **The Dealers (Killers)**: Hidden antagonists seeking to eliminate Party Animals.
- **The Party Animals (Innocents)**: Social majority seeking to exile Dealers via vote.
- **Wildcards (Variables)**: Solo agents with shifting goals (Messy Bitch, Creep, etc.).

### The Vibe: "Radiant Neon Nightclub"
- **Dark-First**: Deep blacks (`voidBlack`) providing high contrast for neons.
- **Glassmorphism**: 10.0 sigma blur, subtle borders, and animated "Oil Slick" shimmer (`CBGlassTile`).
- **Synced Immersion**: Haptics, sounds, and visual effects are synchronized between Host and Player devices via the Script Engine.

---

## 1. Technical Architecture & Stack

### Stack Summary
- **Frontend**: Flutter 3.38+ (Material 3, Dynamic Color).
- **Logic**: Riverpod 3.x, Freezed, Hive CE (Persistence).
- **Cloud**: Firebase (Firestore, Auth, Analytics).
- **Comm**: Dual-track (Local WebSocket + Cloud Firestore).

### AI Narration Engine (Gemini 1.5 Flash)
- **Context-Aware**: Narrations dynamically shift tone based on `dayCount` and `aliveCount` (e.g., Early-game energy vs Late-game desperation).
- **Host Personalities**: 5 selectable antagonistic/pragmatic profiles:
    - **The Cynic**: Gritty, hard-boiled, views players as data points.
    - **Protocol 9**: Corrupted AI, treats players as expendable assets.
    - **The Ice Queen**: Seductive and cold, finds the struggle amusing.
    - **The Promoter**: High-energy, treats carnage as house entertainment.
    - **The Bouncer**: Cynical, treats players like trash that needs sorting.
- **Zero-Config**: API Key is baked into the logic for immediate out-of-the-box functionality.
- **Live Preview**: Hosts can "Preview Voice" directly in settings to test personality styles.

### Authentication & Identity Gate (Updated Flow)
- **Unified Onboarding**: Both apps follow a cinematic Splash -> Auth -> Moniker Setup flow.
- **Player App**: "Guest List Check" -> "VIP Pass" (Google) -> "Print ID" (Moniker). The Home Screen now serves as the primary Lobby entry point.
- **Host App**: "Biometric Security" -> "Manager Badge" (Google) -> "Issue License" (Moniker).
- **The Moniker Gate**: A mandatory Firestore profile check. Users cannot enter the club until a unique moniker is established and linked to their UUID.

---

## 2. Design System: cb_theme

### Visual "Source of Truth"
**READ THIS FIRST:** [`STYLE_GUIDE.md`](./STYLE_GUIDE.md) is the authoritative reference for all visual elements.

The **CB Visuals** folder defines character colors. UI must derive colors from `role.colorHex`.

### UI Philosophy: "Neon Glass"
- **High Friction, High Reward**: Use animations (`CBFadeSlide`) and haptics to make every button press feel like interacting with a physical nightclub terminal.
- **Tertiary Accents**: Use the `tertiary` color scheme for AI and narrative-driven components to separate them from game logic (primary) and system settings (secondary).
- **ID Cards**: Use `CBRoleIDCard` for consistent, high-fidelity role presentation in both apps (Reveal Screen & Club Bible).

---

## 3. Development Workflow

### Setup & Build (Windows/PowerShell)
```powershell
cd "C:\Club Blackout Reborn"
# Get deps
cd packages/cb_models ; flutter pub get ; cd ../cb_logic ; flutter pub get ; cd ../cb_theme ; flutter pub get ; cd ../cb_comms ; flutter pub get
cd ../../apps/player ; flutter pub get ; cd ../host ; flutter pub get

# Generate code
cd ../../packages/cb_models ; dart run build_runner build --delete-conflicting-outputs
cd ../cb_logic ; dart run build_runner build --delete-conflicting-outputs
cd ../../apps/host ; dart run build_runner build --delete-conflicting-outputs
```

### Verified Build Commands
- **Release APK**: `cd apps/host ; flutter build apk --release`
- **Verification**: `flutter analyze` + `flutter test`

---

## 4. Current Status & Roadmap

### Recent Achievements
- [x] **Autonomous Bots**: Added bot player logic (`addBot`, `simulateBotTurns`) for solo testing and roster filling.
- [x] **Streamlined Auth**: Replaced multi-step wizards with direct, immersive "Club Entry" flows.
- [x] **Navigation Refactor**: Implemented `NavigationDrawer` with Riverpod state in Host App to fix UI layering bugs.
- [x] **Club Bible Polish**: Updated "Operatives" list to use high-fidelity ID Cards.
- [x] **Antagonistic AI Overhaul**: 5 selectable pragmatic host personalities.
- [x] **Unified Auth**: Google Sign-In + Moniker Gate implemented for Host & Player.
- [x] **Manual Setup UX**: Host manual role assignment upgraded to drag-and-drop in Lobby setup.
- [x] **Release Hardening**: Host Android signing template + CI host release artifact path added.
- [x] **CI Optimization**: Workflow concurrency/caching/action-version refresh to reduce pipeline runtime.

### Build Status (Feb 19, 2026)

| App | Status | Notes |
| :--- | :--- | :--- |
| **Host** | ✅ Verified | 0 Analyzer errors. Build successful. UI Overhauled. |
| **Player** | ✅ Verified | Auth parity with Host. 0 Analyzer errors. UI Overhauled. |

### Remaining Manual Validation

- [ ] Real-device multiplayer checklist execution (QR scan, deep-link runtime, local/cloud switching under active lobby)
- [ ] Release-signing secret provisioning in GitHub environment for `main` branch enforcement

---

## 5. Host iOS Email Link Auth: End-to-End Verification
*(Refer to original handbook for detailed iOS deep-link verification steps)*
