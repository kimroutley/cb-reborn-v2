# Host Lobby UI QA Checklist + Log (2026-02-21)

## Scope

This checklist validates the host lobby polish pass completed on 2026-02-21:

- Visual hierarchy and spacing rhythm updates
- Join beacon UX improvements (copy code/link, expanded QR modal)
- Bottom action tools polish (readiness status + functional start gating)
- Micro-motion behavior (status transitions and subtle readiness motion)

## Automated verification completed

- Command: `flutter analyze .` (from `apps/host`)
- Result: ✅ No issues found
- Last run: 2026-02-21

## Manual smoke checklist (Host Lobby)

### A) Join beacon + QR usability

- [ ] Join code is clearly visible and readable at normal operator distance
- [ ] **Copy code** action copies exact lobby code and shows success feedback
- [ ] QR tile opens expanded modal on tap
- [ ] Expanded modal shows large QR + correct join code
- [ ] **Copy code** from modal works
- [ ] **Copy link** from modal works
- [ ] Inline join link card supports copy and remains selectable

### B) Cloud link state presentation

- [ ] Connecting state displays `CLOUD LINK: ESTABLISHING...`
- [ ] Ready state displays `CLOUD LINK: ACTIVE`
- [ ] Error state displays retry-required text + retry affordance
- [ ] Transition between states feels smooth (no visual jump/pop)

### C) Bottom controls behavior

- [ ] Lobby readiness strip appears and updates based on player count
- [ ] Start action disabled below minimum players
- [ ] Start action enabled at/above minimum players
- [ ] Label transitions remain context-correct (`Need X More` / `Start Game`)
- [ ] Navigation grouping and labels are visually clear

### D) Typography/spacing consistency

- [ ] Header/subheader hierarchy is legible and balanced
- [ ] Inter-panel vertical spacing appears consistent
- [ ] Config option labels/values are easy to scan
- [ ] No text clipping/truncation at common host resolutions

### E) Functional flow checks

- [ ] Add Bot works in debug mode from lobby control area
- [ ] Start Game still transitions to Game screen when conditions are met
- [ ] Manual role assignment warning still blocks invalid starts when enabled

## Execution log

- Date: 2026-02-21
- Tester: _TBD_
- Host platform/device: _TBD_
- Build/hash: _TBD_
- Outcome summary:
  - Passed: _TBD_
  - Failed: _TBD_
  - Follow-ups: _TBD_

## Notes for handoff

- If any visual issue is found, capture a screenshot and annotate affected section (Join Beacon / Cloud Status / Bottom Controls).
- Re-run `flutter analyze .` in `apps/host` after any follow-up fix.

