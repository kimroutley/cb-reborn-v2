# Club Blackout Reborn Documentation

This directory is the canonical documentation surface for engineering, operations, release history, and feature design.

## Documentation map

- `governance/authority-map.md` — where source-of-truth lives
- `architecture/` — technical architecture, role mechanics, design system
- `development/` — contributor workflows and reusable templates
- `operations/` — rolling status + QA runbooks
- `releases/` — immutable date-stamped release artifacts
- `features/` — domain-specific plans/catalogs (e.g., awards)
- `archive/` — historical snapshots retained for provenance

## Update principles

1. One canonical document per topic.
2. Use rolling files for live state (`operations/status.md`).
3. Use date folders for immutable artifacts (`releases/YYYY-MM-DD/*`).
4. Archive superseded plans; do not delete historical release evidence.
5. Keep package-level `README.md` and `CHANGELOG.md` files in their package directories.
