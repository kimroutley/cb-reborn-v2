# Instructions for AI Agents

> **STOP & READ**: Before you write any code, read `docs/architecture/agent-context.md`.

This repository is a complex **Flutter Monorepo** with strict architectural constraints. Failure to follow these guidelines will break the build or introduce subtle runtime bugs.

## Core Directives

1. **Read the Context**: The definitive technical reference is [`docs/architecture/agent-context.md`](./docs/architecture/agent-context.md). It contains:
    * Correct build order for packages.
    * Testing strategies (mocking, dependency injection).
    * Known issues (linting quirks, serialization gotchas).

2. **Verify Your Work**:
    * Always run `flutter test` in the relevant package directory after changes.
    * Do not assume tests pass just because the code compiles.

3. **Respect the Build System**:
    * **Do not edit generated files** (e.g., `.g.dart`, `.freezed.dart`).
    * Run `dart run build_runner build --delete-conflicting-outputs` in the correct package order if you modify models.

4. **Update Documentation**:
    * If you change architectural patterns or fix critical bugs, update `docs/architecture/agent-context.md` to help future agents.

## Quick Links

* **[`docs/architecture/agent-context.md`](./docs/architecture/agent-context.md)**: Deep technical context & known issues.
* **[`docs/governance/authority-map.md`](./docs/governance/authority-map.md)**: Canonical documentation map.
* **[`PROJECT_DEVELOPER_HANDBOOK.md`](./PROJECT_DEVELOPER_HANDBOOK.md)**: Project vision, features, and high-level workflow.
* **[`README.md`](./README.md)**: General overview and installation.
