# Today’s Runbook — 2026-02-20

Purpose: close remaining operational blockers and move from code-stable to release-ready.

Reporting helper: `docs/operations/STATUS_UPDATE_TEMPLATE_2026-02-20.md`

## 1) Preflight (15 min)

Owner: DevOps / Release

- [ ] Confirm working branch is `main` and workspace is clean.
- [ ] Confirm latest CI passed on `main`.
- [ ] Open `docs/operations/qa-smoke-checklist.md` and use it as live checklist during execution.

Pass criteria:

- Clean git state, green CI baseline, checklist open and ready.

---

## 2) Deploy Secrets Provisioning (30 min)

Owner: DevOps

Provision GitHub repository secrets (Actions):

- [ ] `FIREBASE_SERVICE_ACCOUNT`
- [ ] `FIREBASE_PROJECT_ID`
- [ ] `FIREBASE_TOKEN`

Pass criteria:

- All three secrets exist with non-empty values.
- CI preflight job no longer reports missing secret warnings.

---

## 3) Real-Device Multiplayer Matrix (90–120 min)

Owner: QA + Host Tester + Player Tester

### A. Local mode

- [ ] Host creates local lobby.
- [ ] Player joins and roster sync is correct.
- [ ] Run at least one night/day cycle.
- [ ] Validate clean leave/disconnect behavior.

### B. Cloud mode

- [ ] Host signs in and creates cloud lobby.
- [ ] Player joins (prefer second network profile/device).
- [ ] Validate stable sync through phase transitions.
- [ ] Simulate brief network drop and confirm reconnect recovery.

### C. Mode switching

- [ ] Validate LOCAL → CLOUD in same runtime.
- [ ] Validate CLOUD → LOCAL in same runtime.
- [ ] Confirm no stale session/roster leakage.

Pass criteria:

- No stuck transitions, no stale-room bleed, no reconnect lockups.

---

## 4) Deep-Link + QR Join Validation (45–60 min)

Owner: QA

- [ ] Cold-start deep-link join succeeds.
- [ ] Warm-start deep-link join succeeds.
- [ ] Invalid/expired links show expected error handling.
- [ ] QR join success and invalid QR handling verified.

Pass criteria:

- All join paths deterministic and error states user-readable.

---

## 5) Host iOS Email-Link E2E (45–60 min)

Owner: iOS QA / Host QA

- [ ] Request sign-in link from Host app.
- [ ] Open from iOS Mail and deep-link back into app.
- [ ] Confirm authenticated state persists after app restart.
- [ ] Repeat one sign-out/sign-in cycle.

Pass criteria:

- No post-login hang; sign-in persistence is consistent.

---

## 6) Release Decision Gate (15 min)

Owner: Release Lead

- [ ] Review outcomes from sections 2–5.
- [ ] Log failures with repro notes + screenshots.
- [ ] Decide status:
  - **GO** if all pass criteria met.
  - **NO-GO** if any blocker remains.

Decision output template:

```text
Release Decision (2026-02-20): GO | NO-GO
Blockers Remaining: <none | list>
Next Action Owner: <name>
ETA: <date/time>
```

---

## Fast Triage Mapping (if failures appear)

- Multiplayer/session leakage/regression:
  - `apps/host/lib/services/cloud_runtime_bridge.dart`
  - `apps/player/lib/services/player_cloud_bridge.dart`
  - `apps/player/lib/providers/player_session_provider.dart`

- Email-link auth regression:
  - `apps/host/lib/providers/host_session_provider.dart`

- Checklist/ops status updates:
  - `docs/operations/qa-smoke-checklist.md`
  - `docs/operations/status.md`
