# Polish & Feature Tasks

> **Last Updated:** 2026-02-26  
> **Completed Feb 2026 sprint:** See [archive](../archive/remaining-polish-tasks-2026-02.md) for the list of implemented items (strategy guides, operatives/Alliance Graph, drawer refactor, Blackbook centering, Gemini narrative runtime).

This file tracks the **future polish backlog**. Move items here as they’re identified; move completed items to the archive when a sprint is done.

---

## Future polish (backlog)

- [x] **Local-mode session restore (T7):** Restore host address and join code on relaunch when the last session was local (ws://). Implemented in `player_bootstrap_gate.dart` and `home_screen.dart` (2026-02-28).
- [ ] **Player web PWA:** Install prompt, offline shell, and optional install-to-home-screen flow for the player web app.
- [ ] **Host APK size:** Explore app bundle / split APKs or asset on-demand to reduce release APK size if needed.
- [ ] **Accessibility pass:** Screen-reader labels added for connect flow (scan button, join code field). Remaining: lobby, game, role reveal; focus order; contrast checks.
- [ ] **Analytics / crash reporting:** Optional first-party or Firebase Crashlytics integration for release builds (with consent).
