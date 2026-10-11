# SAGE ONE — Documentation and Asset Cleanup Manifest

Status: Inventory in progress; no removals made by this manifest.
Branch: docs/canonical-source-of-truth-20261011
Baseline main SHA: 5524f23283f5979f06e497048ae7f6b63eabb87b

## Rules
- Canonical entry point: docs/00_START_HERE.md.
- Canonical specifications live in docs; application source stays in source directories.
- Never delete before checking content, inbound references, unique requirements, and asset usage.
- Track each item as KEEP, MERGE, RENAME, ARCHIVE, DELETE-VERIFIED, or UNREVIEWED.
- Work on this branch and review a PR; do not change main or deploy as part of cleanup.
- Preserve useful history and avoid competing canonical copies.

## Current manifest
| Path | Treatment | Notes |
|---|---|---|
| docs/00_START_HERE.md | KEEP / CANONICAL | New entry point |
| docs/design/SAGE_ONE_CANONICAL_DESIGN_SYSTEM.md | KEEP / CANONICAL | Consolidated visual rules |
| docs/product/SAGE_SPARK_ECONOMY.md | KEEP / CANONICAL | Separates SP and SS |
| docs/product/SCREEN_AWARE_ASSISTANT.md | KEEP / CANONICAL | New requested feature |
| docs/SAGE_PROJECT_MEMORY.md | KEEP / REVIEW | Reconcile with entry point |
| docs/SAGE_VISUAL_SYSTEM.md | MERGE / REVIEW | Preserve unique details before archival |
| docs/brand/SAGE_ONE_BRAND_IDENTITY.md | MERGE / REVIEW | Preserve brand and logo source details |
| docs/design/SAGE_ONE_APP_UI_REFERENCE.md | MERGE / REVIEW | Preserve screen requirements |
| docs/design/evolution-system-lab/* | KEEP / REVIEW | Preserve unique stage/transition details |
| EVOLUTION_SYSTEM_FINAL_LOCKED.md | KEEP / CANONICAL FOR RANKS | Canonical rank sequence |
| DEVELOPMENT_RULES.md | KEEP / REVIEW | Reconcile overlapping rules |
| PROJECT_STATE.md, TODO.md, CHANGELOG.md | KEEP / UPDATE | Preserve history; update only with evidence |
| docs/design/Untitled.jpg | UNREVIEWED | Prior audit identified Evolution infographic; inspect before rename |
| docs/design/Untitled front.jpg | UNREVIEWED | Exists; visual contents not yet verified |
| docs/design/img-assets/* | UNREVIEWED | Inspect each image, hash, compare, trace references |
| docs/design/main design assets | DELETE-VERIFIED CANDIDATE | Previously inspected as one-newline placeholder; search references first |
| Root docs overlapping docs/ | MERGE / REVIEW | Keep compatibility links if needed |

## Asset inventory fields
Current path; proposed descriptive path; SHA-256; dimensions/type; visual description; status (APPROVED/HISTORICAL/SUPERSEDED/UNREVIEWED); linked screen/component; source/provenance; duplicate evidence.

## Required checks before PR review
- No broken documentation links.
- No source, workflow, or tests refer to removed paths.
- No canonical asset or unique requirement is lost.
- Project state names the current tested commit.
- Relevant asset-reference and CI checks pass.
- Production-facing redesign is previewed separately.
- Do not merge or deploy without explicit owner approval.

## Remaining work
1. Search repository-wide references to candidate files.
2. Inspect all ten currently inventoried design images and other image assets.
3. Reconcile brand, visual system, UI reference, Evolution lab, root rules, and project memory.
4. Produce evidence-based move/merge/archive/delete list.
5. Apply safe consolidation on this branch.
6. Run link, asset-reference, and relevant CI checks.
7. Open a reviewable PR.
