# SAGE ONE — PROJECT STATE

Last updated: 2026-10-09
Current main: c57c36c60d0056099f5bdc715405c9400fa8bd45

## Identity
- Project: SAGE ONE
- Assistant identity: sage.ai
- Purpose: personal AI mentor and execution partner
- Style: direct, practical, action-oriented, no unnecessary fluff/questions.
- Rules: no lying/hiding important information; permission-based actions.

## Development workflow
- Work in large logical batches.
- GitHub main is the canonical source of truth.
- Use branches/PRs for source changes.
- Use GitHub Actions for heavy validation so the development laptop stays usable.
- Never call a feature complete until success, failure, refresh/restart behavior and regression coverage are checked where practical.

## Current verified product state
Main contains the real private-first execution core:
- Durable worker with atomic claim, ownership leases, heartbeat, retry/backoff and lease recovery.
- Mission planning with dependency-aware bounded execution.
- Real tool execution and verification.
- Research OS with search, web reading, evidence, claims, verification and persistent research records.
- Provider routing with cloud-first controls and protected local fallback.
- Durable notifications and Flutter task polling/filtering.
- Unified Chat `/command` loop with persistent session history and owner/project context.
- Completed durable tasks can index project results and consented experience memory.
- Device voice capture and TTS use the same durable command path.
- Owner Developer Mode provides non-mutating preview plus explicit approval-gated apply.
- Developer proposals are durable and owner-scoped across API restarts.
- Project detail can queue project-scoped commands.
- Sales Engine is executable end-to-end: discovery → audit → score → durable lead → intelligence → approval-gated outreach → activity history → customer conversion.
- Owner Sales UI exposes lead pipeline, lead detail, approval, customer conversion and human follow-up recording; it never sends external outreach automatically.
- Authenticated identity/profile/onboarding/memory foundations exist.
- Private mobile Memory screen supports profile-scoped read/add/delete.
- World Intelligence has status, knowledge, due items and refresh UI.
- Spark/Evolution foundations are backend-backed and exposed in Flutter.
- Apps Hub/ecosystem surfaces, file manager, AI Studio, wallet, payments, transactions, profile, settings and notifications are exposed from the private shell.
- Android APK workflow and God Mode developer website workflow both succeed from main.
- Android release workflow accepts an explicit device backend URL and uses an emulator-reachable host default.
- SAGE CI passes Python compile/lint/tests plus Flutter analyzer/tests.

## Private-first owner mode
- SAGE ONE is currently being built for one owner before public release.
- The private mobile entry path does not require Google sign-in, phone OTP or KYC.
- Developer access is local/owner controlled and production does not inherit private access by default.
- Public signup, multi-tenant ownership, production KYC/SMS and payment-provider expansion remain later scope.

## Safety / authority
- Developer Mode cannot apply source changes without explicit approval.
- God Mode does not create external authority over banks, payments, third-party accounts or destructive external systems.
- Owner economy mutations are audited.
- World Intelligence cannot self-modify production code.

## Economy / Evolution
- Spark is an internal platform credit, not cash.
- Premium work uses a canonical cost catalogue with reservation → settle/refund lifecycle and owner-scoped idempotency.
- Terminal failure/cancellation refunds exactly once; crash reconciliation exists.
- Verified mission-task results settle lifetime Evolution achievement atomically and idempotently.
- Evolution remains separate from Spark spending.

## Security
- Web Reader validates HTTP/HTTPS targets, blocks private/reserved/link-local targets, validates redirect destinations and bounds content.
- Authentication ownership checks are applied to user/profile/task/project/developer surfaces.
- Developer proposals are owner-scoped by trusted authenticated identity.
- Public worker health does not expose private worker results.

## Validation — current main
Latest main push triggered and completed successfully:
- SAGE CI — success
- SAGE ONE Android APK — success
- SAGE ONE God Mode Developer Website — success

Latest verified workflow run IDs:
- Phase 5 PR SAGE CI: 37832532613 (Python + Flutter PASS)
- Main release workflows must be rechecked after the Phase 5 merge.

## Important coordination truth
Several older feature branches and open PRs still exist. Their existence does not mean their work is absent from main. Current main must be treated as the canonical implementation; stale branches should be reconciled or closed only after their changes are compared with main.

## Real remaining blockers
1. Production SMS/OTP provider credentials and delivery.
2. Long-lived Google web token/session refresh UX.
3. Smoke-test the premium lifecycle against the user's configured local database/provider setup.
4. Broader consent-driven memory candidate review/UX.
5. Full multi-tenant isolation only if SAGE becomes a shared public service.
6. Automated visual regression for Evolution animation milestones.
7. Broader external integrations and production release hardening.
8. Manual device/reference review of the complete Flutter surface; CI cannot prove visual fidelity.
9. Physical Android smoke test against the actual configured backend.

## Continuity rule
Always inspect actual GitHub main and this file before architectural changes. Do not rely on stale branches or old chat state.

## Multi-AI development coordination
- GitHub main is the synchronization source of truth.
- `AI_COLLABORATION.md` defines claims, path locks, handoffs, reconciliation and branch/PR rules.
- Do not silently overwrite another active agent's work.
