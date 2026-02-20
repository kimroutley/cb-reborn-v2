# QA Smoke Checklist (Rolling)

Use this checklist as the active operational runbook. For historical run evidence, see date-stamped files under `docs/releases/`.

## Latest known findings

- Mode switching and cloud join glitches were reported and mitigated in code; physical re-test required.
- Host iOS email-link post-login hang was reported and mitigated in code; physical re-test required.
- Required Firebase deploy secrets are currently absent.

## Core smoke checks

### Host profile flow

- [ ] Open Profile from drawer
- [ ] Edit username/public ID/avatar/style
- [ ] Validate discard prompt appears on navigation
- [ ] Validate cancel/discard/save behavior and persistence

### Player profile flow

- [ ] Open Profile from drawer
- [ ] Validate unsaved-change prompt and save/discard flow
- [ ] Validate Reload From Cloud behavior

### About / changelog surfaces

- [ ] Verify host/player About metadata and latest updates
- [ ] Verify latest updates presentation constraints

### Hall of Fame navigation

- [ ] Host Home action opens Hall of Fame
- [ ] Player Stats action opens Hall of Fame

## Real-device multiplayer validation

### Local mode

- [ ] Host creates local lobby
- [ ] Player joins and syncs roster
- [ ] Start game and pass at least one night/day cycle
- [ ] Validate clean disconnect/leave behavior

### Cloud mode

- [ ] Host signs in and creates cloud lobby
- [ ] Player joins from second network profile where possible
- [ ] Validate stable sync through phase transitions
- [ ] Validate reconnect recovery after temporary network drop

### Mode switching

- [ ] LOCAL -> CLOUD in same runtime
- [ ] CLOUD -> LOCAL in same runtime
- [ ] Confirm no stale session/roster leakage

## Deep-link + QR

- [ ] Cold-start deep-link join
- [ ] Warm-start deep-link join
- [ ] Invalid/expired link error handling
- [ ] QR join success + invalid QR handling

## Host iOS email-link E2E

- [ ] Request sign-in link from host app
- [ ] Open link from iOS Mail and deep-link back to app
- [ ] Confirm signed-in state persistence after restart
- [ ] Repeat sign-out/sign-in loop once

## Deploy readiness (GitHub)

- [ ] Secrets present with exact names
- [ ] Workflow reads secrets without empty-variable warnings
