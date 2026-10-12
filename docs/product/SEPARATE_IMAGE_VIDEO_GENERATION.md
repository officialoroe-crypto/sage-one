# Separate Image AI and Video AI Workloads

**Status:** Future architecture requirement; audit first. Not implemented or load-tested.

## Goal
Let many SAGE ONE users request generated images and videos without making the main assistant slow or unavailable. Treat image generation and video generation as distinct workload classes.

## Shape
- **SAGE main API:** authenticate user, validate request, create job, return job ID quickly.
- **Image service/queue:** independent worker pool, concurrency limits and provider adapters.
- **Video service/queue:** independent worker pool, stricter capacity controls for long/heavy jobs.
- **Job control:** durable status, progress, cancellation, bounded retries, idempotency, failure recovery and usage accounting.
- **Media storage:** protected object/file storage for outputs and metadata; avoid large media blobs in the primary database.
- **Operations:** queue-depth/latency/error monitoring, cost and quota caps, provider health checks and an owner kill switch.

## Required behavior
1. Audit current generation endpoints, provider integrations, workers, storage and auth before adding another implementation.
2. Keep main chat, research, messages and tasks responsive while media jobs run asynchronously.
3. Return a job ID immediately; expose queued/running/succeeded/failed/cancelled status and useful errors.
4. Isolate image and video concurrency; use fair scheduling and backpressure so one workload cannot starve the others.
5. Apply authentication, per-user quotas, global caps, output access control, retention and cleanup.
6. Bound timeouts/retries, make submission idempotent, and support cancellation and recovery after restarts.
7. Use provider-hosted generation when appropriate; do not assume the user's laptop or main API server can host large models.
8. Make provider, pricing, quotas and data handling explicit. Free-first by default; no paid provider without owner approval.
9. Do not promise unlimited generation. Capacity depends on provider quotas, budgets, worker capacity and fair-use protections.
10. Test concurrent users, queue saturation, provider outage, quota exhaustion, cancellation, retry, access control and cost limits before production.

## Delivery order
- **P0 now:** repository cleanup and reference/config audit.
- **P1 next:** owner-only self-repair with diagnostics, tests, preview, approval, apply and verification.
- **After P0/P1:** inspect and implement the image/video workload architecture, reusing existing sound components.

## Acceptance
Load tests demonstrate that image/video jobs do not block main assistant requests; queue status and cancellation work; retries do not duplicate jobs; outputs are protected; usage/cost caps work; provider failures recover safely. Until tests run, this remains planned rather than complete.
