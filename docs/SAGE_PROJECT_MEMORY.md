# SAGE ONE — Project Memory / Canonical Source of Truth

GitHub is the durable shared project memory. Chat history is supplementary. Read [Start Here](00_START_HERE.md) and [Master Rules & To-Do](SAGE_MASTER_RULES_AND_TODO.md) before major work.

## Current engineering priorities — LOCKED ORDER
1. **P0: clean the whole repository** — audit tracked files, source, assets, data/config, workflows and docs; identify stale/duplicate/conflicting residuals; trace references; consolidate operational rules and TODO; archive/delete only with evidence; run checks.
2. **P1: build the self-repair system** — audit existing Developer Mode and CI first, then create a safe detect → diagnose → propose → test → preview → owner approve → apply → verify loop.
3. Only after P0/P1 gates: resume broader end-to-end UI/backend QA, device/release hardening and deferred product features based on evidence.

Do not reorder priorities to implement attractive new features while cleanup or self-repair remains the active blocker.

## Product vision
SAGE ONE is the owner's personal AI mentor and execution platform, not a chatbot demo. It should eventually support research, content creation, video workflows, marketing, business discovery, portfolio generation, and permissioned creator/business tasks.

## Role boundary
- Backend engineering builds APIs, data models, authentication, permissions, ledgers, orchestration, workers, integrations, CI and security.
- Frontend engineering builds screens, navigation, UX, visual design, animations, responsive behavior and frontend QA.
- Integration work verifies real end-to-end behavior.
- When a feature is requested, determine whether it is SAGE runtime behavior, backend infrastructure, frontend behavior, or an owner action. Do not confuse future SAGE capability with a request for the engineering assistant to manually perform that capability.

## Owner Developer Mode / self-repair
- Owner-only; credentials and secrets belong in secure configuration, never hardcoded in source.
- Inspect and explain before changing code; use scoped branches/proposals and tests.
- Default path: diagnose → branch → propose patch → test → preview → owner approval → apply/merge → deploy only with explicit approval.
- SAGE may not grant itself owner privileges or silently weaken authentication/authorization.
- Preserve a known-good checkpoint and record evidence, failure states and recovery.

## Canonical design / product decisions
- Premium, calm, futuristic and cinematic; deep black/blue foundation, restrained electric blue/cyan/white and violet, gold for achievements/earnings. Read [canonical design system](design/SAGE_ONE_CANONICAL_DESIGN_SYSTEM.md) and [brand identity](brand/SAGE_ONE_BRAND_IDENTITY.md).
- Use the canonical orbital S identity; don't replace it without owner approval. Trace and verify the actual source asset before renaming/deleting.
- Evolution: 13 canonical ranks × Low/Mid/High = 39 states. See [locked Evolution spec](../EVOLUTION_SYSTEM_FINAL_LOCKED.md).
- Mobile-first, accessible and responsive; meaningful loading/error/retry/cancel/success states; keep the laptop responsive with bounded cloud/background-first heavy work.

## Deferred features — preserve, do not implement during P0/P1
- SAGE Spark Points (SP) and SAGE Spark (SS) separation and future ledger/payout behavior.
- Screen-aware assistant with opt-in screen context and strict privacy/approval boundaries.
- Screen-rating system.
- Further marketplace, third-party integrations, analytics, visual regression and release expansion as scheduled in the master backlog.

## Shared project record
- [Master Rules & To-Do](SAGE_MASTER_RULES_AND_TODO.md) is the only operational priority/checklist source.
- [Cleanup Manifest](CLEANUP_MANIFEST.md) records file/asset audit evidence and proposed KEEP/MERGE/RENAME/ARCHIVE/DELETE-VERIFIED actions.
- [Project State](../PROJECT_STATE.md) retains incident-level and verified runtime handoff details.
- [Changelog](../CHANGELOG.md) records completed work only, with evidence.
