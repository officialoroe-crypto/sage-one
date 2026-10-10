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


## Current execution checkpoint — Android Google sign-in (2026-10-10)

### Verified from the user's local terminal
- The SAGE ONE backend responds at `http://127.0.0.1:8000`.
- `GET /openapi.json` returned HTTP 200 and identified the API as SAGE ONE version `6.0.0`.
- `GET /identity/config` returned `success: true`, a Google client ID is configured, `developer_mode: true`, and `owner_mode_available: true`. Do not copy the client ID into public memory; record only that it is configured.
- ADB is installed at `C:\Users\Nishant\AppData\Local\Android\Sdk\platform-tools\adb.exe`. Git Bash does not have `adb` on PATH, so use the absolute path unless PATH is intentionally fixed.
- The Huawei P40 Pro is connected and authorized. ADB listed one device with status `device`.
- The user successfully ran `adb reverse tcp:8000 tcp:8000`; `adb reverse --list` returned `usb tcp:8000 tcp:8000`. The USB reverse mapping is confirmed for this session.

### What is and is not proven
- Proven: backend availability, identity config availability, ADB device authorization, and USB port reverse mapping.
- Not yet proven: APK is installed, the app is using port 8000, Google sign-in succeeds on the physical phone, token exchange succeeds, or owner-authenticated API calls work.
- A successful CI build is not proof of real-device login.

### Safe next steps
1. Keep avoiding local Flutter/Gradle builds while the laptop is hot or CPU usage is high. Prefer GitHub Actions-built APKs.
2. Before selecting or dispatching an APK build, inspect the Android workflow's `api_url` input and ensure the APK is configured for `http://127.0.0.1:8000` when using this USB reverse mapping.
3. Install only an artifact whose build configuration is verified; then launch it and test Google sign-in on the connected Huawei.
4. Capture the exact outcome/errors, then verify authenticated identity/API behavior before marking sign-in complete.
5. Continue in bulk mode with clear evidence-based status; do not claim a step passed unless its output confirms it.

### Current next action
The user said they will provide code so development can continue. Review the code they provide, identify the relevant SAGE ONE area, and proceed from this checkpoint without repeating completed checks.


## Mandatory assistant continuity checkpoint
Owner explicitly ordered that each assistant reply in the active workflow must be followed by a saved continuity update without another reminder. Follow memory/RULES.md. After each response, update this project checkpoint and memory/CURRENT_CONTEXT.md as appropriate, including current goal/constraints, work done and PR/commit/workflow links, verified versus assumed status, symptom/root cause/fix, failed or unverified checks, and next action with acceptance criteria. Never claim persistence if the write did not succeed. Keep public memory free of raw private transcripts, secrets, tokens, and sensitive owner data; if memory tools are unavailable, disclose the limitation and provide a portable checkpoint.

## Current checkpoint — Website onboarding first (2026-10-11)
- User chose to pause mobile app testing and finish website verification first.
- Backend logs supplied by owner: GET /identity/config 200; POST /identity/dev-login 200; POST /identity/onboarding 422 twice.
- Screenshot showed Memory Setup with a validation error requiring phone to have at least five characters. Exact request body was not captured.
- Cause found in shared frontend/lib/core/identity_client.dart: a blank phone string could be included in the onboarding JSON.
- PR #214 fixed this by omitting null/blank phone and trimming nonblank values; merged to main at dcd9de554a80dbcff18785228145ed414b77f8f6. https://github.com/officialoroe-crypto/sage-one/pull/214
- Pre-merge CI run #38055455236 passed Flutter analysis/tests and Android artifact build. This is not browser verification.
- Android workflow run #38056491244 was seen in progress after merge; do not resume mobile until website checks pass.
- Website: https://officialoroe-crypto.github.io/sage-one/
- Still unverified: Pages deployment includes merged code; blank-phone onboarding returns 200; key pages/buttons work; Google sign-in works. Developer mode may route to Owner Mode.
- Next actions: verify latest Pages deployment, hard-refresh website, test onboarding with phone blank, confirm backend returns 200; inspect Network response if 422. Then test primary navigation, profile/memory consent, relevant buttons/links, and Google login separately. Only then resume Android.

## Current checkpoint — Public marketing website launch (2026-10-11)
- Owner authorized creation and launch of the public SAGE ONE marketing website using a free deployment path, auditing the repository first and avoiding duplicate work.
- Audit found the existing static landing page in `website/`; it was not necessary to create a second website. Existing Pages workflow previously deployed only the Flutter app at the root, which would conflict with the marketing page.
- PR #218: https://github.com/officialoroe-crypto/sage-one/pull/218 (branch `feature/public-marketing-site-launch-20261011-v2`).
- Changes: SEO/Open Graph metadata, orbital favicon, public CTA to the app path, honest wording that some features are still in development, reduced-motion/accessibility fallback, combined artifact layout with marketing page at `/sage-one/` and Flutter app at `/sage-one/app/`, automatic main deployment on website/frontend changes, and PR validation separated from protected deployment.
- CI status when checked: PR workflow run #185 initially failed with no job steps/logs available through the connector; likely environment/job initialization issue, not yet root-caused. Workflow was then refactored into separate build and deploy jobs in commit `e99bb5380ea36f70a1085c9a87221cf8359e0b4f`. No workflow run was yet visible for this latest commit at the last check.
- Not verified: passing CI, merged PR, GitHub Pages configuration, successful deployment, live page rendering, or app deep link. Do not say the site is launched until verified.
- Next: retrieve fresh PR checks for latest head, fix any actual CI failure, merge only after checks pass, then confirm deployment URL and test landing page plus `/app/` route. Do not resume Android until website verification is complete.

## Latest website launch status — 2026-10-11
- The first website launch PR #217 was closed because its branch fell behind main while the required continuity checkpoint was saved. No work was discarded; changes were reapplied on a fresh branch based on current main.
- Active PR #218: https://github.com/officialoroe-crypto/sage-one/pull/218, branch `feature/public-marketing-site-launch-20261011-v2`.
- Current Actions: website workflow run #187 was cancelled because its shared concurrency group conflicted with another workflow. The workflow now uses an isolated `sage-one-public-pages` group; latest website workflow run #190 is queued. SAGE CI run #1797 is queued and Android Release run #341 is pending. No latest run has completed yet.
- A prior PR workflow attempt failed before steps/logs were available; the workflow was refactored to separate build validation from protected deployment. Latest run #190 is queued after isolating Pages concurrency; no successful build or deployment result is available yet.
- Deployment remains unverified. Do not merge until required checks pass; then verify GitHub Pages deployment and the `/sage-one/` marketing page plus `/sage-one/app/` link.
