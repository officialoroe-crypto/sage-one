# SAGE ONE — PROJECT STATE

Last updated: 2026-09-22
Current main: 3894c5418ac333dd32b78b0ecba17277478e263e

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
- Verified mission-task results now settle into Evolution atomically and idempotently.
- Web Reader redirect validation prevents automatic redirect-based private-network SSRF.
- Web Reader extraction dependency is declared explicitly.
- Flutter onboarding capability IDs now match the backend's stable capability contract.
- Command Center routing display now consumes the backend routing shape.
- World Intelligence status UI correctly represents self-modification as blocked.

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

## Web Reader security
- Only HTTP/HTTPS URLs are accepted.
- Local/private/link-local/multicast/reserved/unspecified targets are blocked.
- Redirects are not followed automatically.
- Every redirect destination is validated again.
- Redirect chains are bounded.
- Content size and supported content types are bounded.
- Current dependency: trafilatura 2.2.0.

## Validation status
Recent logical batches were validated through GitHub Actions:
- Evolution settlement: SAGE CI green.
- Flutter routing/status fixes: SAGE CI green.
- Web Reader security/dependency batch: SAGE CI green after regression correction.
- Mission task start atomicity: SAGE CI green.
- Flutter analyzer/tests passed on the recent batches.

Android APK and GitHub Pages workflows were previously green on main and remain covered by the Flutter source validation. A fresh Pages/APK workflow run should still be checked after the next release-affecting main push.

## Remaining real-world blockers
These require external configuration or are deliberate future scope:
1. Production SMS/OTP provider credentials and delivery service.
2. Long-lived Google web token/session refresh UX.
3. Spark cost charging/refund settlement for premium execution.
4. Scheduled World Intelligence refresh trigger and source-quality policy.
5. User-visible memory management and consent-driven auto-learning UX.
6. Full multi-tenant ownership only if SAGE ONE becomes a shared public service.
7. Automated visual regression tests for Evolution animation milestones.
8. Production release hardening and external API integrations.

## Continuity rule
Always inspect the actual GitHub main branch and this file before architectural changes. Do not rely on an old branch or stale local copy.
