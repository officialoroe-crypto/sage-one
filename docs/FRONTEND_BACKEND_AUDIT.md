# SAGE ONE Frontend / Backend Audit

Last updated: 2026-10-09

## Purpose and audit rule

This document records evidence, not assumptions. A screen rendering, a successful build, or a route existing in FastAPI does not by itself prove that every button works end-to-end. Distinguish automated test results from real-device/provider verification.

## Runtime warning cleanup and current CI evidence

Two historical SAGE CI runs (37962853764 and 37962862824) failed because `tests/test_github_action_runtime.py` still expected `actions/upload-artifact@v5` after the Android workflow had moved to v7. Commit `a74474fcc6b24d0e86dab9dd58d10af2277aa8c1` corrected the contract test to require v7 and reject v5; subsequent CI runs passed.

Verified current main commit on 2026-10-09: `8fde9c3322711b075c210da7af77154cb591c35b`.

- [SAGE CI run 1673](https://github.com/officialoroe-crypto/sage-one/actions/runs/37969437072): Python passed with 218 tests and one Starlette/httpx deprecation warning; Flutter analysis and 59 Flutter tests passed.
- [Android Release run 257](https://github.com/officialoroe-crypto/sage-one/actions/runs/37969437080): analysis, Flutter tests, release APK, App Bundle, and artifact upload all passed.

Current workflows use `actions/setup-python@v6`, `actions/checkout@v6`, `actions/upload-artifact@v7`, and pin Ubuntu runners to `ubuntu-24.04`. The latest inspected logs do not contain the old `setup-python@v5` / Node.js 20 annotation. The remaining warning in the latest Python job is from Starlette's TestClient/httpx compatibility path. Annotations attached to historical runs are not evidence that current main is failing.

## Automated checks that exist

- SAGE CI runs Python compile/lint/tests, Flutter analysis/tests, and the Flutter-to-FastAPI route-contract test.
- Android release validation runs Flutter analysis/tests and builds APK/AAB artifacts.
- The frontend has screen/widget smoke tests for the command center, research, tasks, create, projects/project detail, agent, owner console, economy/evolution, world intelligence, memory, sales, onboarding/auth, voice fallbacks, and final surfaces.
- Some interactions have direct regression tests (for example notification mark-all-read, developer approval gating, memory review, workspace placeholder truthfulness, and the dialog/auth fixes listed below).
- The route-contract test checks that recognized Flutter API paths map to FastAPI routes. It is a static contract check, not a live server integration test.

## Fixes merged in PR #192

- Memory Add dialog owns its text controller for the full dialog-route lifetime; Save becomes enabled when content is entered.
- Stale-session recovery returns to login even if identity-provider sign-out throws.
- IdentityClient and SageApi use the same Android emulator default API host.
- Project Detail command/asset and Sales follow-up dialogs no longer dispose text controllers during the route's dismissal animation.
- Profile loading checks that the screen is still mounted before writing to its controllers.
- AI Studio workspace creation validates required fields and keeps controllers alive during dismissal.
- Regression tests cover these behaviors.

## Current audit branch

Profile required-field and age validation is already present on main and covered by `frontend/test/final_surfaces_test.dart`; it is not a pending change.

The follow-up audit fixes transient data-load recovery in Spark Wallet, Transactions, Evolution, Notifications, Payments, File Manager, and AI Studio. These screens now expose a Retry action after an initial read failure and clear stale error state after a retry succeeds. The new widget regression exercises failure → retry → recovered content for all seven screens. This work is on `audit/live-surface-error-recovery` and remains unmerged until its own CI passes. CI must pass before this change is merged.

## Known connection requirements

- Android emulator default: `http://10.0.2.2:8010`.
- The Huawei physical-device APK workflow compiles an explicit `SAGE_API_URL`, defaulting to `http://127.0.0.1:8010`. For that default, the phone must be connected through ADB reverse (`adb reverse tcp:8010 tcp:8010`) while the backend is running on the computer. A different reachable backend requires an explicit API URL.
- The current Android artifact is a private development/testing build path using local HTTP. It is not a production-store release; production requires a deployed HTTPS backend and production signing/configuration.
- GitHub Pages web builds without a public backend URL can only reach a backend that is reachable from the browser's own device (for example the owner's local backend). No public shared backend should be assumed.

## Not yet production-ready / requires external setup

- Production SMS/OTP delivery provider and credentials.
- Long-lived Google web session refresh UX and provider configuration.
- Payment provider credentials and real payment creation/settlement.
- Marketplace, Jobs, Learning, Community, Apps, Earnings, Identity Verification and First Run action buttons are interface placeholders. They explain that the live action is not connected and must not report false success.
- Full multi-tenant isolation if SAGE becomes a shared public service.
- Broader third-party integrations, permissioned publishing, and analytics feedback loop.
- Physical Huawei test of sign-in, backend connectivity, microphone permission/STT, TTS, app restart/session restore, and task execution.
- Full button-by-button interaction coverage and visual/reference regression are still in progress.

## Next verification order

1. Keep CI green and inspect the latest run, not historical annotations.
2. Exercise each live screen action against a fake client and assert the expected HTTP method/path, success state, error state, and cancellation behavior.
3. Keep placeholder integrations explicitly labelled as not connected until their real backend/provider exists.
4. Build the APK from the exact merged main commit.
5. Install it on the Huawei phone with the configured API route, then verify login, chat/task execution, memory, notifications, project actions, and voice on-device.
6. Only after those checks pass, claim the private demo is end-to-end ready.