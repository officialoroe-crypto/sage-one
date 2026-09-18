# SAGE ONE — TODO

## NOW

### CI
- [ ] Fix CI `PYTHONPATH` / repository-root import problem for top-level `execution`.
- [ ] Run pytest after CI fix.
- [ ] Confirm compilation + tests independently.

### Durable Worker
- [ ] Inspect current task model.
- [ ] Add atomic claiming if missing.
- [ ] Add worker ownership.
- [ ] Add lease timestamps.
- [ ] Add heartbeat.
- [ ] Add scheduled retry time.
- [ ] Implement retry/backoff.
- [ ] Implement lease-expiry recovery.
- [ ] Ensure idempotent execution.
- [ ] Add tests for competing workers.
- [ ] Add tests for worker crash/lease expiry.
- [ ] Add tests for retry behavior.

## NEXT

### Resource Protection
- [ ] Identify every local CPU-heavy path.
- [ ] Prevent automatic Ollama fallback for heavy tasks.
- [ ] Add task classification: LIGHT / MEDIUM / HEAVY.
- [ ] Add local resource monitoring.
- [ ] Add local CPU guard.
- [ ] Add graceful defer/pause behavior.

### Background Jobs
- [ ] Create durable task API.
- [ ] Create background worker process/service.
- [ ] Persist task state.
- [ ] Allow user to query task status.
- [ ] Store completed results.
- [ ] Add failure states.
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
