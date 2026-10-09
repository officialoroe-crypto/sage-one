# SAGE ONE Launch State

Last reconciled: 2026-10-08
Canonical main at Session 4 branch creation: `1207dfb3e662266c87ae05815bf6525152dd0e77`

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

Sales is executable inside SAGE: discovery → audit → score → durable lead → intelligence → approval-gated outreach → activity history → customer conversion. The owner Flutter Sales surface provides pipeline/detail views and human follow-up recording. External message sending remains intentionally disabled until a real provider/permission is configured.

## Priority 3 — Private deployment
**Status: AUTOMATED ANDROID RELEASE VALIDATION; PHYSICAL DEVICE VALIDATION REMAINS**

The Android release workflow is designed to:
- validate the configured device-reachable backend URL;
- run Flutter analyzer and tests before release builds;
- build both release APK and release App Bundle;
- publish both artifacts for inspection/download from the workflow run.

The Android emulator default is `http://10.0.2.2:8010`. Physical devices must use the workflow dispatch `api_url` input or the `SAGE_ANDROID_API_URL` repository variable with a backend URL reachable by that device. CI success does not prove the app has been exercised against a live production backend or physical device.

## Priority 4 — Developer Mode
**Status: IMPLEMENTED + SAFETY-GATED**

Developer Mode is available to the owner. Preview is non-mutating; applying a proposal requires an explicit approval action. Proposals are durable and owner-scoped.

## CI / release evidence
SAGE CI passed for the Session 4 branch head before this current-main integration refresh. The current-main branch must pass its own checks before merge. Android release artifact availability and live-device behavior must be confirmed from the actual workflow run; do not infer them from the workflow definition.

## Explicitly deferred
- Production SMS/OTP delivery.
- Long-lived Google web session refresh.
- Full public/multi-tenant architecture.
- Broad third-party integrations.
- Production payment-provider integration.
- Production signing/keystore secrets and store publishing.
- Physical-device validation until a real device and reachable backend are available.
- Pixel-perfect visual parity where original artwork/assets are not present.
