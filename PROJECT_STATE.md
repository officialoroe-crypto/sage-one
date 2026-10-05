# SAGE ONE — PROJECT STATE

Last updated: 2026-10-05
Current main: 90dab1ddddb710b384b3a77b4f2ae9132c8ad9dd

## Identity
- Project: SAGE ONE
- Assistant identity: sage.ai
- Purpose: personal AI mentor and execution partner
- Style: direct, practical, action-oriented, no unnecessary fluff/questions.
- Rules: no lying/hiding important information; permission-based actions.

## Development workflow
- Work in large logical batches.
- Inspect GitHub first; make source changes through branches/PRs.
- Use GitHub Actions for heavy validation so the development laptop stays usable.
- Never call a feature complete until its success path, failure path, restart/refresh behavior and regression coverage are checked.

## Environment
- Python local target: 3.14.7
- CI Python: 3.13
- FastAPI: 0.141.1
- Flutter: 3.47.3
- Android SDK: 37
- Canonical source: C:\SageOne\sage_core
- Legacy backend: C:\SageOne\Backend
- Local backend port: 8010

## Core architecture
REQUEST → PLAN → EXECUTE → RESULT → VERIFY → EVIDENCE → SETTLE → ACHIEVEMENT → EVOLUTION → HISTORY

Implemented:
- Durable worker with atomic claim, ownership leases, heartbeat, retry/backoff and lease recovery.
- FastAPI lifecycle starts/stops the worker.
- Mission planning with dependency-aware and bounded parallel execution.
- Real tool execution and verification.
- Research OS with search, web reading, evidence, claims, verification and persistent research records.
- Provider routing: Groq, Cerebras, Gemini through Google's OpenAI-compatible API, controlled Ollama fallback.
- CPU/resource protection that avoids automatic heavy local Ollama takeover.
- Durable notifications and Flutter task polling.
- Authenticated Google identity foundation.
- Phone OTP state machine + provider abstraction.
- User profile/onboarding/memory foundation, plus private mobile memory review/add/delete UI.
- Local phone-free Developer Mode and SAGE Owner Authority/God Mode.
- Private-first owner mode: development defaults to a localhost-only owner session; Google/phone/KYC onboarding remains isolated for future multi-user mode.
- Production environments do not inherit private/developer access by default.
- Owner Spark/Evolution controls and audit log.
- Non-mutating Evolution simulation with authoritative thresholds and Flutter animation.
- Flutter Evolution rank screen reads the canonical 13-rank names/thresholds from the authenticated `/economy/evolution/tiers` API; rank progress remains read-only and sourced from the economy snapshot.
- Verified mission-task results settle into Evolution atomically and idempotently.
- Web Reader redirect validation prevents automatic redirect-based private-network SSRF.
- Web Reader extraction dependency is declared explicitly.
- Flutter onboarding capability IDs match the backend stable capability contract.
- Command Center routing display consumes the backend routing shape.
- World Intelligence status UI correctly represents self-modification as blocked.
- Spark grants and spends now use idempotent references and atomic SQL balance mutations.
- Android APK workflow accepts a device-reachable backend URL through workflow dispatch or the repository variable.

## Private-first owner mode
- SAGE ONE is currently being built for one owner before any public release work.
- The mobile entry path skips Google sign-in, phone OTP, and onboarding; those identity capabilities remain in the codebase but are not on the private entry path.
- Private/developer sessions remain localhost-only and still use a short-lived in-memory backend session token so normal authenticated APIs keep their ownership boundary.
- Production does not default to private/developer access.

## Owner / God Mode
- Local Developer Mode is localhost-only and requires no phone/SMS/OTP.
- Owner controls are internal SAGE development/testing controls.
- Production owner identity is explicitly bound with SAGE_OWNER_AUTH_SUBJECT.
- God Mode does not create external authority over banks, payments, third-party accounts, or destructive external systems.
- Owner economy mutations are audited.

## Evolution settlement
A successfully verified mission task awards a deployment-owner-scoped verified achievement event.
- Reward: 100 Evolution achievement per newly verified mission task.
- Source identity: mission_task + task ID.
- Duplicate verification does not award twice.
- Task verification and Evolution settlement are committed in one database transaction.
- Failed settlement rolls the verification transaction back.

## Spark economy
- Spark is an internal platform credit, not cash.
- Premium work has a stable cost catalogue.
- Grant/spend operations reject non-positive amounts.
- Repeated operations with the same owner-scoped reference are idempotent.
- Reusing a reference with a different amount is rejected.
- Spending uses an atomic SQL balance >= amount update, preventing read/check/write overdraw races.
- Premium execution now has an atomic reservation → settle/refund lifecycle with owner-scoped idempotency keys. Reservations use the canonical Spark cost catalogue; refunds reverse the balance exactly once and do not inflate lifetime-earned Spark.
- Premium transaction controls are owner-only development endpoints. Durable premium task creation is owner-authenticated and derives the owner key from trusted claims; the worker reserves catalog-priced Spark before execution, settles on completion, and refunds terminal failure/cancellation. A worker reconciliation pass repairs reserved transactions for terminal tasks after a crash. Retry attempts reuse the same task-scoped idempotency key.

## Web Reader security
- Only HTTP/HTTPS URLs are accepted.
- Local/private/link-local/multicast/reserved/unspecified targets are blocked.
- Redirects are not followed automatically.
- Every redirect destination is validated again.
- Redirect chains are bounded.
- Content size and supported content types are bounded.
- Current dependency: trafilatura 2.2.0.

## Frontend status — 2026-10-05

Canonical main currently contains the functional private-owner Flutter shell with Command Center, Research, Tasks, Create, Projects, Agent, World Intelligence, Owner Console, Memory, and Evolution destinations.

Active frontend work discovered in the shared repository:
- Phase 01 Splash: PR #125, exact head CI green.
- Phase 02 Onboarding: PR #128, exact head CI green.
- Phase 03 Language Selection: PR #129, branch head `6f6dbdf2505ee4399b2339d866c3b4bdaf5d8444`; previous CI failed only on an undefined `SageTheme.textMuted` reference, now corrected and awaiting fresh CI.
- Command Center visual v2: PR #122, latest head `e6edfc0aa6343fbedeea6782acba0756ac65a23d`; analyzer passes but the completion-dialog widget test failed in CI #1101, now corrected and awaiting fresh CI.
- `feat/flutter-phase-04-auth` exists but is identical to the Phase 03 branch; it is not a separate Phase 04 implementation yet.

Important: Phase 02 has two open PRs (#127 and #128); #128 is the newer implementation and should be the canonical Phase 02 review path. Command Center #112 is superseded by #122 and should not be merged.

## Validation status
- SAGE CI passed on the final audit-hardening PR after the Android workflow and Spark changes.
- Python job passed.
- Flutter analyzer/tests passed.
- The audited hardening work is merged to main. Current canonical main for the frontend audit is `90dab1ddddb710b384b3a77b4f2ae9132c8ad9dd`.
- Premium durable task integration was merged in PR #79. Worker recovery/migration tests passed CI and were merged in PR #80; owner/catalog boundary tests passed CI and were merged in PR #81; the isolated API-to-worker end-to-end test and internal-only owner-key handoff fix passed CI and were merged in PR #82. Project-state validation updates were merged in PR #83.
- Fresh main-branch Android APK / Pages workflow results should be checked after release-affecting pushes.

## Shared owner memory system
- Added `memory/CHATGPT_OS.md` as the owner-facing AI working contract.
- Added `memory/OWNER_MEMORY_MODEL.md` defining owner-scoped memory and future per-user isolation.
- Added durable rule, preference, decision, mistake, current-context, and SAGE ONE integration documents under `memory/`.
- Public GitHub contains the memory contract only; private conversations belong in the runtime memory store.

## Current private-first phase
The immediate product target is a fast personal workspace for the owner: Command Center, Research, Tasks, Create, Projects/Workflow, memory, and execution. The private Flutter shell now exposes Memory from the More menu; its screen reads, adds, and deletes profile-scoped memories through the existing authenticated identity API. Public signup, KYC, Google/phone verification UX, multi-tenant ownership, and payment-provider integration are deferred until after real personal use.

## Remaining real-world blockers
These require external configuration or are deliberate future scope:
1. Production SMS/OTP provider credentials and delivery service.
2. Long-lived Google web token/session refresh UX.
3. Run the additive task migration and smoke-test the premium lifecycle against the user's configured local database. CI covers worker success, retry idempotency, terminal refunds, reconciliation, migration repeatability, endpoint owner/catalog boundaries, and isolated SQLite API-to-worker settlement; local database/provider-backed runtime validation remains outstanding. See `docs/runbooks/PREMIUM_SPARK_TASKS.md`.
4. World Intelligence Flutter freshness UI and source/freshness presentation polish.
5. Permissioned publishing adapters and analytics → improve feedback loop.
6. Voice commands, computer control, file operations, and external API integrations.
7. Automated Evolution animation visual-regression coverage.
8. Multi-tenant ownership only if SAGE ONE becomes a shared public service.
9. Production release hardening and real-device/manual QA, including the Huawei P40 workflow.

## Continuity rule
Always inspect the actual GitHub main branch and this file before architectural changes. Do not rely on an old branch or stale local copy.

## Multi-AI development coordination
- SAGE ONE is intended to be safely maintainable from multiple independent AI sessions/accounts.
- GitHub main is the canonical source of truth; chat history is not synchronization state.
- `AI_COLLABORATION.md` defines preflight, work claims, path locks, handoffs, reconciliation, branch/PR rules, and planned automation.
- `memory/AI_WORKING_CONTEXT.md` records the current Agentic Gateway milestone, core-completion target, immediate work queue, and multi-AI rules.
- GitHub Issue #90 tracks implementation of the developer collaboration/work-lock control plane.


## Backend completion update — 2026-10-01
- Agentic Action Engine remains the controlled tool execution gateway.
- Standard Tool Contract metadata is now part of the registry and action-plan flow.
- Durable Automation persists one-time/interval schedules and dispatches them into the normal durable task queue.
- Automation trigger, action, execution verification, and outcome verification events are traceable.
- Durable ActionEvidence has a controlled retrieval surface.
- Mission trace/result endpoints require SAGE Owner Authority.
- AI work coordination is operational with machine-readable claims, conservative path-overlap checks, stale-claim detection, explicit takeover, and CI validation.
- Spark premium reservation/settlement/refund is already wired into the durable worker lifecycle and crash reconciliation.


## Latest verified backend update — 2026-10-01
- World Intelligence now has a transparent configurable source-selection policy: HTTP/HTTPS validation, optional allowlist, explicit blocklist, and per-domain diversity limits.
- Policy rejections are surfaced rather than hidden.
- Current main: `6c454a63af377694e7e598cb67edc4d71656342a`.
