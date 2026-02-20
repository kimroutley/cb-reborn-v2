# Commit Checklist (Clean Split)

Use this checklist to stage only intended files and avoid accidental mixed commits.

> PowerShell note: use `;` to chain commands.

Optional helper script (interactive, grouped staging + commit prompts):

```powershell
cd "C:\Club Blackout Reborn"
.\scripts\commit_split.ps1
```

Preview only (no staging, no commits):

```powershell
cd "C:\Club Blackout Reborn"
.\scripts\commit_split.ps1 -DryRun
```

---

## 1) Player deep-link guardrails + navigation tests

- [ ] Stage files
  - `apps/player/lib/screens/home_screen.dart`
  - `apps/player/lib/screens/connect_screen.dart`
  - `apps/player/test/join_link_debounce_test.dart`
  - `apps/player/test/connect_screen_navigation_guard_test.dart`

Optional stage command:

```powershell
git add apps/player/lib/screens/home_screen.dart
git add apps/player/lib/screens/connect_screen.dart
git add apps/player/test/join_link_debounce_test.dart
git add apps/player/test/connect_screen_navigation_guard_test.dart
```

Commit:

```powershell
git commit -m "fix(player): debounce join links and prevent duplicate claim navigation"
```

---

## 2) Role mechanics parity (night actions) + tests

- [ ] Stage files
  - `packages/cb_logic/lib/src/night_actions/actions/sober_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/roofi_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/bouncer_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/bartender_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/club_manager_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/messy_bitch_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/lightweight_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/dealer_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/attack_dog_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/messy_bitch_kill_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/medic_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/silver_fox_action.dart`
  - `packages/cb_logic/lib/src/night_actions/actions/whore_action.dart`
  - `packages/cb_logic/lib/src/night_actions/night_action_strategy.dart`
  - `packages/cb_logic/test/night_resolution_test.dart`
  - `packages/cb_logic/test/game_resolution_logic_test.dart`

Commit:

```powershell
git commit -m "feat(cb_logic): align night action messaging with mechanics spec"
```

---

## 3) Host setup UX + release/CI hardening

- [ ] Stage files
  - `apps/host/lib/screens/lobby_screen.dart`
  - `apps/host/android/key.properties.example`
  - `apps/host/README.md`
  - `.github/workflows/ci-cd.yml`

Commit:

```powershell
git commit -m "feat(host): add manual role assignment UX and harden release CI"
```

---

## 4) Docs + handoff sync

- [ ] Stage files
  - `README.md`
  - `PROJECT_DEVELOPER_HANDBOOK.md`
  - `GEMINI_HANDOFF_LIST.txt`
  - `COMMIT_CHECKLIST.md`

Commit:

```powershell
git commit -m "docs: sync roadmap and verification handoff status"
```

---

## Keep out (unless intentional)

- [ ] Do **not** include generated/runtime artifacts such as:
  - `apps/player/widget_test_output.txt`
- [ ] Do **not** include unrelated workspace/editor files unless intended:
  - `*.code-workspace`
- [ ] Before each commit, verify staged files:

```powershell
git diff --staged --name-only
```
