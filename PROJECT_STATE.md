# SAGE ONE — PROJECT STATE

Last updated: 2026-09-17

## 1. Project Identity

**Project:** SAGE ONE  
**Assistant identity:** sage.ai  
**Purpose:** Personal AI mentor and execution partner.

Core behavior:
- Direct
- Practical
- Brutally honest when appropriate
- Action-oriented
- No unnecessary fluff
- Avoid unnecessary questions
- Never lie or hide important information
- Never perform actions without permission

Preferred development workflow:
- Work in bulk rather than tiny edits.
- Prefer complete replacement files.
- Give exact file paths.
- Give exact commands to test.
- Minimize repetitive manual editing.
- Do not rebuild components that already work.

## 2. Hardware / Resource Constraint

Primary development laptop:
- CPU: Intel Core i5-7200U @ 2.50 GHz
- RAM: 20 GB
- OS: Windows 10 64-bit / Windows 10 Home Single Language 22H2
- GPU: Intel HD Graphics 620
- Discrete GPU: NVIDIA GeForce 9xxM series, approximately 1 GB dedicated VRAM plus shared memory

Critical architectural requirement:

> SAGE must remain usable while working. Heavy AI, research, synthesis, verification and long-running tasks should eventually run in the cloud/background rather than consuming the laptop's CPU.

Recent tests have caused approximately 100% CPU usage. This must be treated as an architectural problem, not merely a testing inconvenience.

Long-term model:
- Laptop/phone = UI, lightweight local agent, commands, local integrations.
- Cloud = heavy AI inference, research, web processing, synthesis, verification and background workers.

Local Ollama must not automatically take over heavy tasks when cloud providers fail.

## 3. Current Development Environment

Known setup:
- Flutter stable 3.47.3
- Android SDK 37.0.0
- Chrome web
- Visual Studio Build Tools 2026 18.10.0
- Flutter doctor previously confirmed green
- Python 3.14.7
- FastAPI 0.141.1
- Uvicorn 0.52.4

Backend paths used during development:
- `C:\SageOne\Backend`
- `C:\SageOne\sage_core`

Known Uvicorn command:
`C:\SageOne\Backend\venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8010`

Earlier issues with paths/imports were resolved by creating:
- `C:\SageOne\sage_core\app\main.py`
- `C:\SageOne\sage_core\app\core.py`

## 4. Research OS

Intended pipeline:

SEARCH
↓
WEB READER
↓
EXTRACTION
↓
EVIDENCE
↓
CROSS-CHECK
↓
SYNTHESIS
↓
CITATIONS
↓
REPORT

### Search

Search system is already working and should NOT be rebuilt unless inspection proves it is broken.

Known working capabilities:
- Multiple queries
- Deduplication
- Source IDs
- URLs
- Snippets
- Provenance
- Timestamps

A previous test:
- 3 queries
- 6 unique sources
- 0 errors

### Web Reader

Web Reader is under active development and should be continued from the existing implementation, not rebuilt.

Previous synthesis testing successfully searched/read 6 sources and created 6 evidence items.

## 5. Brain / AI Providers

Cloud inference is preferred.

Known provider work:
- Groq
- Gemini
- Ollama

Earlier Gemini issues:
- `models/gemini-2.5-flash` was unavailable.
- A newer model/API direction was indicated.
- Gemini later hit free-tier quota:
  `generate_content_free_tier_requests`, limit 20.

Ollama issue:
- `llama3.2:3b` returned an empty summary and 0 claims.

Architectural decision:
- Do not use local Ollama as an automatic heavy-task fallback.
- Prefer cloud provider fallback.
- If cloud providers are unavailable, queue/defer or explicitly report failure instead of making the laptop unusable.

A previous Pylance warning:
`C:\SageOne\sage_core\brain\router.py`
reported that `Stream[InteractionSSEEvent]` has no attribute `id`.

## 6. Durable Worker / Task System

This is an active infrastructure track.

Intended worker lifecycle:

TASK
↓
atomic claim
↓
worker lease
↓
heartbeat
↓
execute
├── success → completed
├── retry → delayed/backoff
└── exhausted → failed/dead
↓
lease recovery if worker crashes

Required properties:
- Atomic task claiming
- Worker ownership
- Leases
- Heartbeats
- Retry timing
- Exponential/backoff retry strategy
- Crash recovery
- Idempotent execution

Current known limitation:
- The worker previously only listed pending tasks and dispatched them.
- It did not yet properly implement atomic claiming, ownership, leases/heartbeats or persisted retry timing.
- This could allow duplicate task pickup by multiple workers.

Database task model was known to have:
- status
- retries
- max_retries

But it previously lacked sufficient:
- worker ownership
- lease state
- heartbeat
- scheduled retry fields

## 7. Current CI Issue

Most recent confirmed issue:

**CI compilation succeeds, but pytest cannot import the top-level `execution` package.**

Cause identified:
- The CI workflow is not putting the repository root on `PYTHONPATH`.

Immediate next step:
1. Fix CI import/path configuration.
2. Run pytest.
3. Only after that, continue durable worker hardening.

Do NOT simply modify tests to make CI green.

## 8. Resource Management — Planned

SAGE should eventually have a local resource manager.

Initial conceptual levels:

CPU:
- SAFE: <40%
- BUSY: 40–70%
- HEAVY: 70–85%
- CRITICAL: >85%

RAM:
- SAFE: <70%
- BUSY: 70–85%
- CRITICAL: >85%

Initial desired policy:
- Local CPU target: below approximately 50%
- Local CPU hard ceiling: approximately 70%, subject to later testing

At high CPU:
- Reduce/pause local work.
- Prefer cloud execution.
- Avoid launching local AI inference.
- Keep the computer usable.

These are design targets, not yet implemented or final.

## 9. Planned Task Classification

SAGE should classify work:

### LIGHT
- Normal conversation
- Quick calculations
- Simple planning
- Short answers

→ Fast cloud execution or lightweight local processing.

### MEDIUM
- Coding
- Analysis
- Document processing
- Moderate research

→ Stronger cloud execution.

### HEAVY
- Deep research
- Multi-source verification
- Large documents
- Long reasoning
- Multi-agent tasks

→ Background cloud worker.

## 10. Background Task Architecture

Target behavior:

USER
↓
Create task
↓
Immediately acknowledge
↓
Background worker executes
├── Search
├── Read
├── Extract
├── Evidence
├── Synthesis
└── Verify
↓
Persist result
↓
Notify/retrieve result

The user should be able to continue using the laptop while SAGE performs heavy work.

## 11. Research Efficiency Rules

Avoid unnecessarily processing huge payloads locally.

Use:
- Maximum source count
- Maximum page size
- Maximum extracted text
- Maximum evidence items
- Maximum context size
- Maximum claims
- Maximum reasoning/output length

Independent research operations should eventually run concurrently in cloud workers where safe.

Goal:
- Faster
- Cheaper
- More reliable
- Lower local CPU use

## 12. Current Priority Order

### Priority 1 — CI correctness
Fix:
`pytest cannot import top-level execution`

### Priority 2 — Worker correctness
Implement/harden:
- Atomic claim
- Lease
- Heartbeat
- Retry/backoff
- Crash recovery
- Idempotency

### Priority 3 — Performance architecture
Implement:
- Task classification
- Background jobs
- Cloud workers
- Local resource guard
- No automatic heavy Ollama fallback

### Priority 4 — Research OS expansion
Continue:
- Web Reader
- Extraction
- Evidence
- Cross-check
- Synthesis
- Citations
- Report generation

Do not rebuild working Search.

## 13. Current Known Issues

- CI pytest import problem for top-level `execution`
- Worker durability still needs hardening
- Local tests can consume excessive CPU
- Ollama fallback can be unsuitable for this laptop
- Gemini free-tier quota has been reached in previous testing
- Brain structured-output/reliability needs stronger validation/fallback handling
- Previous Pylance warning regarding `Stream[InteractionSSEEvent].id`

## 14. Development Rule

Before changing anything:

1. Inspect the current repository/files.
2. Identify what already exists.
3. Do not rebuild working components.
4. Make the smallest architecturally correct change.
5. Prefer complete replacement files.
6. Test.
7. Record the result in this document.

This file is the continuity source for future ChatGPT development sessions.
