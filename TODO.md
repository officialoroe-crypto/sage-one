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
- [x] Controlled Ollama local routing.
- [x] Explicit `auto`, `cloud`, and `local` routing modes.
- [x] CPU-aware local eligibility.
- [x] Provider health visibility.
- [x] Structured-output validation.
- [x] Empty-response detection.
- [x] Retry/cooldown behavior.
- [x] Avoid local heavy fallback.

### Next
- [ ] Stronger quota awareness.
- [ ] Provider health-aware fallback selection.
- [ ] Better retry classification for transient vs permanent errors.
- [ ] Durable provider telemetry.

## LATER

- [ ] Long-term memory architecture.
- [ ] Mobile-first daily interface.
- [ ] Voice commands.
- [ ] Computer control.
- [ ] File operations.
- [ ] External API integrations.
- [ ] Scheduled/background automation.
- [ ] Security/permission layer.
- [ ] Public-release preparation.
