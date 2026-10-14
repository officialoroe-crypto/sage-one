# SAGE ONE bulk browser QA

## What it runs

The **SAGE Workspace Browser QA** workflow starts a temporary local HTTP server inside an isolated GitHub Actions runner and opens the real `website/` source in Chromium with Playwright. It does not publish the website, deploy the app, or release an APK.

The suite covers:
- Live Core `/health` and `/identity/config` smoke checks.
- Workspace boot and uncaught JavaScript errors.
- Real clicks for navigation and Chat authentication guard.
- Rendering of the primary screens and an action-wiring inventory.
- Voice transcript capture with a simulated speech-recognition provider, confirming capture does not auto-submit.
- Files category filtering and honest disabled states for unconnected Community actions.
- Saved conversation list/open/archive/restore and Activity Center tasks/notifications using controlled API fixtures.
- Backend API tests against an isolated SQLite database for owner-scoped history, archive/restore, and task-list isolation.

## How to run it

1. Open the repository's **Actions** tab.
2. Select **SAGE Workspace Browser QA**.
3. Select **Run workflow** and choose the branch to test.
4. Open the run and inspect the job summary.
5. Download the `sage-one-browser-qa-<run-id>` artifact for the HTML report, JSON inventory, screenshots, video, and traces.

Artifacts expire after seven days. They contain QA fixtures only, not Google credentials or private account data.

## What a green run does not prove

A green browser run does not prove real Google owner login, an actual AI-generated answer, physical microphone permission/audio, external payments, KYC, or completion by a live background worker. Those require dedicated authenticated/provider tests. The history and Activity Center browser tests use API fixtures to verify UI-to-action behavior; the Python tests separately exercise the new history/archive API against an isolated database. No test bypasses owner authorization in production.

## Status language

- **Implemented:** code exists.
- **Connected:** UI action calls its intended API or dispatcher.
- **Tested:** automated test ran successfully.
- **Verified live:** the real intended environment confirmed the behavior.
- **Deferred/blocked:** a required provider, credential, deployment, or live test is still missing.

Do not treat a source file, API route, or green CI alone as proof of a live feature.
