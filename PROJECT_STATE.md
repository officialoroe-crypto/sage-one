# SAGE ONE — PROJECT STATE

Last updated: 2026-09-19

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

## Architecture implemented
- Durable task lifecycle with atomic claim, lease, heartbeat, retry/backoff and crash recovery.
- Resource-aware execution policy protecting the laptop from heavy local work.
- Provider routing with Groq, Cerebras and controlled Ollama fallback.
- Research OS with source reading, evidence, synthesis, verification and persistent research records.
- Mission planner/executor with bounded parallel execution, progress history and pause/resume/cancel controls.
- Durable task notifications and Flutter unread badge.
- Authenticated identity/profile foundation with Google ID-token verification, phone OTP state machine, user-scoped memory and onboarding APIs.
- Controlled SAGE World Intelligence for bounded public-world observation/learning and human-reviewed upgrade proposals.

## SAGE World Intelligence
World Intelligence is system-level learning about the public world, separate from personal user memory.

Loop:
WORLD → DISCOVER → COLLECT SOURCES → VERIFY/CROSS-CHECK → EXTRACT KNOWLEDGE → UPDATE WORLD KNOWLEDGE → DETECT PATTERNS/OPPORTUNITIES → HELP USERS

Boundaries:
- public sources only
- bounded topics and research calls
- source-traceable persisted knowledge/signals
- upgrade proposals require human review
- no self-modifying code
- no permission/security changes
- no financial/account/web-write authority

Default topics include current affairs, AI/technology, business, content trends, software/APIs and education.

## Mobile integration batch
Current branch: `feature/world-intelligence-v1`

Implemented in this batch:
1. Top-level `/identity/*` and `/world/*` routers are mounted into `app.main` through a cloud-side one-time integration step.
2. Flutter `SageApi` supports World Intelligence status, knowledge, due topics and bounded refresh.
3. Added `WorldIntelligenceScreen` using the approved SAGE ONE visual direction: deep black, restrained blue/cyan/purple accents, readable status, source-oriented knowledge cards and recovery/error state.
4. Added World Intelligence as a discoverable mobile navigation destination.
5. Kept the Research OS, durable tasks, mission execution, permissions and personal memory architecture intact.

## Approved visual system
- Premium futuristic but restrained.
- Deep/plain black foundation.
- No cheap neon.
- Extremely subtle typography glow.
- SAGE Core/logo is the primary visual status element.
- Recovery uses purple through light sky blue into stable state.
- Research/source provenance is visible without dashboard clutter.
- Evolution changes primarily the SAGE Core/logo treatment, voice visualizer, particles and small accents; background remains black.
- SAGE Spark is the approved name for the internal credit concept.
- Visual references are references for look/motion/hierarchy only; the written system specification remains the behavior source of truth.

## Current validation state
- Previous World Intelligence head passed SAGE CI run #160 before subsequent integration commits.
- A new CI run is required after the latest branch commits; do not claim the current branch is green until verified.

## Next major tracks
1. Verify and merge the current World Intelligence/mobile integration checkpoint after CI.
2. Build the first-run Flutter identity/onboarding flow around the existing Google + phone verification API contracts.
3. Add World Intelligence source-quality/domain policy and durable scheduled refresh through the background automation layer.
4. Add world-knowledge freshness/provenance UI and upgrade-proposal review UI.
5. Continue mobile-first SAGE UI toward the approved reference direction.
6. Add the dedicated Marketplace / Opportunities discovery area for jobs, rent, land/property and categories without cluttering the core command center.

## Continuity rule
This file is the continuity source for future SAGE ONE development sessions. Always inspect the actual GitHub repository and this state before making architectural changes.
