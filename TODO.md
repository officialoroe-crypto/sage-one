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

## NOW

### Background Jobs
- [ ] Create durable task API.
- [ ] Create background worker process/service entry point.
- [ ] Persist task state through the existing durable worker lifecycle.
- [ ] Allow user to query task status.
- [ ] Store completed results.
- [ ] Add explicit failure states to the user-facing task API.
- [ ] Add notification mechanism.

## RESEARCH OS

- [ ] Continue existing Web Reader.
- [ ] Extraction layer.
- [ ] Evidence objects.
- [ ] Cross-checking.
- [ ] Synthesis reliability.
- [ ] Citation preservation.
- [ ] Report generation.
- [ ] Parallel cloud research.

## BRAIN

- [ ] Strengthen provider routing.
- [ ] Cloud-provider fallback.
- [ ] Structured-output validation.
- [ ] Empty-response detection.
- [ ] Retry policy.
- [ ] Provider health tracking.
- [ ] Quota awareness.
- [ ] Avoid local heavy fallback.

## LATER

- [ ] Long-term memory architecture.
- [ ] Mobile-first daily interface.
- [ ] Desktop + mobile workflow.
- [ ] Voice commands.
- [ ] Computer control.
- [ ] File operations.
- [ ] External API integrations.
- [ ] Scheduled/background automation.
- [ ] Security/permission layer.
- [ ] Public-release preparation.
