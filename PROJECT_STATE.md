# SAGE ONE — PROJECT STATE

Last updated: 2026-09-22
Current main: 1e1ad8a218e1fc2444d8cf0a26c2af65a526dcbd

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
- User profile/onboarding/memory foundation.
- Local phone-free Developer Mode and SAGE Owner Authority/God Mode.
- Owner Spark/Evolution controls and audit log.
- Non-mutating Evolution simulation with authoritative thresholds and Flutter animation.
- Verified mission-task results settle into Evolution atomically and idempotently.
- Web Reader redirect validation prevents automatic redirect-based private-network SSRF.
- Web Reader extraction dependency is declared explicitly.
- Flutter onboarding capability IDs match the backend stable capability contract.
- Command Center routing display consumes the backend routing shape.
- World Intelligence status UI correctly represents self-modification as blocked.
- Spark grants and spends now use idempotent references and atomic SQL balance mutations.
- Android APK workflow accepts a device-reachable backend URL through workflow dispatch or the repository variable.

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
- Premium execution charging/refund orchestration is still separate work and is not falsely marked complete.

## Web Reader security
- Only HTTP/HTTPS URLs are accepted.
- Local/private/link-local/multicast/reserved/unspecified targets are blocked.
- Redirects are not followed automatically.
- Every redirect destination is validated again.
- Redirect chains are bounded.
- Content size and supported content types are bounded.
- Current dependency: trafilatura 2.2.0.

## Validation status
- SAGE CI passed on the final audit-hardening PR after the Android workflow and Spark changes.
- Python job passed.
- Flutter analyzer/tests passed.
- The hardening PR was merged to main as 1e1ad8a218e1fc2444d8cf0a26c2af65a526dcbd.
- Fresh main-branch Android APK / Pages workflow results should be checked after release-affecting pushes.

## Remaining real-world blockers
These require external configuration or are deliberate future scope:
1. Production SMS/OTP provider credentials and delivery service.
2. Long-lived Google web token/session refresh UX.
3. Premium execution Spark charge/refund orchestration.
4. Scheduled World Intelligence refresh trigger and source-quality policy.
5. User-visible memory management and consent-driven auto-learning UX.
6. Full multi-tenant ownership only if SAGE ONE becomes a shared public service.
7. Automated visual regression tests for Evolution animation milestones.
8. Production release hardening and external API integrations.

## Continuity rule
Always inspect the actual GitHub main branch and this file before architectural changes. Do not rely on an old branch or stale local copy.