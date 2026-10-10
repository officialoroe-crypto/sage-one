# SAGE ONE Launch State

Last reconciled: 2026-10-10
Canonical main at the latest inspected checkpoint: `5d8efe7c61ed9691be66d83b77ec9de79fbcfaaf`

## Current website-first verification checkpoint — 2026-10-10

- PR #201 and PR #202 are merged; their latest SAGE CI and Android release validations passed.
- PR #218 merged and [Pages run 38058717863](https://github.com/officialoroe-crypto/sage-one/actions/runs/38058717863) deployed artifact `11671519061`. This artifact combined the marketing landing page and Flutter web build at `/sage-one/app/`; the authenticated web app was therefore published before the required web + mobile QA sequence. Browser authentication and live backend behavior are not verified.
- Root cause: the new workflow deployed on `push: main` and bundled `frontend/build/web` into the Pages artifact; the non-PR condition allowed automatic deployment.
- Corrective branch `fix/hold-public-app-until-web-mobile-qa` switches public Pages content to marketing-only and gates deployment behind manual dispatch. Flutter web analysis/tests and a separate QA build artifact continue in CI. After the fix merges, manually redeploy marketing-only content to remove the app path from Pages.
- SAGE CI passed on current pre-correction main: [run 38058766698](https://github.com/officialoroe-crypto/sage-one/actions/runs/38058766698). Android Release [run 38058766769](https://github.com/officialoroe-crypto/sage-one/actions/runs/38058766769) was in progress when last checked.
- Website QA must precede mobile QA. Before running locally, reconcile API ports: Flutter defaults to `http://localhost:8010`, while an earlier backend checkpoint reported port `8000`; configure one explicit `SAGE_API_URL` after inspecting the actual backend launch configuration.


## Priority 0 — Core runtime
**Status: IMPLEMENTED + CI VERIFIED**

The private-first app has a real command-to-execution loop:
- Chat → durable command → worker → result → chat history.
- Research persists into research records and project assets.
- Project-scoped commands are supported.
- Tasks expose active/done/failed filtering.
- SAGE Voice capture, wake listening and TTS use the same durable command pipeline.
- Developer Mode supports preview → explicit approval → apply.

## Priority 1 — Daily owner workspace
**Status: IMPLEMENTED; automated validation hardened; physical-device review remains**

The shell exposes Command Center, Research, Tasks, Create, Projects, Memory, Evolution, Agent, World Intelligence, Owner Console, Voice, Chat, Apps Hub/ecosystem surfaces, File Manager, AI Studio, Spark Wallet, Payments, Transactions, Profile, Settings and Notifications. Memory now includes a review queue for unconfirmed automatically learned memories, with keep/reject actions.

## Priority 2 — Useful business workflow
**Status: IMPLEMENTED + CI VERIFIED; EXTERNAL DELIVERY REMAINS**

Sales is executable inside SAGE: discovery → audit → score → durable lead → intelligence → approval-gated outreach → activity history → customer conversion. The owner Flutter Sales surface provides pipeline/detail views and human follow-up recording. External message sending remains intentionally disabled until a real provider/permission is configured.

## Priority 3 — Private deployment
**Status: AUTOMATED ANDROID RELEASE VALIDATION; PHYSICAL DEVICE VALIDATION REMAINS**

The Android release workflow:
- validates the configured device-reachable backend URL;
- runs Flutter analyzer and tests before release builds;
- ensures Android microphone permission is present for SAGE Voice;
- builds both release APK and release App Bundle;
- publishes both artifacts for inspection/download from the workflow run.

The Android emulator default is `http://10.0.2.2:8010`. Physical devices must use the workflow dispatch `api_url` input or the `SAGE_ANDROID_API_URL` repository variable with a backend URL reachable by that device. CI success does not prove the app has been exercised against a live production backend or physical device.

## Priority 4 — Developer Mode
**Status: IMPLEMENTED + SAFETY-GATED**

Developer Mode is available to the owner. Preview is non-mutating; applying a proposal requires an explicit approval action. Proposals are durable and owner-scoped.

## Historical CI / release evidence (older baseline)
- Session 4 Android release validation: PASS; APK and AAB built and uploaded — [run #37884835156](https://github.com/officialoroe-crypto/sage-one/actions/runs/37884835156).
- Final frontend bulk PR SAGE CI: PASS — 214 Python tests, Flutter analysis clean, 27 Flutter tests — [run #37886497211](https://github.com/officialoroe-crypto/sage-one/actions/runs/37886497211).
- Final frontend bulk PR Android release validation: PASS; APK and AAB built and uploaded — [run #37886497229](https://github.com/officialoroe-crypto/sage-one/actions/runs/37886497229).
- Main SAGE CI after the frontend merge: PASS — [run #37886992614](https://github.com/officialoroe-crypto/sage-one/actions/runs/37886992614).
- Main God Mode Developer Website after the frontend merge: PASS — [run #37886992587](https://github.com/officialoroe-crypto/sage-one/actions/runs/37886992587).
- Main Android release validation after the frontend merge was still running when this document was prepared; see [run #37886992592](https://github.com/officialoroe-crypto/sage-one/actions/runs/37886992592). The exact PR head already passed release validation above.

## Explicitly deferred
- Production SMS/OTP delivery and provider credentials.
- Long-lived Google web session refresh UX.
- Local/provider-backed premium lifecycle smoke test on the user's configured environment.
- Full public/multi-tenant architecture unless SAGE becomes shared.
- Broader third-party integrations and permissioned publishing adapters.
- Analytics-driven feedback improvement loop.
- Pixel-level Evolution screenshot/golden regression and full visual/reference comparison.
- Production payment-provider integration.
- Production signing/keystore secrets and store publishing.
- Physical-device validation until a real device and reachable backend are available.
