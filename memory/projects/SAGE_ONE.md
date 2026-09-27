# SAGE ONE — MEMORY INTEGRATION

## Role

SAGE ONE is the implementation target for the shared owner-memory contract.

## Current identity

- Assistant: sage.ai
- Mode: private-first owner mode
- Primary use: one owner before any public multi-user release

## Integration requirements

SAGE ONE should consume the memory contract in `memory/CHATGPT_OS.md` and `memory/OWNER_MEMORY_MODEL.md`.

The runtime memory layer should provide:
- owner-scoped retrieval;
- structured durable memory;
- conversation summaries;
- project-scoped memory;
- explicit memory provenance;
- memory update/write operations;
- user isolation before multi-user mode is enabled.

## Important distinction

The GitHub files define the **rules and schema**.

The SAGE ONE runtime/database should contain the **private data**.

Do not make the public Git repository the database for the owner's private conversations.

## Future conversation continuity

A new SAGE ONE conversation should be able to load a compact relevant context package such as:

`OWNER PROFILE + DURABLE RULES + RELEVANT PROJECT MEMORY + RECENT CONVERSATION SUMMARY + ACTIVE TASK STATE`

It should not blindly load the entire conversation archive into every request.
