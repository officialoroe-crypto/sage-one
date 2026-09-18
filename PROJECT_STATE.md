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
- User confirms merges; do not merge without explicit confirmation.
- Avoid unnecessary local testing because the development laptop can hit ~100% CPU.
- Do not rebuild working components.

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
SEARCH → WEB READER → EXTRACTION → EVIDENCE → CROSS-CHECK → SYNTHESIS → CITATIONS → REPORT
- Search is working and must not be rebuilt unless broken.
- Previous test: 3 queries → 6 unique sources → 0 errors.
- Web Reader/research synthesis has already produced evidence items from multiple sources.

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

## Recent merged checkpoints
- PR #3: fixed worker/orchestrator ownership context and added CI.
- PR #5: added durable background task API and resource-protected background worker.
- Current `main` checkpoint: commit `edd1acfb5b5bbebe5dbfe0a78c75c2bb62d101d6`.

## Current development batch
Branch: `feature/provider-routing-v2`

This batch combines multiple stages:
1. Deterministic task classification/routing policy.
2. Groq-first cloud routing.
3. Controlled Ollama local routing.
4. Explicit `auto`, `cloud`, and `local` routing modes.
5. CPU-aware local eligibility.
6. Provider routing health visibility.
7. Regression tests for light/medium/heavy routing and CPU protection.

Configuration:
- `SAGE_ROUTING_MODE=auto` by default.
- `SAGE_PREFER_LOCAL=false` by default.

## Next major tracks
1. Finish and merge provider routing batch after CI passes and user confirmation.
2. Connect heavy AI execution to durable background tasks.
3. Improve research pipeline orchestration and evidence/citation persistence.
4. Add notification/retrieval for completed background tasks.
5. Strengthen memory integration.
6. Continue toward mobile-first SAGE UI.

## Important known issues
- Previous Gemini free-tier quota was exhausted during testing.
- Previous Ollama `llama3.2:3b` research-style test produced empty summary/0 claims; local Ollama therefore remains restricted.
- Previous Pylance warning involved `Stream[InteractionSSEEvent].id`; avoid treating static typing warnings as runtime facts without verification.

## Continuity rule
This file is the continuity source for future SAGE ONE development sessions. Always inspect the actual GitHub repository and this state before making architectural changes.
