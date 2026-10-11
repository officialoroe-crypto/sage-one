# SAGE ONE — Documentation and Asset Cleanup Manifest

Status: Inventory in progress; one verified one-byte documentation placeholder removed on this review branch. No application assets or source files deleted/moved.
Branch: `docs/canonical-source-of-truth-20261011`
Baseline main SHA: `5524f23283f5979f06e497048ae7f6b63eabb87b`

## Active priority order
1. **P0 — Whole-repository cleanup.** Inventory files/assets/data/config/workflows/docs; trace references; reconcile contradictions; remove/archive only verified residuals; test.
2. **P1 — Self-repair system.** Audit and safely connect existing Developer Mode, proposals, CI, diagnostics, test execution and preview/apply.
3. **Deferred — currency behavior, screen-aware assistant, screen-rating system.** Keep requirements documented, but do not implement them during P0/P1.

Operational rules and all current/future tasks are centralized in [SAGE_MASTER_RULES_AND_TODO.md](SAGE_MASTER_RULES_AND_TODO.md). `TODO.md` and `DEVELOPMENT_RULES.md` are now compatibility pointers, not competing lists.

## Rules
- Canonical entry point: [docs/00_START_HERE.md](00_START_HERE.md).
- Canonical operational rules/backlog: [docs/SAGE_MASTER_RULES_AND_TODO.md](SAGE_MASTER_RULES_AND_TODO.md).
- Canonical specifications remain in subject-specific docs; consolidate conflicts, not all technical detail into one enormous file.
- Never delete before checking content, inbound references, runtime/build/test use, uniqueness, provenance and recovery path.
- Track each item as KEEP, MERGE, RENAME, ARCHIVE, DELETE-VERIFIED, or UNREVIEWED.
- Work on this branch and review a PR; do not change main or deploy as part of cleanup.
- Preserve useful history; avoid competing canonical copies.
- User data, database migrations, security/auth code, secrets/configuration and canonical assets require extra care; do not treat them as disposable clutter.

## Baseline repository inventory (main SHA above)\n\n- Recursive Git tree was not truncated: 364 total tree entries, 313 tracked files.\n- 12 image/vector files were found: 11 design/reference images and the website favicon. The 11 design images still require visual inspection and hash/dimension inventory.\n- Five zero-byte Python `__init__.py` files exist (`app`, `config`, `memory`, `permissions`, `web`). Empty package initializers can be intentional; do not remove without checking package/runtime behavior.\n- `docs/design/main design assets` was exactly one newline (1 byte). Repository code search for the path/name returned no references. It was removed on this branch only; review can restore it if a hidden/unindexed dependency is found.\n- The brand document names `SAGE_ONE_canonical_logo.png` and records a SHA-256/dimensions, but no asset with that filename appears in the tracked-file inventory. Locate the original or confirm which tracked reference is intended before replacing branding.\n- Code search for `Untitled front.jpg` returned no matches; this does not replace visual inspection or checking references in non-indexed/untracked files.\n\n## Documentation actions completed in this pass
| Path | Treatment | Notes |
|---|---|---|
| `docs/00_START_HERE.md` | KEEP / CANONICAL | Updated to show P0 cleanup → P1 self-repair → deferred features |
| `docs/SAGE_MASTER_RULES_AND_TODO.md` | KEEP / CANONICAL | Single operational rules, priority, current task and future backlog |
| `TODO.md` | KEEP / COMPATIBILITY POINTER | Checklist redirected to master; do not maintain a second TODO |
| `DEVELOPMENT_RULES.md` | KEEP / COMPATIBILITY POINTER | Rules redirected to master; preserve old links |
| `docs/SAGE_PROJECT_MEMORY.md` | KEEP / UPDATE | Removed obsolete Spark=0/old priority contradictions; points to current priority order |
| `docs/design/SAGE_ONE_CANONICAL_DESIGN_SYSTEM.md` | KEEP / CANONICAL | Visual rules |
| `docs/product/SAGE_SPARK_ECONOMY.md` | KEEP / DEFERRED SPEC | Preserve for future; no implementation in current priority |
| `docs/product/SCREEN_AWARE_ASSISTANT.md` | KEEP / DEFERRED SPEC | Preserve for future; no implementation in current priority |
| `docs/brand/SAGE_ONE_BRAND_IDENTITY.md` | KEEP / REVIEW | Canonical logo source metadata is documented; actual source asset still needs tracing |
| `docs/design/SAGE_ONE_APP_UI_REFERENCE.md` | KEEP / MERGE REVIEW | Preserve unique screen/UX requirements |
| `docs/design/evolution-system-lab/*` | KEEP / REVIEW | Preserve unique stage/transition details |
| `EVOLUTION_SYSTEM_FINAL_LOCKED.md` | KEEP / CANONICAL FOR RANKS | Canonical rank sequence |
| `PROJECT_STATE.md`, `CHANGELOG.md` | KEEP / RECONCILE | State date/SHA is stale; update only after checking current evidence |
| `docs/design/Untitled.jpg` | UNREVIEWED | Prior audit described Evolution infographic; record exact hash/dimensions and trace use |
| `docs/design/Untitled front.jpg` | UNREVIEWED | Exists; visual contents need direct inspection |
| `docs/design/img-assets/*` | UNREVIEWED | Inspect every image; hash, dimensions, duplicate and reference trace |
| `docs/design/main design assets` | DELETE-VERIFIED on branch | One-byte newline-only placeholder; code search for path/name returned no references; deletion is reviewable and not on main |
| Root docs overlapping `docs/` | MERGE / REVIEW | Keep compatibility pointers when old links are in use |
| Open PRs #221–#225, #219, #190 and #227 | REVIEW / RECONCILE | Older branches/bases may be stale; no blind merge |

## Asset inventory fields
Path; proposed descriptive path; SHA-256; dimensions/type; visual description; status (APPROVED/HISTORICAL/SUPERSEDED/UNREVIEWED); linked screen/component; source/provenance; duplicate evidence; reference-search method/result.

## Required checks before P0 exit / PR review
- Inventory all tracked files and relevant untracked/generated/runtime files where accessible.
- No broken documentation links.
- No source, workflow, tests or build configuration refer to removed paths.
- No canonical asset, unique requirement, migration, user data or security behavior is lost.
- No contradictory operational checklist remains outside the master file except documented subject-specific specs and compatibility pointers.
- Project state names the current commit accurately and distinguishes tested from unverified.
- Relevant asset-reference, link, static, unit/integration and CI checks pass or are explicitly marked blocked.
- Website preview/acceptance is separate from public deployment.
- Do not merge or deploy without explicit owner approval.

## Remaining cleanup work
1. Classify the 313 tracked files by area and role; identify residuals without treating intentional package initializers as waste.
2. Inspect/hash all design and image assets; inspect the actual bytes of `Untitled front.jpg` and all `img-assets` files.
3. Search source/docs/workflows/tests for every candidate path and for duplicate rule/task wording; use more than code search if indexing is incomplete.
4. Reconcile brand, visual system, UI reference, Evolution lab, architecture, project state, changelog and open PRs.
5. Compare existing self-repair foundations against P1 requirements without implementing future currency/screen-rating features.
6. Apply safe consolidations and verified cleanup on this branch; document every removal/move.
7. Run bounded link/asset-reference checks and relevant CI. Avoid hanging Flutter invocations on the laptop; prefer hosted CI or a bounded timeout.
8. Update the master task list and project state with evidence, then open/update the reviewable PR.
9. No merge/deployment in this cleanup pass.
