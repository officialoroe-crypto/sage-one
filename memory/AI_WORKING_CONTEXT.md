# SAGE ONE — SHARED AI WORKING CONTEXT

Last updated: 2026-10-01

## Current milestone
SAGE ONE completed the first major Agentic Action Gateway integration: Agentic Action Engine implemented and merged; Core/direct tool execution routed through the Action Engine; mission-level tool execution routed through the Action Engine. Main: `a3f82b7deb10ae8346fa422d3a8e87a46ae8b285`. PRs #87, #88, and #89 are merged.

## Core completion target
Do not declare the core complete until this lifecycle is traceable:
REQUEST → PLAN → ACTION → PERMISSION → TOOL → EXECUTE → VERIFY → EVIDENCE → RESULT → SETTLE → EVOLUTION → HISTORY

Next core pass: tighten action/task/mission correlation; authorization provenance; action verification vs real outcome verification; first-class evidence; traceable final result/history; and success/failure/restart/regression tests.

## Important architecture rules
- Tool execution must go through the controlled Action Engine; no arbitrary callable paths.
- Permission is fail-closed. Capability is not permission.
- Tool success is not automatically proof that the user's intended outcome happened.
- Evidence should be first-class.
- Runtime Permission Engine and developer AI collaboration locks are separate concerns.
- Durable Automation is distinct from the bounded local execution scheduler.
- Spark remains an internal platform credit unless a future product/legal design explicitly changes that.
- Heavy AI inference should remain cloud-first for the current development laptop.
- Voice comes after the text execution loop.
- Flutter should first expose the real SAGE interaction loop rather than many disconnected screens.
- World Intelligence must remain source-backed and must not self-modify SAGE.

## Multi-AI collaboration decision
Multiple AI accounts may work on the same repository, but they must never rely on shared chat memory. GitHub is the shared source of truth. Each AI must preflight from latest main, claim a scope, avoid overlapping locks, record branch/base SHA/objective, record changes and validation, hand off explicitly, integrate through PR + CI, and stop/reconcile when overlap is detected. Canonical protocol: `AI_COLLABORATION.md`.

## Immediate work queue
1. Continue SAGE Core integration/regression hardening.
2. Add World Intelligence source-quality/domain policy.
3. Add consent-driven memory auto-learning pipeline.
4. Complete Flutter Command Center against the real execution loop.
5. Add automated Evolution visual regression coverage.
6. Later: voice, device/computer control, public-release preparation.

## Development style
Work in large logical batches. Inspect first, implement coherent changes, validate in one consolidated pass. Keep active-work user updates concise.


## Verified current state — 2026-10-01
- Standard Tool Contract metadata is implemented and merged.
- Durable Automation Engine is implemented and merged; schedules enqueue normal durable tasks and never bypass Action Engine permissions.
- Automation trigger events are persisted.
- Outcome verification events are persisted separately from tool action identity.
- Durable execution evidence has a controlled read surface.
- Mission trace/result endpoints require SAGE Owner Authority.
- AI collaboration claims are operational through `coordination/claims.py`, with overlap/stale checks and CI validation.
- Current main SHA: `a3f82b7deb10ae8346fa422d3a8e87a46ae8b285`.
- The 13 Evolution System remains a locked product/design constraint; backend work must not silently redefine its rank names, visual identities, or progression rules.


## Verified handoff refresh — 2026-10-03
- Audited main SHA: `207b29c49e7bec4e75774ce2d74b4bd9bed9d59a`.
- Main CI and Android APK workflow passed at runs 36874551956 and 36874551903.
- Read `docs/AI_HANDOFF_2026-10-03.md` first for backend implemented/deferred inventory, Flutter screen inventory, PR conflicts, owner design constraints and exact next actions.
- Backend is substantially implemented; do not duplicate the durable worker, mission/action engine, Research OS, automation, notification, identity/profile, memory CRUD, Spark lifecycle, Evolution settlement or World Intelligence foundation. Integrate existing contracts.
- Flutter production UI remains behind the backend: the main branch has a private-first functional workspace but not all screens from the composite visual reference.
- Command Center PRs #112 and #122 overlap. #122's latest Flutter CI had one failing task-completion dialog widget test. Reconcile and fix before further work in that module.
- Continue page-by-page Flutter implementation in disjoint modules; preserve backend functionality and the standalone 13-stage Evolution lab.


## Evolution integration decision — 2026-10-03
- Owner approved combining the complete 13-stage Evolution system into the production SAGE ONE app; it is not a separate product/lab anymore.
- Integrate design specs from PR #115 and transition engine from PR #121 with the existing backend-backed Flutter Evolution screen.
- Keep Spark economic balance separate from Evolution lifetime achievement; withdrawals/spending do not reduce Evolution.
- Expose coherent Evolution identity/progress across Home, Profile, Evolution detail, rank transitions and achievements.
- Preserve SAGE blue/black identity; rank materials remain accents. Low/Mid/High affect intensity/particles, not total UI color takeover.
