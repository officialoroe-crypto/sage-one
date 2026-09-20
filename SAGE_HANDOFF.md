# SAGE ONE — DEVELOPMENT HANDOFF

Last verified checkpoint: 2026-09-20 UTC
Branch basis: `main`

## Continuity
The requested `SAGE_HANDOFF.md` did not exist in the repository at the checkpoint, so this file establishes the missing continuity record. `PROJECT_STATE.md` and `TODO.md` were used as the authoritative checkpoint sources.

## Current architecture
- FastAPI SAGE ONE core with mission planning, execution, verification, trace and durable background tasks.
- Resource-aware local execution protection; heavy local Ollama fallback remains disabled.
- Groq/Cerebras cloud routing with resilience and telemetry.
- Research OS with source reading, evidence, synthesis, verification and persistent research artifacts.
- Authenticated identity foundation with Google ID-token verification, phone OTP state machine, user-scoped classified memory and onboarding profile persistence.
- SAGE World Intelligence separated from personal memory, using bounded public-source observation/learning and human-reviewed upgrade proposals.
- Flutter mobile foundation with authenticated onboarding and World Intelligence integration.
- SAGE Spark/economy package has just been initialized; no spend/credit behavior is implemented yet.

## Immediate checkpoint state
- `app.main` mounts the identity and World Intelligence routers.
- The existing router regression test was incorrectly checking that those routes were absent from the application route table. That assertion has been corrected on `feature/sage-continuation-v1`.
- A fresh CI run must validate the correction before merging.
- Do not call the checkpoint green until CI passes on the current head.

## Next development order
1. Get the router/integration checkpoint green and merge.
2. Add a durable World Intelligence refresh job type using the existing durable worker rather than running inference in the HTTP request.
3. Add persistent refresh scheduling/lease semantics so refreshes cannot duplicate across workers.
4. Add source-quality/domain policy enforcement before public-world knowledge is persisted.
5. Add World Intelligence freshness/provenance UI in Flutter.
6. Connect first-run authenticated onboarding end-to-end, including a production SMS provider abstraction/configuration without committing credentials.
7. Add user-visible memory management and consent-driven auto-learning.
8. Build the integrated MVP loop: authenticated user → profile/consent → personal workspace → research/execute → verified result → persisted history.
9. Expand SAGE Spark only after its accounting, limits, auditability and permission model are defined; it must not become a hidden authorization mechanism.

## Engineering rules
- Work in large logical batches.
- Inspect the repository before changing architecture.
- Prefer branches + PRs + CI.
- Keep the user's laptop usable; heavy AI/research/synthesis/verification belongs in cloud/background execution where possible.
- Never self-modify code, permissions, security policy, accounts or financial authority through World Intelligence.
- Keep personal memory and system-level World Intelligence strictly separate.
- Never commit API keys, OAuth secrets, SMS credentials or other secrets.
- Preserve working components; fix the smallest architectural layer that solves the problem.
