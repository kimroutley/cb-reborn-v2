# Role Awards Build Instructions (Merge Companion)

> **Merged status (Feb 18, 2026):** This companion has been merged into `AWARDS_SYSTEM_PLAN.md`.
> Source of truth: `AWARDS_SYSTEM_PLAN.md` (see Sections 16–21 for merge contract, quality gates, icon policy, role completion checklist, intake template, and collaboration loop).
> Keep this file as historical reference only; add new content to `AWARDS_SYSTEM_PLAN.md`.

This file is the implementation and merge playbook for `AWARDS_SYSTEM_PLAN.md`.
Use it when combining your role-by-role award drafts into one shippable plan and then into code.

> Target merge doc: `AWARDS_SYSTEM_PLAN.md`
> Purpose: deterministic merge workflow, no lost content, no role gaps, no schema drift.

## 1) What this file controls

- How to merge alternate drafts into the plan without conflicts.
- How to collect role-specific awards from workshop sessions.
- How to enforce a minimum award ladder per role.
- How to bind each award to icon + license + attribution requirements.
- How to convert final plan content into implementation tasks.

## 2) Merge contract (non-negotiable)

When merging content into `AWARDS_SYSTEM_PLAN.md`:

1. Keep sections **1–11** intact as the canonical backbone.
2. Merge extra ideas only into **Section 9: Open merge slots** first.
3. Promote merged details into Sections 4/5/6 only after de-duplication.
4. Do not change role IDs away from `RoleIds` constants.
5. Never replace stable identifiers with display names.

If two drafts disagree, keep both variants in Slot A/B/C/D and mark one as `preferred`.

## 3) Workshop-driven role award intake process

Use this process for each role while collaborating:

1. Pick role (exact canonical `roleId`).
2. Capture at least 5 awards for that role:
   - `Rookie` (easy)
   - `Pro` (medium)
   - `Legend` (hard)
   - `Bonus 1`
   - `Bonus 2`
3. Assign gameplay trigger for each award (measurable, deterministic).
4. Assign icon candidate + source + license.
5. Assign rank difficulty score (`1-5`) and expected rarity (`common/uncommon/rare/ultra`).
6. Add to the role intake table (Section 7 in this file).

## 4) Award definition quality gate

Every award must pass all checks:

- **Role-specific:** behavior tied to the role’s mechanics.
- **Observable:** derivable from recorded game events/history.
- **Deterministic:** same history = same unlock result.
- **Non-overlapping:** does not duplicate another award’s trigger.
- **Tone-safe:** sarcastic/funny, but gameplay-focused and not personal.

Reject any award that fails one of these checks.

## 5) Icon sourcing rules (for Hall of Fame + cloud)

Preferred order:

1. MIT/Apache icon sets (Phosphor, Tabler, Heroicons, Material Symbols).
2. CC-BY sets (Game-Icons) when thematic match is much better.

Required metadata for every iconized award:

- `iconKey`
- `iconSource` (library/site)
- `iconLicense`
- `iconAuthor` (if required)
- `attributionText` (especially for CC-BY)
- `iconUrl` (source link)

Do not finalize an award without icon metadata.

## 6) Merge slots usage guide

Use these exact destinations when merging ideas from another draft:

- **Slot A (Unlock formulas):** thresholds/conditions, counters, streak logic.
- **Slot B (Copywriting packs):** title/description variants (snarky, brutal, playful).
- **Slot C (Cloud sync):** Firestore document shapes/indexes/security constraints.
- **Slot D (Seasonal resets):** season rollover, archive, carry-over policies.

After review, move accepted content from slot -> canonical section:

- Slot A -> Sections 4 and 5
- Slot B -> Section 4 (definition fields)
- Slot C -> Section 5 (persistence) + Section 10 (risk)
- Slot D -> Section 5 + Section 11 (DoD)

## 7) Role award intake template (fill during workshops)

Copy this block per role while we co-design awards:

### Role Intake: `<roleId>` / `<displayName>`

- Award 1
   Tier: `Rookie`
   Award ID: `roleid_rookie_01`
   Title:
   Unlock Trigger (Deterministic):
   Difficulty (1-5): `1`
   Rarity: `common`
   Icon Key:
   Source:
   License:
   Attribution Needed: `no`

- Award 2
   Tier: `Pro`
   Award ID: `roleid_pro_01`
   Title:
   Unlock Trigger (Deterministic):
   Difficulty (1-5): `3`
   Rarity: `uncommon`
   Icon Key:
   Source:
   License:
   Attribution Needed: `no`

- Award 3
   Tier: `Legend`
   Award ID: `roleid_legend_01`
   Title:
   Unlock Trigger (Deterministic):
   Difficulty (1-5): `5`
   Rarity: `rare`
   Icon Key:
   Source:
   License:
   Attribution Needed: `no`

- Award 4
   Tier: `Bonus`
   Award ID: `roleid_bonus_01`
   Title:
   Unlock Trigger (Deterministic):
   Difficulty (1-5): `2`
   Rarity: `uncommon`
   Icon Key:
   Source:
   License:
   Attribution Needed: `no`

- Award 5
   Tier: `Bonus`
   Award ID: `roleid_bonus_02`
   Title:
   Unlock Trigger (Deterministic):
   Difficulty (1-5): `4`
   Rarity: `ultra`
   Icon Key:
   Source:
   License:
   Attribution Needed: `no`

Notes:

- Required event fields:
- Edge cases:
- Anti-cheese constraint:

## 8) Canonical role completion checklist

Mark complete only when all 5 are true:

- [ ] 5+ awards defined for role
- [ ] all triggers deterministic and testable
- [ ] no overlap with another role’s core ladder
- [ ] icons assigned with license metadata
- [ ] attribution requirement recorded (if any)

## 9) Build execution order (after plan merge)

Follow monorepo-safe order:

1. `packages/cb_models` — add award types + catalog + icon metadata fields.
2. `packages/cb_logic` — unlock computation + persistence/query logic.
3. `apps/host` — Hall of Fame + recap award surfaces.
4. `apps/player` — personal progression/awards views.
5. Docs — update `AGENT_CONTEXT.md` with extension/maintenance guidance.

## 10) Definition of merged-ready

Your merged plan is ready to implement when:

- every canonical role has at least 5 awards (3-tier core + 2 bonus minimum),
- each award has deterministic trigger + icon metadata,
- each role entry has difficulty staging,
- Slot A/B/C/D contains no unresolved conflicts,
- implementation tasks can be derived directly without re-planning.

## 11) Quick-start collaboration protocol (for us)

When we workshop live:

1. You name a role.
2. You propose awards (or ask me to propose).
3. I normalize into deterministic unlock rules.
4. I suggest icon candidates + license-safe source.
5. We append the finalized role intake to the plan set.

Repeat until all canonical roles are complete.
