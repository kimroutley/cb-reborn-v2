# Documentation Index

> **Last verified:** 2026-02-25

This index catalogues every `.md` file in the Club Blackout Reborn monorepo.
Use it to orient yourself before making changes — every file is listed exactly
once under its primary category.

---

## 1. Core Directives & Standards

The absolute truth for developing within the monorepo. Read these before making
any significant changes.

| File | Purpose |
|------|---------|
| [`PROJECT_DEVELOPER_HANDBOOK.md`](../PROJECT_DEVELOPER_HANDBOOK.md) | Overarching vision, features, setup instructions, and high-level workflow. |
| [`STYLE_GUIDE.md`](../STYLE_GUIDE.md) | The "Design Bible" — Radiant Neon aesthetic, colors, typography, components, interaction design (haptics, animations). |
| [`AGENTS.md`](../AGENTS.md) | Entry-point rules file for AI agents — points to the style guide and architecture context. |
| [`docs/architecture/agent-context.md`](architecture/agent-context.md) | Deep technical context: build order, testing strategies, state management patterns (Riverpod/Freezed), known gotchas. |
| [`docs/architecture/style-guide.md`](architecture/style-guide.md) | Canonical copy of the style guide inside `docs/`. Mirrors `STYLE_GUIDE.md`. |
| [`docs/architecture/role-mechanics.md`](architecture/role-mechanics.md) | Master specification for all game roles, night actions, priorities, and global game mechanics. |
| [`COMPREHENSIVE_ROLE_MECHANICS.md`](../COMPREHENSIVE_ROLE_MECHANICS.md) | Tabular role-mechanics spreadsheet with action types, notifications, logic, and improvement notes. |
| [`docs/governance/authority-map.md`](governance/authority-map.md) | Identifies where the source of truth lives for each domain of the project. |
| [`docs/README.md`](README.md) | Explains the layout, update principles, and purpose of the `docs/` directory. |
| [`.agents/palette.md`](../.agents/palette.md) | Agent learning journal — records past lessons and anti-patterns. |

---

## 2. Package Architecture

The project is a Flutter monorepo. Build order: `cb_models` → `cb_comms` → `cb_logic` → apps.

| Package | README | CHANGELOG | Extra Docs | Purpose |
|---------|--------|-----------|------------|---------|
| `cb_models` | [`README.md`](../packages/cb_models/README.md) | [`CHANGELOG.md`](../packages/cb_models/CHANGELOG.md) | — | Core domain models (Freezed), enums, role definitions, game state, catalogs. Base layer — no internal dependencies. |
| `cb_theme` | [`README.md`](../packages/cb_theme/README.md) | [`CHANGELOG.md`](../packages/cb_theme/CHANGELOG.md) | [`AUDIO_AUDIT.md`](../packages/cb_theme/AUDIO_AUDIT.md), [`assets/audio/README.md`](../packages/cb_theme/assets/audio/README.md) | Design tokens, reusable UI components (`CBGlassTile`, `CBMessageBubble`), haptics, and audio services. Depends on `cb_models`. |
| `cb_comms` | [`README.md`](../packages/cb_comms/README.md) | — | — | Communication layer: Firebase bridge, WebSocket host server, player client, profile repository, offline queue. Depends on `cb_models`. |
| `cb_logic` | [`README.md`](../packages/cb_logic/README.md) | [`CHANGELOG.md`](../packages/cb_logic/CHANGELOG.md) | — | Game engine: Riverpod providers, state transitions, night resolution pipeline, day vote logic, bot simulation. Depends on `cb_models`, `cb_comms`. |

---

## 3. Application Entry Points

The user-facing applications that consume the shared packages.

| App | README | Purpose |
|-----|--------|---------|
| `apps/host` | [`README.md`](../apps/host/README.md) | The "Command Center" (Phone/Android — Pixel 10 Pro). Session creation, game loop execution, God Mode tools, AI recap export. |
| `apps/player` | [`README.md`](../apps/player/README.md) | The "Companion App" (Mobile/Web). Joining sessions, role prompts, voting, game feed, player-side auth flow. |

---

## 4. Features & Design

Domain-specific plans, catalogs, and design recommendations.

| File | Purpose |
|------|---------|
| [`docs/features/awards/plan.md`](features/awards/plan.md) | Master plan for the Role Awards and Hall of Fame feature. |
| [`docs/features/awards/name-icon-catalog.md`](features/awards/name-icon-catalog.md) | Canonical title/icon metadata for every role award. |
| [`docs/features/awards/history/build-instructions.md`](features/awards/history/build-instructions.md) | Historical merge companion for the awards build (superseded by `plan.md`). |
| [`docs/features/host-ui-polish-recommendations.md`](features/host-ui-polish-recommendations.md) | UI polish tasks and recommendations for the host app. |

---

## 5. Current State & Operations

Rolling status, QA checklists, and runbooks that track the live state of the project.

| File | Purpose |
|------|---------|
| [`docs/operations/status.md`](operations/status.md) | Rolling live status of the project. |
| [`docs/operations/qa-smoke-checklist.md`](operations/qa-smoke-checklist.md) | Canonical smoke-test checklist for releases. |
| [`docs/operations/player-ui-polish-qa-2026-02-21.md`](operations/player-ui-polish-qa-2026-02-21.md) | QA checklist for the player app UI polish pass. |
| [`docs/operations/host-lobby-ui-qa-2026-02-21.md`](operations/host-lobby-ui-qa-2026-02-21.md) | QA checklist for the host lobby UI refactor. |
| [`docs/operations/player-startup-cache-qa-checklist.md`](operations/player-startup-cache-qa-checklist.md) | QA checklist for player app startup and cache behavior. |
| [`docs/COMMUNICATION_AND_PUSH.md`](COMMUNICATION_AND_PUSH.md) | Host–player communication audit, push notification event catalog, and target architecture. |
| [`docs/operations/LETS_DO_IT_RUNBOOK.md`](operations/LETS_DO_IT_RUNBOOK.md) | **Unblock CI deploy, VAPID/push setup, and real-device validation** — single runbook. |
| [`docs/operations/GITHUB_SECRETS_CHECKLIST.md`](operations/GITHUB_SECRETS_CHECKLIST.md) | Tick list for adding the 3 GitHub Actions secrets (Firebase deploy). |
| [`docs/operations/TODAYS_RUNBOOK_2026-02-20.md`](operations/TODAYS_RUNBOOK_2026-02-20.md) | Day-of runbook for the 2026-02-20 work session. |
| [`docs/operations/runbook-execution-2026-02-20.md`](operations/runbook-execution-2026-02-20.md) | Execution log for the 2026-02-20 runbook. |
| [`docs/operations/STATUS_UPDATE_TEMPLATE_2026-02-20.md`](operations/STATUS_UPDATE_TEMPLATE_2026-02-20.md) | Template used for status updates on 2026-02-20. |
| [`docs/operations/STATUS_PATCH_AFTER_SECTION2_2026-02-20.md`](operations/STATUS_PATCH_AFTER_SECTION2_2026-02-20.md) | Status patch after completing section 2 of the 2026-02-20 runbook. |
| [`docs/operations/STATUS_PATCH_AFTER_SECTION3_2026-02-20.md`](operations/STATUS_PATCH_AFTER_SECTION3_2026-02-20.md) | Status patch after completing section 3 of the 2026-02-20 runbook. |
| [`docs/operations/STATUS_PATCH_AFTER_SECTION5_2026-02-20.md`](operations/STATUS_PATCH_AFTER_SECTION5_2026-02-20.md) | Status patch after completing section 5 of the 2026-02-20 runbook. |

---

## 6. Releases

Immutable date-stamped release artifacts. Each folder captures the state of a specific deployment.

### 2026-02-20

| File | Purpose |
|------|---------|
| [`docs/releases/2026-02-20/RELEASE_HANDOFF.md`](releases/2026-02-20/RELEASE_HANDOFF.md) | Handoff document for the 2026-02-20 release. |

### 2026-02-19

| File | Purpose |
|------|---------|
| [`docs/releases/2026-02-19/release-notes.md`](releases/2026-02-19/release-notes.md) | Release notes for the major UI Overhaul + Release Hardening update. |
| [`docs/releases/2026-02-19/release-handoff.md`](releases/2026-02-19/release-handoff.md) | Internal handoff document for the 2026-02-19 release. |
| [`docs/releases/2026-02-19/status-brief.md`](releases/2026-02-19/status-brief.md) | Brief status snapshot at the time of release. |
| [`docs/releases/2026-02-19/qa-smoke-checklist.md`](releases/2026-02-19/qa-smoke-checklist.md) | Smoke-test checklist executed for this release. |
| [`docs/releases/2026-02-19/deployment-verification.md`](releases/2026-02-19/deployment-verification.md) | Post-deployment verification results. |
| [`RELEASE_HANDOFF_2026-02-19.md`](../RELEASE_HANDOFF_2026-02-19.md) | Root-level copy of the 2026-02-19 handoff (pending migration to `docs/releases/`). |

---

## 7. Development Workflows

Guidelines for contributing and managing the codebase.

| File | Purpose |
|------|---------|
| [`docs/development/checklists/commit-checklist.md`](development/checklists/commit-checklist.md) | Steps to follow before committing code. |
| [`docs/development/templates/pr-body.md`](development/templates/pr-body.md) | Template for pull request descriptions. |

---

## 8. Archive

Historical snapshots, superseded plans, and one-off artifacts retained for provenance. See [`docs/archive/README.md`](archive/README.md) for archival policy.

| File | Purpose |
|------|---------|
| [`docs/archive/README.md`](archive/README.md) | Archival policy and migration state. |
| [`docs/archive/analysis-and-recommendations-2026-02.md`](archive/analysis-and-recommendations-2026-02.md) | February 2026 analysis and recommendations snapshot. |
| [`docs/archive/awards-system-plan-2026-02.md`](archive/awards-system-plan-2026-02.md) | Original awards system plan (superseded by `docs/features/awards/plan.md`). |
| [`docs/archive/awards-name-icon-catalog-2026-02.md`](archive/awards-name-icon-catalog-2026-02.md) | Earlier awards icon catalog (superseded by `docs/features/awards/name-icon-catalog.md`). |
| [`docs/archive/player-app-plan.md`](archive/player-app-plan.md) | Original player app design plan. |
| [`docs/archive/pr-description-2026-02-19.md`](archive/pr-description-2026-02-19.md) | PR description snapshot from the 2026-02-19 release. |
| [`docs/archive/setup-alignment-todo.md`](archive/setup-alignment-todo.md) | Historical setup alignment checklist. |
| [`docs/archive/todo-report-2026-02.md`](archive/todo-report-2026-02.md) | February 2026 TODO tracking report. |

---

## 9. Root-Level Entrypoints

Files at the repository root that serve as entrypoints or quick references.

| File | Purpose |
|------|---------|
| [`README.md`](../README.md) | General overview, installation, and getting started. |
| [`PROJECT_DEVELOPER_HANDBOOK.md`](../PROJECT_DEVELOPER_HANDBOOK.md) | *(Listed in Section 1)* |
| [`STYLE_GUIDE.md`](../STYLE_GUIDE.md) | *(Listed in Section 1)* |
| [`AGENTS.md`](../AGENTS.md) | *(Listed in Section 1)* |
| [`COMPREHENSIVE_ROLE_MECHANICS.md`](../COMPREHENSIVE_ROLE_MECHANICS.md) | *(Listed in Section 1)* |
| [`RELEASE_HANDOFF_2026-02-19.md`](../RELEASE_HANDOFF_2026-02-19.md) | *(Listed in Section 6)* |

---

## Summary

Club Blackout Reborn is a Flutter monorepo requiring strict adherence to its
build order (`cb_models` → `cb_comms` → `cb_logic` → apps) and visual
guidelines (`STYLE_GUIDE.md`). State is managed immutably via Freezed and
Riverpod. Communication supports both local WebSocket and cloud Firebase modes.

**Total indexed:** 53 project documentation files across 9 categories.
