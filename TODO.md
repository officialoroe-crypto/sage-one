# SAGE ONE — TODO

## COMPLETE CHECKPOINTS

### CI
- [x] Fix CI `PYTHONPATH` / repository-root import problem for top-level `execution`.
- [x] Run pytest after CI fix.
- [x] Confirm compilation + tests independently.

### Durable Worker
- [x] Inspect current task model.
- [x] Add atomic claiming.
- [x] Add worker ownership.
- [x] Add lease timestamps.
- [x] Add heartbeat.
- [x] Add scheduled retry time.
- [x] Implement retry/backoff.
- [x] Implement lease-expiry recovery.
- [x] Ensure worker-owned execution context is preserved.
- [x] Add tests for competing workers.
- [x] Add tests for worker crash/lease expiry.
- [x] Add tests for retry behavior.

### Resource Protection
- [x] Add task classification: LIGHT / MEDIUM / HEAVY.
- [x] Add host CPU and memory monitoring.
- [x] Add local CPU guard with conservative thresholds.
- [x] Add graceful defer behavior when local resources are too busy.
- [x] Prevent heavy work from starting locally above the protected CPU threshold.
- [x] Add regression tests for resource protection.
- [x] Keep automatic heavy local Ollama fallback disabled.

### Background Jobs
- [x] Create durable task API.
- [x] Create background worker process/service entry point.
- [x] Persist task state through the existing durable worker lifecycle.
- [x] Allow user to query task status.
- [x] Store completed results.
- [x] Add explicit failure states to the user-facing task API.
- [x] Queue background execution without performing inference in the HTTP request.
- [x] Add Flutter task polling/detail/cancellation UX.
- [x] Route research-agent tasks through the real Research OS pipeline.
- [x] Route non-research durable goals through mission planning + tool execution + verification.
- [x] Keep mission child tasks out of the global durable worker queue.
- [x] Add durable in-app notification mechanism for completed/failed background tasks.
- [x] Add notification list/read/read-all API endpoints.
- [x] Add unread notification badge to the Flutter shell.

## SAGE EXECUTION / AGENT LAYER

### Foundation — COMPLETE
- [x] Convert high-level goals into durable missions.
- [x] Decompose missions into dependent executable tasks.
- [x] Execute tasks through the real tool registry.
- [x] Carry verified outputs forward as mission context.
- [x] Verify task completion before satisfying dependencies.
- [x] Run durable goals through the same mission execution path as synchronous execution.
- [x] Protect mission child tasks from competing global workers.

### Mission Intelligence — COMPLETE
- [x] Parallelize independent mission tasks with bounded concurrency.
- [x] Add dependency-aware execution waves.
- [x] Add mission execution progress summary from verified task state.
- [x] Persist a final mission result synthesized from verified task outputs.
- [x] Add mission cancellation/pause/resume semantics at the execution layer.
- [x] Add deterministic retry/recovery strategies per task type.
- [x] Add deterministic user-facing mission progress events.
- [x] Expose mission pause/resume/cancel controls through the HTTP/mobile API.
- [x] Persist richer execution events for long-term trace/history.

## RESEARCH OS

### Foundation — COMPLETE
- [x] Search layer.
- [x] Web Reader.
- [x] URL normalization and duplicate-source suppression.
- [x] Source metadata/content hashing.
- [x] Evidence objects with stable IDs.
- [x] Structured synthesis.
- [x] Claim/source/evidence validation.
- [x] Cross-check/verification layer.
- [x] Empty-response and zero-claim detection.
- [x] Durable worker execution for research tasks.
- [x] Start/stop the durable worker from the FastAPI application lifecycle and expose worker health.

### Next
- [x] First-class persistent research artifacts.
- [x] Persist source/evidence/claim/citation relationships.
- [x] Citation-preserving report generation.
- [x] Parallel cloud research with bounded concurrency.
- [x] Research result retrieval independent of task-row size.

## BRAIN

### Foundation — COMPLETE
- [x] Deterministic task classification/routing policy.
- [x] Groq-first cloud routing.
- [x] Cerebras secondary cloud routing.
- [x] Gemini cloud fallback through Google's OpenAI-compatible API.
- [x] Controlled Ollama local routing.
- [x] Explicit `auto`, `cloud`, and `local` routing modes.
- [x] CPU-aware local eligibility.
- [x] Provider health visibility.
- [x] Structured-output validation.
- [x] Empty-response detection.
- [x] Retry/cooldown behavior.
- [x] Avoid local heavy fallback.

### Next
- [x] Stronger quota awareness.
- [x] Provider health-aware fallback selection.
- [x] Better retry classification for transient vs permanent errors.
- [x] Durable provider telemetry.

## IDENTITY / ONBOARDING / MEMORY

### Foundation — IN PROGRESS
- [x] Add shared user profile persistence keyed by authenticated provider identity.
- [x] Store onboarding profile fields: name, phone verification state, address, age, useful basics, help intent, and selected capabilities.
- [x] Add stable multi-select onboarding capability catalog.
- [x] Add user-scoped persistent memory with explicit classifications: fact, interest, inference, skill, skill evidence, goal, preference, experience.
- [x] Support memory view/update/delete at the service layer with profile ownership checks.
- [x] Verify Google authentication tokens server-side against configured OAuth client ID.
- [x] Add phone verification challenge state machine with expiry, attempt limits, identity binding, and SMS-provider abstraction.
- [ ] Add production SMS/OTP provider.
- [x] Expose secure authenticated onboarding/profile APIs through the mounted identity router.
- [ ] Build first-run Flutter onboarding flow.
- [ ] Add user-visible memory management UI.
- [ ] Add consent-driven auto-learning pipeline on top of profile memory.

## SAGE WORLD INTELLIGENCE

### Controlled public-world learning
- [x] Add separate system-level world intelligence engine.
- [x] Grant bounded permissions for public-world reading/observation/learning.
- [x] Keep public-world knowledge separate from user personal memory.
- [x] Store source-traceable world knowledge and public-world signals.
- [x] Add bounded default topics covering current affairs, AI/technology, business, content trends, software/APIs, and education.
- [x] Add stale-knowledge detection and refresh readiness.
- [x] Add human-reviewable SAGE upgrade proposals.
- [x] Explicitly prevent self-modification through world learning.
- [x] Register world intelligence as reusable SAGE tools.
- [x] Add regression coverage for permissions, status, and upgrade proposals.
- [x] Add durable World Intelligence refresh task type and queue endpoint.
- [ ] Add durable scheduled world refresh trigger through the background automation layer.
- [ ] Add source-quality/domain policies for world refresh.
- [ ] Add world-knowledge UI and freshness indicators in Flutter.

## LATER

- [ ] Mobile-first daily interface.
- [ ] Voice commands.
- [ ] Computer control.
- [ ] File operations.
- [ ] External API integrations.
- [ ] Scheduled/background automation.
- [x] Security/permission control plane for global owner mutations; production owner identity boundary is enforced.
- [ ] Public-release preparation.


## EVOLUTION / GOD MODE TESTING
- [x] Add non-mutating Evolution simulation API using the authoritative achievement thresholds.
- [x] Animate Evolution simulation in Owner/God Mode without mutating persisted Evolution state.
- [x] Keep APPLY and RESET as explicit mutation controls.
- [ ] Add automated visual regression coverage for Evolution animation milestones.


## AUDIT — CURRENT REMAINING WORK
- [x] Audit all Python source files for syntax/lint and high-risk patterns.
- [x] Audit all Flutter/Dart source files with analyzer/tests and targeted async/resource checks.
- [x] Verify atomic verified-achievement settlement.
- [x] Restrict global permission mutation to SAGE Owner Authority.
- [x] Redact private worker results from public worker health.
- [x] Prevent accidental multi-user production deployments by requiring the configured owner identity.
- [x] Make the Android development build configurable for the Huawei P40 USB/ADB workflow.
- [x] Make the worker heartbeat regression test deterministic after a real main-branch CI failure.
- [ ] Add production SMS provider.
- [ ] Add Google-token/session refresh handling for long-lived authenticated sessions.
- [ ] Wire Spark costs into the premium-work execution settlement path.
- [ ] Add full multi-tenant data ownership if SAGE ONE is ever offered as a shared public service.
- [ ] Add automated visual regression coverage for Evolution animation milestones.
