# SAGE ONE — AI WORK CONTROL PLANE

This directory is the machine-readable coordination state for independent AI sessions working on the repository.

## Protocol
- `ACTIVE_WORK.yaml` contains active claims.
- A claim reserves its declared path/module scope.
- Agents must inspect `main` and this file before editing.
- Exact-path overlap is forbidden while a claim is active.
- Parent-directory overlap is treated conservatively: e.g. `execution/` overlaps `execution/engine.py`.
- Claims are not permission to merge; PR + CI remains required.
- Human can release, reassign, or override a claim.
- Stale claims require explicit takeover; do not silently steal work.

## Agent handshake
1. Read `PROJECT_STATE.md`, `TODO.md`, `AI_COLLABORATION.md`, and `coordination/ACTIVE_WORK.yaml`.
2. Inspect latest `main` SHA.
3. Claim a non-overlapping scope.
4. Work only inside the claim unless the claim is updated first.
5. Before PR, record changed files, tests, failures, and next action.
6. After merge/handoff, release the claim.

## Future enforcement
A script/CI check will validate claim shape, stale timestamps, path overlap, and PR changed-file overlap. Until that check exists, this file is the shared coordination contract and GitHub PR/issues are the authoritative claim records.
