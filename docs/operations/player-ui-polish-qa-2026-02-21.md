
# Player UI Polish QA Checklist + Log (2026-02-21)

## Scope

This checklist validates the player-side polish pass for recent lobby/game-flow updates:

- Connect entry flow polish (uplink status panel + animated failure messaging)
- Claim flow polish (identity availability/status panel + clearer CTA state)
- Lobby status modernization (inline status panel + animated state messaging)
- Themed feedback consistency (themed snackbar for profile handle updates)
- Game action surface modernization (themed bottom action panels)
- Action tile readability refinement (spacing/typography tune)

## Automated verification completed

- Command: `flutter analyze .` (from `apps/player`)
- Result: ✅ No issues found
- Last run: 2026-02-21

## Manual smoke checklist (Player)

### A) Lobby status clarity

- [ ] Lobby status panel is visible and legible on common phone sizes
- [ ] Status icon/color updates with lifecycle state (waiting players, setup, ready)
- [ ] Status title and detail transition cleanly without jitter
- [ ] Roster feed remains readable after status-panel addition

### A1) Connect flow clarity

- [ ] Uplink status panel appears and updates for ready/error states
- [ ] Join URL parse flow still pre-fills join code correctly
- [ ] Connection failure feedback transitions cleanly and remains readable
- [ ] `INITIATE UPLINK` path still navigates to claim on successful join

### A2) Claim flow clarity

- [ ] Identity availability panel shows count when nothing selected
- [ ] Availability panel switches to selected identity when user taps a player
- [ ] CTA label switches (`SELECT AN IDENTITY` -> `CONFIRM IDENTITY`) correctly
- [ ] Claim submission still dispatches successfully

### B) Profile handle save feedback

- [ ] Save username success uses themed feedback and remains readable
- [ ] Validation failures (short/duplicate username) surface clearly
- [ ] Save in-progress state (`SAVING...`) behaves correctly

### C) Game action bars

- [ ] Setup-phase `CONFIRM IDENTITY` bar renders as themed panel
- [ ] In-round action panel renders consistently with role-accent border
- [ ] Action panel does not overlap core content on small screens
- [ ] Tap targets remain responsive and reliable

### D) Game action tile readability

- [ ] Header/subheader typography is legible and balanced
- [ ] Instruction text remains readable across role colors
- [ ] Tile content spacing feels consistent with surrounding panel

### E) Functional continuity

- [ ] Joining flow still reaches claim/lobby/game as expected
- [ ] Role confirm action still dispatches successfully
- [ ] Target selection actions still open selection sheet and submit correctly

## Execution log

- Date: 2026-02-21
- Tester: _TBD_
- Device(s): _TBD_
- Build/hash: _TBD_
- Outcome summary:
  - Passed: _TBD_
  - Failed: _TBD_
  - Follow-ups: _TBD_

## Notes

- Re-run `flutter analyze .` in `apps/player` after any follow-up UI tweaks.
- Capture screenshots for any clipping/overlap in bottom action panels.
