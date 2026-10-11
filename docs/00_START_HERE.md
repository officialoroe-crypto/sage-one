# SAGE ONE — Start Here

Status: Canonical documentation entry point. Last reviewed: 2026-10-11.

## Read first
1. [Master Rules & To-Do — single operational priority/backlog source](SAGE_MASTER_RULES_AND_TODO.md)
2. [Cleanup Manifest](CLEANUP_MANIFEST.md)
3. [Canonical design system](design/SAGE_ONE_CANONICAL_DESIGN_SYSTEM.md)
4. [Project memory](SAGE_PROJECT_MEMORY.md)
5. [Architecture](../ARCHITECTURE.md)
6. [Project state and incident handoff](../PROJECT_STATE.md)
7. [Locked Evolution system](../EVOLUTION_SYSTEM_FINAL_LOCKED.md)

Detailed design, brand, economy, and feature specifications remain linked from this index. Do not maintain a competing priority list elsewhere.

## Current priority order
- **P0 now:** whole-repository cleanup and removal/archive of verified residuals, duplicates, stale files, conflicting rules and task lists.
- **P1 next:** safe self-repair loop that diagnoses, proposes, tests, previews and records fixes for owner approval.
- **After P0/P1:** live web intelligence and message assistance, reusing existing research/web-reader foundations after an end-to-end audit.
- **Deferred:** SP/SS currency behavior, screen-aware assistant and screen-rating system. Keep their specifications/backlog; do not implement them during P0/P1 unless the owner explicitly reprioritizes.

## Product definition
SAGE's live web/message-assistance plan is recorded in [Live Web Intelligence & Message Assistance](product/LIVE_WEB_INTELLIGENCE_AND_MESSAGE_ASSISTANCE.md). Existing research code is a foundation, not proof of a working end-to-end Chat experience.
SAGE ONE is a real AI execution ecosystem, not a chatbot demo. Core areas include Chat, Tasks, Research, Memory, Projects/Workspace, Voice, Onboarding, Authentication, durable execution, provider routing, owner-only Developer Mode, and a preview → approve → apply workflow.

Normal SAGE: understand → plan → execute with permission → verify → show result.
Owner Developer SAGE: inspect code → propose safe change → implement and test → preview → owner approves → apply/merge.

## Authority rules
- [Master Rules & To-Do](SAGE_MASTER_RULES_AND_TODO.md) controls current work order and operational rules.
- Detailed subject-specific specs govern their technical details; the latest explicit owner decision recorded in a canonical spec supersedes older drafts.
- Mark references APPROVED, HISTORICAL, SUPERSEDED, or UNREVIEWED.
- Never delete files before checking content, inbound references, build/runtime/test use, uniqueness and recovery.
- Record explicit implementation requests without asking redundant confirmation.
- No merge or production deployment without explicit owner approval.
- Prefer free resources; do not introduce paid services without approval.
- Never claim a test, device flow, or deployment passed without current evidence.

## Work protocol
Recover → Audit → Document → Plan → Implement → Test → Preview → Owner approval → Apply. Audit before editing, preserve existing work, work on a branch, record evidence, and update this index when canonical sources change.
