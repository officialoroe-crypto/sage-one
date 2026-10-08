# SAGE ONE Launch State

Last reconciled: 2026-10-08
Canonical main after Session 3: `055d8eac6e73a10e49c429e5332dfe7fb0c05619`

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
**Status: FOUNDATION AVAILABLE**

The architecture supports research, persistent projects/assets/workflows and real task execution. Content/video and sales foundations exist, but a polished end-to-end business workflow still needs external integrations and production-grade publishing/analytics adapters.

## Priority 3 — Private deployment
**Status: AUTOMATED ANDROID RELEASE VALIDATION HARDENED; PHYSICAL DEVICE VALIDATION REMAINS**

The Android release workflow now:
- validates the configured device-reachable backend URL;
- runs Flutter analyzer and tests;
- builds both release APK and release App Bundle;
- publishes both release artifacts for inspection/download from the workflow run.

The Android emulator default remains `http://10.0.2.2:8010`. Physical devices must use the workflow dispatch `api_url` input or the `SAGE_ANDROID_API_URL` repository variable with a backend URL reachable by that device.

## Priority 4 — Developer Mode
**Status: IMPLEMENTED + SAFETY-GATED**

Developer Mode is available to the owner. Preview is non-mutating; applying a proposal requires an explicit approval action. Proposals are durable and owner-scoped.

## CI / release evidence
Main has successful SAGE CI, Android release validation and God Mode Developer Website workflows. Android release validation covers both APK and AAB outputs and keeps backend endpoint configuration explicit.

## Explicitly deferred
- Production SMS/OTP delivery.
- Long-lived Google web session refresh.
- Full public/multi-tenant architecture.
- Broad third-party integrations.
- Production payment-provider integration.
- Production signing/keystore secrets and store publishing.
- Pixel-perfect visual parity where original artwork/assets are not present.
