# MISTAKES AND PREVENTION

This is a durable learning log. Record recurring mistakes with a prevention rule.

## Format

### [DATE] — Short mistake name
- What happened:
- Why it happened:
- Prevention:
- Scope:
- Status:

## Initial prevention rules

### 2026-09-27 — Do not treat the memory system as ChatGPT-only
- What happened: The first design was framed primarily as a ChatGPT working manual.
- Why it happened: The need for the same durable interaction contract inside future SAGE ONE was not fully captured.
- Prevention: Maintain a shared memory contract readable by both the owner-facing ChatGPT workflow and SAGE ONE, while keeping actual private conversation memory in SAGE ONE's private storage.
- Scope: Global owner-memory architecture.
- Status: Resolved by the current memory model.


### 2026-10-10 — Windows Git Bash cannot assume ADB is on PATH
- What happened: Running `adb devices` returned `bash: adb: command not found`, even though Android SDK platform-tools and a connected phone were present.
- Why it happened: The SDK's `platform-tools` directory is not on this Git Bash session's PATH.
- Prevention: Use the verified executable path `/c/Users/Nishant/AppData/Local/Android/Sdk/platform-tools/adb.exe` in commands, or configure PATH deliberately after confirming the SDK path. Clearly label expected output as an example and tell the owner not to paste output lines as commands.
- Scope: Local Android debugging on the owner's Windows/Git Bash environment.
- Status: Resolved for this session; ADB found the authorized phone and USB reverse mapping for port 8000 was confirmed.
