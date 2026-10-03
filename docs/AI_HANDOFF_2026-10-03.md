# SAGE ONE — Verified Handoff Snapshot (2026-10-03)

This file is the cross-AI heads-up for the current repository state. Read it before starting work, then read `AI_COLLABORATION.md`, `PROJECT_STATE.md`, and `TODO.md`.

## Canonical repository state
- Repository: `officialoroe-crypto/sage-one`
- Main SHA audited: `207b29c49e7bec4e75774ce2d74b4bd9bed9d59a`
- Main SAGE CI: passed at run [36874551956](https://github.com/officialoroe-crypto/sage-one/actions/runs/36874551956).
- Main Android APK workflow: passed at run [36874551903](https://github.com/officialoroe-crypto/sage-one/actions/runs/36874551903).
- Main APK artifact exists and is downloadable from that workflow's Artifacts section. This is the main-branch baseline APK, not the unmerged Command Center PR build.

## Backend: verified implemented foundation
The backend is substantially ahead of the visual frontend. The following are documented as implemented in the canonical project state / TODO and must be reused, not rebuilt:
- Durable task worker: atomic claims, ownership leases, heartbeat, retries/backoff, lease recovery, lifecycle integration.
- Mission planning/execution: dependency-aware tasks, bounded parallelism, real tool registry execution, verification, mission result/history, pause/resume/cancel semantics.
- Agentic Action Engine as the controlled tool execution gateway, with standard tool contract metadata and permission checks.
- Research OS: search, Web Reader, evidence, claims, cross-check/verification, synthesis, persistent research artifacts and citation-preserving reports.
- Cloud provider routing and health/fallback controls; local heavy Ollama fallback remains guarded.
- Durable automation schedules dispatch into normal durable task queue and retain trigger/action/outcome trace.
- Durable notifications and task status/control APIs, surfaced in Flutter.
- Identity foundation: authenticated profile persistence, onboarding APIs/capability catalog, Google token verification, phone OTP state machine abstraction.
- Private-first owner/developer mode, owner authority boundaries, owner console/audit controls.
- Profile-scoped memory view/add/delete UI and APIs.
- Spark internal-credit primitives: idempotent grants/spends, atomic reservations, settlement/refund, worker crash reconciliation.
- Evolution authoritative 13-tier backend catalog, verified achievement settlement, read-only rank progress, non-mutating simulation.
- World Intelligence with bounded public-source learning, source policy/allow/block list and domain diversity; no self-modification.
- AI collaboration work claims / stale checks / path-overlap controls and CI validation.

## Backend: remaining / deferred (do not mark complete)
See canonical `TODO.md` for details. Explicit remaining items include:
- Production SMS/OTP provider credentials and delivery integration.
- Long-lived Google session/token refresh UX.
- Consent-driven memory auto-learning pipeline.
- Full multi-tenant ownership only if product becomes public multi-user.
- World Intelligence UI/freshness indicators in Flutter.
- Permissioned publishing adapters and analytics feedback loop.
- Voice commands, computer/device control, full file operations, external integrations.
- Public-release preparation.
- Evolution animation visual-regression coverage.
- Local configured database/provider-backed smoke test for premium Spark task lifecycle (CI coverage exists).

## Flutter frontend: actual current inventory on main
Existing screens:
`agent.dart`, `auth_gate.dart`, `command_center.dart`, `create.dart`, `economy.dart`, `evolution.dart`, `login.dart`, `memory.dart`, `onboarding.dart`, `owner_console.dart`, `private_owner_gate.dart`, `project_detail.dart`, `projects.dart`, `research.dart`, `tasks.dart`, `world_intelligence.dart`.
Existing tests cover agent, auth gate, command center, Evolution visual catalog, onboarding, research and tasks.
The current UI is a functional owner-first Flutter workspace, not yet a full visual implementation of the owner's composite screen reference. There are no frontend asset files in `frontend/assets/` on main at the audited SHA.

## Frontend work in progress / coordination warning
- PR #122, branch `feat/flutter-command-center-visual-v2`, is a draft. It includes a cinematic Command Center pass, task-completion artifact dialog, master reference spec, design tokens and reusable UI primitives. Latest known Flutter CI failed one widget test: the Execute button was not hit-testable in the test viewport, so the completion dialog assertion failed. Do not call PR #122 validated or merged.
- PR #112, branch `feature/flutter-command-centre-orb`, is another older draft for the same Command Center area. Its scope overlaps PR #122. The two branches must be reconciled; do not independently edit/merge both versions.
- PR #121, branch `ai/evolution-transition-engine`, is an Evolution transition animation engine. It is separate from the main Command Center work.
- PR #115, branch `design/evolution-system-lab`, is the isolated 13-stage Evolution design lab. It remains separate from production UI until owner approval.
- PR #86 is an older UI replication brief for the React/Figma prototype; Flutter remains the production frontend.

## Owner's visual and product constraints
- Flutter is the production mobile app framework.
- Implement the owner-provided composite SAGE ONE UI board screen-by-screen, in explicit first-to-last order.
- Preserve SAGE navy/black + blue/cyan identity; Evolution materials are accent layers only.
- Home orb is a clean, continuously glowing sphere: no surrounding decorative rings, orbital paths, outlines or orbiting icons.
- Apps such as Jobs, Marketplace, Learning, Community, File Manager and AI Studio belong under Apps Hub, not cluttering Home.
- Keep backend real: do not replace API/task/auth flows with mock-only implementations.
- Keep 13 Evolution system as its own design/animation lab until approved for integration.
- User wants a real Android APK installable on their phone; provide only an APK built from a clearly identified commit and configure a backend URL reachable from the phone (127.0.0.1 on phone is not the user's PC).

## Exact next actions for any AI continuing
1. Read this handoff and the collaboration protocol; check current main and active claims again.
2. Resolve the duplicate Command Center PR ownership (#112 vs #122) and repair the failing #122 widget test before claiming Command Center work.
3. Work on disjoint page modules (Splash / onboarding / login / profile) only after a new explicit coordination claim and API contract review.
4. Audit every screen against the owner reference, then implement in batches and add widget tests.
5. Build APK through `.github/workflows/sage-one-android-apk.yml` with a device-reachable `api_url`. Download the artifact and verify the APK before sharing.
6. Update this file, `PROJECT_STATE.md`, `TODO.md` and `memory/AI_WORKING_CONTEXT.md` at each meaningful handoff so another AI can continue without chat history.

## Important honesty note
The main-branch backend success claims are based on repository documentation and merged tests/CI. Items labelled remaining/deferred are not complete. The current feature PRs are not part of main until reviewed and merged.
