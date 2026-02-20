# Authority Map

## Canonical sources

- **Monorepo technical constraints:** `docs/architecture/agent-context.md`
- **Role mechanics reference:** `docs/architecture/role-mechanics.md`
- **UI style/design reference:** `docs/architecture/style-guide.md`
- **Agent operating rules:** `AGENTS.md`
- **Project overview/onboarding:** `README.md`
- **Rolling operational status:** `docs/operations/status.md`
- **QA smoke runbook (live):** `docs/operations/qa-smoke-checklist.md`
- **Player startup cache QA runbook:** `docs/operations/player-startup-cache-qa-checklist.md`
- **Release snapshots:** `docs/releases/<YYYY-MM-DD>/`
- **Awards feature planning/catalog:** `docs/features/awards/`
- **Reusable PR template:** `docs/development/templates/pr-body.md`
- **Commit workflow checklist:** `docs/development/checklists/commit-checklist.md`

## Non-canonical historical content

Files in `docs/archive/` are retained for historical context only.

## Update triggers

- Update `docs/architecture/agent-context.md` when architecture, build-order constraints, or critical gotchas change.
- Update `docs/operations/status.md` when release posture, blockers, or validation state changes.
- Add a new `docs/releases/<date>/` folder for each release cycle.

## Ownership

- Architecture docs: core maintainers
- Operations docs: release operator
- Feature docs: feature owner
- Package docs/changelogs: package owner
