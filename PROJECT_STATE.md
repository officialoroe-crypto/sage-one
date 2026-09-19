# SAGE ONE — PROJECT STATE

Last updated: 2026-09-18

## Identity
- Project: SAGE ONE
- Assistant identity: sage.ai
- Purpose: personal AI mentor and execution partner
- Style: direct, practical, action-oriented, no unnecessary fluff/questions
- Rules: no lying/hiding important information; permission-based actions

## Development workflow
- Work in large logical batches rather than tiny edits.
- Inspect GitHub first; code directly in GitHub.
- Use GitHub branches + PRs + CI for validation.
- Keep the laptop usable; avoid unnecessary local test runs.
- Do not rebuild working components.
- Heavy AI, research, synthesis and verification belong in durable background/cloud execution where possible.

## Hardware constraint
- Intel Core i5-7200U @ 2.50 GHz
- 20 GB RAM
- Windows 10 64-bit
- Intel HD Graphics 620 + NVIDIA GeForce 9xxM series (~1 GB dedicated VRAM)
- Laptop must remain usable during SAGE operation.
- Heavy AI, research, synthesis, verification and long-running work should run cloud/background.
- Local Ollama must never automatically take over heavy work.

## Environment
- Python 3.14.7
- FastAPI 0.141.1
- Uvicorn 0.52.4
- Flutter stable 3.47.3
- Android SDK 37.0.0
- Chrome web
- Visual Studio Build Tools 2026 18.10.0
- Backend: `C:\SageOne\Backend`
- SAGE core: `C:\SageOne\sage_core`
- Backend command:
  `C:\SageOne\Backend\venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8010`

## Research OS
Target pipeline:
SEARCH → WEB READER → EXTRACTION → EVIDENCE → CROSS-CHECK → SYNTHESIS → CITATIONS → REPORT

Implemented foundation:
- Search via registered `web_search` tool.
- Web Reader via registered `web_read` tool.
- URL normalization and duplicate-source suppression.
- Source metadata and content hashing.
- Evidence objects with stable evidence IDs.
- Structured synthesis with source/evidence traceability.
- Deterministic claim validation and verification.
- Empty-evidence / empty-summary / zero-claim failure detection.
- Research agent now executes the existing synthesis + verification pipeline inside the durable background worker.

Known limitation:
- Research result persistence is currently stored as the durable task result; a dedicated research artifact/evidence store is a future step.

## AI providers
Implemented provider layer:
- Groq
- Cerebras
- Ollama
- Gemini/OpenRouter configuration remains present but OpenRouter is intentionally deferred.

Current strategy:
- Groq is the first cloud provider.
- Cerebras is the secondary cloud provider.
- Ollama is local and controlled by resource/task policy.
- Medium/heavy tasks are cloud-only in automatic routing.
- Light tasks may use Ollama only when explicitly local or when the host is below the local CPU ceiling.
- Provider cooldowns, health counters and structured-output validation exist.
- Groq uses its OpenAI-compatible chat API and GPT-OSS model configuration.
- Ollama uses its OpenAI-compatible local endpoint and `llama3.2:3b` by default.

## Resource protection
CPU policy:
- SAFE <40%
- BUSY 40–70%
- HEAVY 70–85%
- CRITICAL >=85%

Local execution policy:
- Heavy local work is blocked at 50% CPU.
- Local work is blocked at 70% CPU.
- High CPU defers background work instead of consuming more CPU.
- `psutil` is used for host resource monitoring.

## Durable task system
Current lifecycle:
TASK → atomic claim → lease → heartbeat → execute → complete/retry/fail → lease recovery

Implemented:
- durable task model
- worker ownership
- lease expiry
- heartbeat
- retry/backoff fields
- crash/lease recovery
- worker-owned completion/failure
- `POST /tasks`
- `GET /tasks`
- `GET /tasks/{task_id}`
- `POST /tasks/{task_id}/cancel`
- `python -m app.background_worker`
- local resource protection connected to worker
- background execution endpoint queues durable work instead of doing inference in the HTTP request
- research-agent tasks now use the real Research OS pipeline in the worker

## Recent merged checkpoints
- PR #12: hardened Flutter execution UX v1; merge commit `3d935ca9776c1b13253514b9e5cd2a3a2587e1bf`.
- PR #13: hardened Flutter task execution UX v2; merge commit `36d7f121931530d18088ecb891d5c80ce845a9c7`.
- CI run #85 passed before PR #13 merge.

## Current development batch
Branch: `feature/research-os-background-v1`

This batch:
1. Routes `research` durable tasks to the existing Research OS synthesis/verification engine.
2. Keeps non-research agents on the existing orchestrator path.
3. Adds regression coverage for research-vs-general worker routing.
4. Reconciles project-state documentation with the actual merged architecture.

## Next major tracks
1. Merge and verify the research background-worker batch after CI passes.
2. Persist research artifacts/evidence/citations as first-class durable records.
3. Add notification/retrieval for completed background tasks.
4. Strengthen provider quota/health-aware fallback and retry policy.
5. Strengthen memory integration.
6. Continue toward mobile-first SAGE UI.
7. Add permissions/security controls before exposing powerful computer/file operations.

## Important known issues
- Previous Gemini free-tier quota was exhausted during testing.
- Previous Ollama `llama3.2:3b` research-style test produced empty summary/0 claims; local Ollama therefore remains restricted.
- Previous Pylance warning involved `Stream[InteractionSSEEvent].id`; avoid treating static typing warnings as runtime facts without verification.

## Continuity rule
This file is the continuity source for future SAGE ONE development sessions. Always inspect the actual GitHub repository and this state before making architectural changes.
