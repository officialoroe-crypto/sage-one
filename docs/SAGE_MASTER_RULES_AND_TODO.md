# SAGE ONE — MASTER RULES & TO-DO

Status: Canonical work-control document. Last reviewed: 2026-10-11.
Branch for current documentation/cleanup work: `docs/canonical-source-of-truth-20261011`
Baseline main SHA for this cleanup: `5524f23283f5979f06e497048ae7f6b63eabb87b`

This file is the single operational source for priority order, working rules, current tasks, and future backlog. Detailed product/design/architecture specs remain linked from [Start Here](00_START_HERE.md); they define their own subject, while this file controls what we do next.

## Owner reprioritization — 2026-10-14

The owner explicitly reprioritized the work. The active scope is now a fast, reviewable product-rebuild sequence: (1) restore the intended web workspace in a private QA artifact and make voice commands visible/safe; (2) verify Google identity and backend flows; (3) map and connect real frontend controls to backend APIs; (4) truthfully handle phone OTP/formal KYC provider readiness; (5) harden Spark ledger/economy and payment readiness; (6) refine animation and run end-to-end QA. This overrides the previous instruction to defer all product features until the cleanup/self-repair gates, for this owner-directed scope only. Preserve cleanup evidence, permission gates, testing, and rollback safeguards.

**Release freeze:** no website deployment, public app exposure, APK publication, or production publishing during this rebuild. CI and short-retention QA artifacts are allowed. Never call a feature complete based on source code or CI alone when it requires a real provider/device test.

## 1. Current priorities — do not reorder without an explicit owner decision

### P0 — Clean and stabilize the repository (NOW)
Goal: remove obsolete residuals and conflicting sources so development stops getting stuck on unclear files, duplicate rules, stale state, and broken references.

- [ ] Inventory the entire tracked repository, including source, docs, assets, workflows, generated artifacts, tests, and configuration.
- [ ] Identify duplicate/obsolete files, empty placeholders, stale drafts, conflicting instructions, unused assets, and abandoned feature paths.
- [ ] Trace inbound references and runtime/build/test use before moving or deleting anything.
- [ ] Inspect images individually; record dimensions, SHA-256, visual purpose, provenance, canonical/historical status, and references.
- [ ] Consolidate overlapping rules and task lists into this master file; leave short compatibility pointers at legacy paths where safe.
- [ ] Reconcile stale `PROJECT_STATE.md`, `TODO.md`, changelog claims, docs, open PRs, and actual main/CI evidence.
- [ ] Prefer safe moves/archives over permanent deletion when uncertainty remains. Never delete unique requirements, canonical assets, secrets evidence, migrations, or user data.
- [ ] Run documentation-link, asset-reference, dead-file, Python, Flutter, workflow, and relevant regression checks using CI or bounded commands.
- [ ] Record each candidate in `docs/CLEANUP_MANIFEST.md` as KEEP, MERGE, RENAME, ARCHIVE, DELETE-VERIFIED, or UNREVIEWED, with evidence.
- [ ] Produce a clean PR and report exact changed paths, removed items, retained items, checks and failures.
- [ ] Do not merge, deploy, or delete uncertain assets/data without the appropriate review/approval.

**P0 exit gate:** one clear source for work rules and priorities; no known stale contradictory instructions; all asset/file actions evidence-backed; no broken references; relevant checks reported honestly. This is not complete just because docs were added.

### P1 — Build the self-repairing system (NEXT, after cleanup baseline)
Goal: SAGE can diagnose issues and help the owner fix them safely while the owner tests the website.

- [ ] Audit current Owner Developer Mode, durable proposals, test runners, CI coordination, logs, health/diagnostics, preview/apply, and rollback support.
- [ ] Map existing pieces before adding new code; reuse working components.
- [ ] Build an observable repair loop: detect → gather evidence → classify → explain likely cause → propose scoped patch → run targeted tests → show diff/preview → request approval → apply only after approval → verify and record outcome.
- [ ] Keep repair operations owner-authorized, least-privilege, auditable, and isolated from production by default.
- [ ] Add bounded execution, cancellation/timeouts, resource guards, retries only when safe, and explicit failure states.
- [ ] Preserve a known-good checkpoint; never silently rewrite authorization, secrets, financial behavior, or user data.
- [ ] Require tests and owner approval before merge/deploy. Provide clear website preview and test instructions.
- [ ] Add regression tests for failed repair, rejected proposal, stale branch/base, test failure, rollback/recovery, and approval boundaries.
- [ ] Demonstrate the loop against a real non-production issue and record evidence before calling it complete.

**P1 exit gate:** an actual repair proposal can be reviewed, tested, rejected or approved; no silent production mutations; outcomes and recovery are recorded. A written design alone does not pass this gate.

## 2. Future backlog — record now, do not implement during P0/P1 unless the owner reprioritizes

### F1 — SAGE Spark currency separation (DEFERRED)
- [ ] Keep SAGE Spark Points (SP) and SAGE Spark (SS) as separate systems and ledgers.
- [ ] SP: internal-only points, non-cash/non-withdrawable; proposed 100 SP starting balance and a target around 50 SP/day from legitimate tasks, subject to anti-abuse limits.
- [ ] SS: earned balance intended for eligible payouts to eSewa/banks only after provider, compliance, eligibility, and end-to-end payout verification.
- [ ] Achievements award SP, not SS.
- [ ] Evolution progression increases with qualifying money earned; spending either currency must not reduce rank.
- [ ] No SP↔SS exchange rate is approved.
- [ ] The proposed 500 SS job/opportunity fee is unresolved: specify who pays, what it buys, refund/cancellation rules, and fraud controls before implementation.
- [ ] Define gross verified earnings versus net settled payouts, thresholds, holds, reversals, ledger migration, idempotency, and provider verification before coding.
- [ ] Preserve existing balances/data; no silent migration or cash-value promise.

### F2 — Screen-aware assistant (DEFERRED)
- [ ] Support user-invoked screenshot/share/selected-text context first.
- [ ] Make screen access opt-in, visibly active, immediately pausable, narrowly permissioned, and privacy-reviewed.
- [ ] Explain what may be processed/shared; redact sensitive fields where feasible; do not silently capture/upload.
- [ ] Suggest translations, replies, text to type/say, coding/website help, and learning assistance.
- [ ] Never send messages, submit forms, publish code, or execute external actions without explicit approval.
- [ ] Continuous overlay/accessibility behavior is a later platform-specific review, not an assumption of universal OS support.

### F3 — Screen rating system (DEFERRED)
- [ ] Capture the owner's requested screen-rating system as a future feature.
- [ ] Define what is rated, scale, criteria, storage, and how it affects prioritization only after P0/P1.
- [ ] Do not build or wire a rating mechanism during cleanup/self-repair work.



### F6 — Live Internet Intelligence, Search and Message/Task Assistance (DEFERRED until P0 cleanup and P1 self-repair gates)
- [ ] Audit current research pipeline, World Intelligence, provider routing, memory, chat command loop, durable task workers, source records and web-fetch capabilities before adding code. Search-index results alone are not sufficient; inspect actual files and call paths.
- [ ] Provide a real backend-owned web-search/fetch interface with provider adapters, timeouts, retries with limits, rate limits, caching, source URLs, publication/access timestamps where available, and graceful no-provider/no-network states.
- [ ] Search the open web and allow Google search results where a supported, permitted integration is available. Do not assume Google Custom Search JSON API is available for a new project: Google's current docs say it is closed to new customers; select a maintained provider or allowed user-opened Google Search flow after provider/cost review.
- [ ] Show citations/source links and distinguish sourced facts, inference, stale information and uncertainty. Cross-check high-impact claims; do not invent sources.
- [ ] Let SAGE use current information to answer questions, research topics, explain messages, translate, draft replies, summarize user-provided context, create/organize tasks, and propose next actions.
- [ ] Support explicit user request and opt-in task triggers; never run unbounded autonomous browsing or claim it is continuously learning when no job is running.
- [ ] Treat webpage content as untrusted input, not instructions. Protect against prompt injection, malicious links, secret exfiltration, and unsafe downloads; never let page text override system/owner rules.
- [ ] Separate transient research results from durable memory. Propose useful memory candidates with source, confidence and expiry/freshness; require the owner's consent before saving personal or durable preferences unless an existing approved memory policy explicitly permits it.
- [ ] Message assistance may draft, translate and suggest responses; do not send, post, or contact anyone without explicit per-action approval.
- [ ] Task assistance may plan and execute only within existing permission/confirmation boundaries; require approval for external, destructive, paid, publishing or sensitive actions.
- [ ] Keep secrets server-side, use least-privilege provider credentials, document quotas/pricing, prefer free-first options, and never introduce a paid dependency without explicit owner approval.
- [ ] Test unavailable provider, rate-limit/quota, malformed result, malicious page instructions, stale source, duplicate job, cancellation, timeout and network-offline cases.
- [ ] Acceptance: real end-to-end query → sourced results → answer/task proposal → user review → optional approved memory; logs show provenance and bounded usage. Mark incomplete until live integration tests prove it.


### F7 — Separate Image AI and Video AI Workloads (FUTURE ARCHITECTURE; audit first)
- [ ] Keep the SAGE ONE main assistant responsive by separating image-generation and video-generation into independent services/workers and queues, rather than running heavy generation in the main API process.
- [ ] Audit existing image/video generation endpoints, provider adapters, storage, job tables, background workers, auth, quota and billing before implementation; reuse sound existing infrastructure. Evaluate Qwen as an image-generation candidate and Wan as a video-generation candidate; verify exact model/API, license, region, quotas, pricing, privacy and commercial-use terms before choosing a provider.
- [ ] Define a common job lifecycle: submitted → queued → running → succeeded/failed/cancelled; return a job ID, progress/status, output references and actionable errors.
- [ ] Separate image and video concurrency/worker pools; video jobs must not starve chat, research, or image jobs. Apply per-user and global concurrency limits, fair scheduling, backpressure and queue-depth alerts.
- [ ] Use external/provider-hosted generation where appropriate instead of assuming the owner's laptop or primary API server can run large models. Keep provider selection configurable and free-first; disclose quotas, price and data handling before any paid provider is enabled.
- [ ] Store outputs in object/file storage with authorization, retention rules, signed/limited access URLs, cleanup and metadata; don't keep large media blobs in the primary relational database.
- [ ] Support cancellation, bounded retries, timeouts, idempotency, duplicate-job protection, failed-job recovery, usage tracking and owner-visible logs.
- [ ] Protect against abuse and cost spikes: authentication, quotas, per-user limits, moderation/safety checks appropriate to the provider, storage caps and admin kill switch.
- [ ] Scale image and video independently based on queue depth and provider capacity; no promise of unlimited or continuous generation. Capacity must follow provider quotas, budgets and fair-use policy.
- [ ] Acceptance: load tests show image/video queues do not block chat/research; verify concurrent users, provider failure, cancellation, retry, quota exhaustion, authorization, retention and cost limits before production.
- [ ] Status: architecture requirement only. Not implemented or load-tested. Keep behind P0 repository cleanup and P1 self-repair unless owner explicitly reprioritizes.


### F8 — Freebuff status (PAUSED; owner will evaluate separately)
- [x] Owner says Freebuff's one-hour-per-day free coding allowance is not enough for SAGE ONE's planned 5–12 hour work sessions.
- [ ] Do not spend current development time integrating or evaluating Freebuff. The owner has already assigned it tasks and will judge its output independently.
- [ ] Do not grant it additional SAGE ONE permissions or treat its output as merged/verified without owner review.
- [ ] Resume evaluation only if the owner explicitly asks after reviewing its results.


### F6 — Existing validation/release backlog carried forward (DEFERRED until priority gates allow)
- [ ] Production SMS/OTP provider.
- [ ] Long-lived Google web session refresh UX.
- [ ] Premium lifecycle smoke test on the configured environment.
- [ ] Full multi-tenant ownership if SAGE becomes public/shared.
- [ ] Broader third-party integrations and permissioned publishing adapters.
- [ ] Analytics → improve feedback loop.
- [ ] Automated Evolution visual regression.
- [ ] Full button-by-button interaction audit with HTTP-method/path assertions and loading/error/cancel regression coverage.
- [ ] Live backend connectivity smoke test against the configured private environment.
- [ ] Manual Android/device QA with a physical device and reachable backend.
- [ ] Resolve physical Android Google Sign-In only after checking current PR/CI, phone-reachable API URL, latest APK artifact, and fresh device logs; CI/build success alone is insufficient.
- [ ] Full visual/reference comparison.
- [ ] Verify consent-driven memory candidate review and confirmation UX on the real runtime path.
- [ ] Recheck premium reservation/settlement/refund lifecycle and Evolution settlement integration with current tests.
- [ ] Reconfirm Android release workflow API URL and ADB-reverse requirements before installing an APK.

### F4 — Live web intelligence and message assistance (OWNER-REQUESTED; AFTER P0/P1)
- [ ] Audit the existing `research/engine.py`, `research/parallel.py`, `research/synthesis.py`, `research/verification.py`, `web/reader.py`, `tools.registry`, API routes, chat execution path, persistence and deployed configuration.
- [ ] Connect existing live search/page reading to ordinary authenticated Chat when current information is needed; do not rebuild duplicate search infrastructure.
- [ ] Show result titles, domains, source links, retrieval times, evidence/uncertainty, and gracefully report timeouts/provider limits.
- [ ] Add user-submitted-message assistance: explain, translate, summarize, and draft tone-adjusted replies; no reading other apps without explicit user initiation/permission and no external send without confirmation.
- [ ] Treat web pages as untrusted data; protect against prompt injection, SSRF/redirect bypass, oversized content, malicious downloads and provider abuse.
- [ ] Keep "learning" retrieval-grounded and consent-based: no silent model retraining, no bulk scraping, and no silent durable-memory writes.
- [ ] Audit DDGS and existing providers before considering Google Search API. Any credentials, quota-dependent or paid provider needs explicit approval.
- [ ] Test the real chat/API route, citations/provenance, auth, failures, cancellation, rate limits, prompt injection, SSRF and memory-consent behavior.
- [ ] See [Live Web Intelligence & Message Assistance](product/LIVE_WEB_INTELLIGENCE_AND_MESSAGE_ASSISTANCE.md).

### F5 — Product and release work (AFTER P0/P1 and live-web work, ordered by evidence)
- [ ] Website browser acceptance and responsive/visual audit.
- [ ] Full button/link/route/API interaction audit with loading, empty, error, retry and cancel behavior.
- [ ] Physical Android device walkthrough, including Google Sign-In and phone-reachable backend configuration.
- [ ] Resolve production SMS/OTP provider and long-lived Google session refresh.
- [ ] Confirm private/public deployment boundary and web-first, mobile-second QA release gate.
- [ ] Broader third-party integrations, permissioned publishing adapters, analytics feedback loop, and automated Evolution visual regression.
- [ ] Full multi-tenant isolation only when SAGE becomes public/shared.
- [ ] Canonical logo asset recovery/verification and UI reference comparison.

## 3. Non-negotiable working rules

1. **Recover before acting.** Read this file, `docs/00_START_HERE.md`, `PROJECT_STATE.md`, the relevant detailed specification, open PRs, and current CI evidence.
2. **Audit before edits.** Search the repository, inspect current main SHA and working state, trace references and runtime paths.
3. **Preserve working code and owner decisions.** Do not restart architecture or rebuild a working component without evidence.
4. **Bulk, coherent changes.** Group related fixes into reviewable batches; do not make unrelated edits just to show activity.
5. **Single operational source.** Put priorities/rules/current and future tasks here. Legacy `TODO.md` and `DEVELOPMENT_RULES.md` should point here rather than maintain competing checklists.
6. **Detailed specs stay linked.** Design, API, architecture, security, brand and locked Evolution details remain in their subject-specific docs; this master does not replace technical detail.
7. **No destructive guessing.** Never delete/move a file until its content, inbound references, build/test/runtime use, uniqueness and recovery path are checked.
8. **Security first.** No hardcoded credentials, secrets in docs/logs, self-granted owner access, or weakened auth to make tests pass.
9. **Explicit permission.** No external message, publish, payment, destructive data change, merge, or production deployment without the required user approval.
10. **Resource safety.** Keep the development laptop usable. Heavy AI/research should be bounded and cloud/background-first; no uncontrolled heavy local-model fallback.
11. **Real failure states.** Tasks need observable pending/running/retrying/completed/failed/dead states; failures must not be hidden. Use idempotency for retries.
12. **Test the real path.** Trace request → auth/permission → execution → persistence → result. Test failure, retry, refresh/restart and regression where practical.
13. **Preview → approve → apply.** Developer changes are inspected, scoped, tested and previewed before approval; no silent self-modification in production.
14. **Evidence-only status.** Code existence, a PR, an APK build, or old green CI does not prove live functionality. Record exact commit, checks, device/runtime evidence, and remaining blockers.
15. **Keep durable records.** Update project state, this backlog, cleanup manifest, and changelog when supported by actual changes/evidence.
16. **Free-first.** Do not add paid services, subscriptions, or credit-dependent dependencies without explicit approval.
17. **Simple owner handoff.** Report what changed, where it lives, what was tested, what failed, and the exact next action.

## 4. Work protocol

Recover → Audit → Document → Plan → Implement → Test → Preview → Owner approval → Apply/merge/deploy.

## 5. Linked canonical references

- [Start Here](00_START_HERE.md)
- [Cleanup Manifest](CLEANUP_MANIFEST.md)
- [Canonical Design System](design/SAGE_ONE_CANONICAL_DESIGN_SYSTEM.md)
- [Brand Identity](brand/SAGE_ONE_BRAND_IDENTITY.md)
- [App UI Reference](design/SAGE_ONE_APP_UI_REFERENCE.md)
- [Locked Evolution System](../EVOLUTION_SYSTEM_FINAL_LOCKED.md)
- [Architecture](../ARCHITECTURE.md)
- [Project State / incident handoff](../PROJECT_STATE.md)
- [Changelog](../CHANGELOG.md)


## 7. Historical completion claims carried forward (not re-certified by this cleanup)

The previous `TODO.md` marked the following foundations complete. These are preserved as historical project records, **not a claim that every runtime path is currently verified**. Re-audit during P1 and product QA where relevant.

- Durable workers, leases, heartbeat, retries/backoff, recovery, task polling/cancellation/notifications.
- Mission planning, dependency-aware execution, verification, Research OS records/evidence, provider routing and resource protection.
- Unified Chat command loop, project-scoped commands/results, consent-gated task-experience memory, voice STT/TTS through durable commands.
- Owner Developer Mode preview/apply gate and durable owner-scoped proposals.
- Authenticated profile persistence, Google token validation foundation, OTP state machine/provider abstraction, onboarding, user-visible memory controls.
- World Intelligence backend and Flutter status/knowledge/refresh UI.
- Spark reservation/settlement/refund primitives, premium execution lifecycle, Evolution achievement settlement and tier API.
- Apps Hub, File Manager, AI Studio, Wallet/Payments/Transactions, Profile/Settings/Notifications shell surfaces.
- Sales discovery/audit/scoring, durable leads, intelligence, approval-gated outreach preparation, activity/history and owner sales UI.
- Machine-readable work claims, claim/release and stale-claim detection, handoff records, overlap checks, CI coordination and current-main pre-PR consistency check.
- CI previously reported Python compile/lint/tests, Flutter analyzer/tests, Android APK workflow and developer website workflow as passing on then-current main. Those old results do not certify the current branch or current runtime.

## 6. Definition of done

A task is complete only when its acceptance criteria are met, relevant checks have current evidence, remaining risks are written down, and the resulting state is recorded. If a required check cannot run, label it BLOCKED/UNVERIFIED, never PASS.
