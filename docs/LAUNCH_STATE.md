# SAGE ONE Launch State

Last reconciled: 2026-10-09
Canonical main: `c57c36c60d0056099f5bdc715405c9400fa8bd45`

## Priority 0 — Core runtime
**Status: IMPLEMENTED + CI VERIFIED**

The private-first app has a real command-to-execution loop:
- Chat → durable command → worker → result → chat history.
- Research persists into research records and project assets.
- Project-scoped commands are supported.
- Tasks expose active/done/failed filtering.
- Voice capture and TTS feed the same durable command pipeline.
- Developer Mode supports preview → explicit approval → apply.

## Priority 1 — Daily owner workspace
**Status: IMPLEMENTED; automated validation hardened; physical device review remains**

The shell exposes Command Center, Research, Tasks, Create, Projects, Memory, Evolution, Agent, World Intelligence, Owner Console, Voice, Chat, Apps Hub/ecosystem surfaces, File Manager, AI Studio, Spark Wallet, Payments, Transactions, Profile, Settings and Notifications.

## Priority 2 — Useful business workflow
**Status: IMPLEMENTED + CI VERIFIED; EXTERNAL DELIVERY REMAINS**

Sales is now executable inside SAGE: discovery → audit → score → durable lead → intelligence → approval-gated outreach → activity history → customer conversion. The owner Flutter Sales surface provides pipeline/detail views and human follow-up recording. External message sending remains intentionally disabled until a real provider/permission is configured.

## Priority 3 — Private deployment
**Status: AUTOMATED RELEASE PATH HARDENED; PHYSICAL DEVICE VALIDATION REMAINS**

The product is private-first and owner-scoped. The next real-world step is device/runtime validation using the user's configured backend and Android build.

## Priority 4 — Developer Mode
**Status: IMPLEMENTED + SAFETY-GATED**

Developer Mode is available to the owner. Preview is non-mutating; applying a proposal requires an explicit approval action. Proposals are durable and owner-scoped.

## CI / release evidence
Main has successful SAGE CI, Android APK and God Mode Developer Website workflows. The Android workflow now uses an Android-emulator-reachable host default (`10.0.2.2`) while still allowing an explicit backend URL for physical devices.

## Explicitly deferred
- Production SMS/OTP delivery.
- Long-lived Google web session refresh.
- Full public/multi-tenant architecture.
- Broad third-party integrations.
- Production payment-provider integration.
- Pixel-perfect visual parity where original artwork/assets are not present.
