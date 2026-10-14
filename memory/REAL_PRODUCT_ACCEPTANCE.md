# SAGE ONE — Real Product Acceptance Rules

Status: Owner-mandated, important, effective 2026-10-14.

These are durable project requirements. Do not weaken or silently reinterpret them.

## Non-negotiable rules

- No prototype features presented as real functionality.
- No fake success messages, simulated transactions, invented results, or hidden failures.
- A passing unit test, browser test, build, or CI run is evidence for that specific check only. It is not proof that the complete feature works for a real user.
- Never mark a feature complete until its real end-to-end acceptance checks have passed. Report implemented, connected, automated-tested, externally configured, and real-device-verified as separate states.
- If a provider or credential is missing, implement the real integration path and give the owner an exact, safe setup-and-test path. Until configured and verified, the action must be unavailable or clearly report not configured; it must never claim success.
- Do not deploy or publicly release SAGE ONE without the owner's explicit approval.
- Preserve existing working architecture and owner authorization; inspect before changing, use focused branches/PRs, run tests, review diffs, and keep evidence.

## Required end-to-end evidence

1. **Live Chat:** make an authenticated request to the actual deployed backend; verify the request reaches the real AI provider and returns a genuine model response (not a canned/offline fallback); verify the user and assistant messages are saved in durable storage; reopen/reload the same conversation and verify the messages remain.
2. **History and Activity Center:** verify owner-scoped APIs, real stored session/task/activity records, archive/restore/read-state persistence, and correct UI behavior after reload. No invented activity or earnings.
3. **Tasks and Memory:** verify authenticated API calls, owner isolation, durable stored state, real task lifecycle transitions, failure states, and persistence after restart/reload. Verify memory create/read/update/delete and consent/authorization boundaries.
4. **Google sign-in on Android:** test on the owner's physical Android phone with the actual app and backend configuration; verify successful identity-token validation, owner authorization, and a usable authenticated session. A web login or successful build alone does not count.
5. **Voice on Android:** test microphone permission, actual speech capture/transcription, command interpretation, consent/confirmation for consequential actions, execution, spoken response, stop/mute, and error states on the physical phone. A simulated transcript or mocked test does not count.
6. **OTP/SMS, KYC, payments, withdrawals, media generation, and every other provider-dependent action:** use real documented provider adapters and backend-only secrets; test success, rejection/failure, timeouts, retries/idempotency, authorization, and persisted records. No simulated money movement or fake verification. Without a configured provider, show unavailable/not configured and do not claim the operation succeeded.

## Verification record format

For each feature, record:
- Exact environment and app/backend commit or build tested.
- Preconditions and provider configuration status (never expose secrets).
- Reproducible test steps and request/response or logs with sensitive values redacted.
- Evidence of durable database/state before and after the action.
- Success case, failure case, authorization/owner-isolation case, retry/idempotency case where relevant.
- Automated CI results, browser QA, real deployed-backend evidence, and physical-device evidence as separate items.
- Result: PASS only for checks actually executed; FAIL for observed defects; BLOCKED when a required provider, credential, deployed environment, or device test is unavailable. Never turn BLOCKED into PASS.
- A concrete fix path and retest evidence for every failure/blocker.

## Current priority

Finish and validate PR #263; prove live authenticated Chat and persistence; validate History, Activity Center, tasks, and memory through APIs and stored data; verify Google sign-in and voice on the physical Android phone; then replace remaining prototype behavior with real provider integrations or honestly disable it until configured. Keep the product private and unreleased until owner approval.
