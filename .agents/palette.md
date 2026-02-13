## 2026-02-14 - [Chat Bubble Parameter Precedence]
**Learning:** Components accepting both a complex `header` widget and simpler `title`/`avatar` props often fail to implement fallback logic, leading to silent failures where data is passed but not rendered.
**Action:** Always verify that complex widget props (like `playerHeader`) do not inadvertently hide simpler props unless intended. Implement clear fallback rendering logic.
