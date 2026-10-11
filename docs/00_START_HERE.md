# SAGE ONE — Start Here

Status: Canonical documentation entry point. Last reviewed: 2026-10-11.

## Required reading order
1. [Canonical design system](design/SAGE_ONE_CANONICAL_DESIGN_SYSTEM.md)
2. [SAGE Spark economy](product/SAGE_SPARK_ECONOMY.md)
3. [Screen-aware assistant](product/SCREEN_AWARE_ASSISTANT.md)
4. [Cleanup manifest](CLEANUP_MANIFEST.md)
5. [Project memory](SAGE_PROJECT_MEMORY.md)
6. [Architecture](../ARCHITECTURE.md)
7. [Development rules](../DEVELOPMENT_RULES.md)
8. [Locked Evolution system](../EVOLUTION_SYSTEM_FINAL_LOCKED.md)

## Authority rules
- This is the entry point; detailed specs remain authoritative for their subject.
- The latest explicit owner decision recorded in a canonical spec takes precedence over older drafts and screenshots.
- Mark every reference APPROVED, HISTORICAL, SUPERSEDED, or UNREVIEWED.
- Do not invent missing details or delete files before checking content and references.
- When the owner explicitly says to implement a feature, record it without asking for redundant confirmation.
- No merge or production deployment without explicit owner approval.
- Prefer free resources; do not introduce paid services without approval.
- Never claim a test, device flow, or deployment passed without current evidence.

## Product definition
SAGE ONE is a real AI execution ecosystem, not a chatbot demo. Core areas include Chat, Tasks, Research, Memory, Projects/Workspace, Voice, Onboarding, Authentication, durable execution, provider routing, owner-only Developer Mode, and a preview → approve → apply workflow.

Normal SAGE: understand → plan → execute with permission → verify → show result.
Owner Developer SAGE: inspect code → propose safe change → implement and test → preview → owner approves → apply/merge.

## Canonical decisions
- Owner memory and owner-only developer access must be protected from other users.
- Evolution and both Spark balances are separate systems; see linked specifications.
- Screen reading must be visibly enabled, permission-based, privacy-conscious, and immediately pausable.
- Use stable asset paths; historical screenshots must not silently override current specifications.

## Work protocol
Recover → Audit → Document → Plan → Implement → Test → Preview → Approve → Apply. Audit before editing, preserve existing work, work on a branch, record evidence, and update this index when canonical sources change.
