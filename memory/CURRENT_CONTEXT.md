# OWNER CONTEXT — SAFE CROSS-PROJECT SUMMARY

Last updated: 2026-10-10

## Relationship model

The owner wants SAGE ONE to function as a personal AI mentor and execution partner with continuity across conversations.

## Current priority

Finish the private-first owner experience before considering multi-user/public product work.

## Memory priority

The memory system must preserve:
- how the owner wants to communicate;
- durable preferences;
- decisions and constraints;
- mistakes and prevention rules;
- relevant project state;
- conversation summaries needed for continuity.

The system must not require every historical sentence to be retained as memory.

## Privacy

This repository is public. Sensitive owner information and raw private conversations must stay out of GitHub and in the private SAGE ONE memory store.


## Active SAGE ONE checkpoint — 2026-10-10
- Android Google sign-in is still under real-device verification; do not call it complete yet.
- Local backend `127.0.0.1:8000` responds with HTTP 200 for OpenAPI; API version reports `6.0.0`.
- `/identity/config` reports success, Google client ID configured, developer mode enabled, and owner mode available. The actual client ID is intentionally not stored in public memory.
- Huawei device is ADB-authorized. ADB executable is at `C:\Users\Nishant\AppData\Local\Android\Sdk\platform-tools\adb.exe`; Git Bash cannot resolve `adb` by name.
- USB reverse mapping `tcp:8000 -> tcp:8000` was successfully established and listed.
- Next: inspect user-provided code / Android workflow configuration, ensure the selected APK targets port 8000, then test Google sign-in and authenticated owner behavior on the phone.
- Resource constraint: laptop previously reached high CPU usage and became hot. Avoid local Flutter/Gradle builds for now; prefer verified GitHub Actions artifacts.
- Public repository memory records only safe project state. Do not commit raw logs containing identifiers, secrets, tokens, or private conversation data.
