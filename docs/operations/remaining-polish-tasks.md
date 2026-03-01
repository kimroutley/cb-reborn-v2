# Polish & Feature Tasks

> **Last Updated:** 2026-02-28  
> **Completed Feb 2026 sprint:** See [archive](../archive/remaining-polish-tasks-2026-02.md) for the list of implemented items (strategy guides, operatives/Alliance Graph, drawer refactor, Blackbook centering, Gemini narrative runtime).

This file tracks the **future polish backlog**. Move items here as they’re identified; move completed items to the archive when a sprint is done.

---

## Future polish (backlog)

**Recent completions:** Chat M3 + player names (send-to chips and feed use player names; theme chips). Host app bundle doc added. Host system UI + void window for Pixel (2026-02-28).

---

## Host app – Pixel / Play Store readiness

- [x] **System UI (status + nav bar):** Transparent bars, light icons for dark theme. Set in `apps/host/lib/main.dart` via `SystemChrome.setSystemUIOverlayStyle`.
- [x] **Window background:** NormalTheme uses `cb_void_black` (#0E1112) so the Android window behind Flutter matches the app (no white flash). `res/values/colors.xml` + `styles.xml`.
- [x] **SafeArea / insets:** Scaffold and persistent phase bar use `SafeArea` (including `top: false` where content goes under app bar). Gesture nav and display cutouts are respected.
- [ ] **Host APK size:** Prefer App Bundle for Play: see [build-host-app-bundle.md](build-host-app-bundle.md).
- [ ] **Analytics / crash reporting:** Optional for release (e.g. Firebase Crashlytics with consent).

## Future polish (backlog)

- [x] **Local-mode session restore (T7):** Restore host address and join code on relaunch when the last session was local (ws://). Implemented in `player_bootstrap_gate.dart` and `home_screen.dart` (2026-02-28).
- [ ] **Player web PWA:** Install prompt exists (banner + beforeinstallprompt). Optional: offline shell, flow refinement.
- [x] **Accessibility pass (player screens):** Screen-reader labels for connect (scan button, join code field, Enter button; connected view: group chat region, Continue to Lounge), lobby (main region, Confirm & Join, chat, Edit profile), game (feed, chat bar), role reveal (role region, Confirm identity), notifications banner (Enable notifications, Install app). Focus order on connect: join code (0), scan (1), Enter (2), Just Browsing (3). Remaining: contrast checks.
- [x] **Accessibility (remaining):** Contrast checks (WCAG AA). Audit in [accessibility-contrast-audit.md](operations/accessibility-contrast-audit.md); tab unselected label set to 0.5 opacity for AA.
