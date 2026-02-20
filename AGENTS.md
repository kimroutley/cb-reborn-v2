# Instructions for AI Agents

> **STOP & READ**: Before you write any code, read the core documentation below.

This repository is a complex **Flutter Monorepo** with strict architectural and visual constraints. Failure to follow these guidelines will break the build, introduce subtle bugs, or violate the design system.

## Core Directives

1.  **Visuals First**:
    *   **MANDATORY**: Read **[`STYLE_GUIDE.md`](./STYLE_GUIDE.md)** before touching any UI code.
    *   Do not hardcode colors. Use `Theme.of(context).colorScheme` or `CBColors` from `cb_theme`.
    *   Use shared widgets (`CBGlassTile`, `CBPanel`, `CBPrimaryButton`) instead of raw Flutter widgets.

2.  **Architecture & Context**:
    *   The definitive technical reference is **[`AGENT_CONTEXT.md`](./AGENT_CONTEXT.md)**.
    *   It contains build order, testing strategies, and known "gotchas".

3.  **Verify Your Work**:
    *   Always run `flutter test` in the relevant package directory after changes.
    *   Do not assume tests pass just because the code compiles.

4.  **Respect the Build System**:
    *   **Do not edit generated files** (e.g., `.g.dart`, `.freezed.dart`).
    *   Run `dart run build_runner build --delete-conflicting-outputs` in the correct package order if you modify models.

5.  **Update Documentation**:
    *   If you change architectural patterns, fix critical bugs, or add new UI paradigms, update the relevant documentation.

## Quick Links

*   **[`STYLE_GUIDE.md`](./STYLE_GUIDE.md)**: **MUST READ**. The "Design Bible" for the Radiant Neon aesthetic.
*   **[`AGENT_CONTEXT.md`](./AGENT_CONTEXT.md)**: Deep technical context & known issues.
*   **[`PROJECT_DEVELOPER_HANDBOOK.md`](./PROJECT_DEVELOPER_HANDBOOK.md)**: Project vision, features, and high-level workflow.
*   **[`README.md`](./README.md)**: General overview and installation.
