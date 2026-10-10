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


## Mandatory continuity rule — 2026-10-11
Owner explicitly ordered that after every assistant reply, relevant conversation context, leads, decisions, causes, fixes, evidence, and next steps must be saved without another reminder. See memory/RULES.md. For active work, update this file and the project-specific file after each reply when tools permit. If a write fails, disclose it and provide a portable checkpoint. Do not put raw private chat transcripts, secrets, tokens, or sensitive details in this public repository.

## Active checkpoint — SAGE ONE website onboarding first
- Owner explicitly paused mobile testing and wants website verification completed first.
- User's backend logs: GET /identity/config = 200; POST /identity/dev-login = 200; POST /identity/onboarding = 422 twice.
- Screenshot showed phone validation requiring at least five characters. Code review found the shared Flutter identity client could include an empty phone string.
- PR #214 changed frontend/lib/core/identity_client.dart to omit null/blank phone values and trim nonblank values. Merged into main at dcd9de554a80dbcff18785228145ed414b77f8f6. PR: https://github.com/officialoroe-crypto/sage-one/pull/214
- Pre-merge CI run #38055455236 passed automated Flutter analysis/tests and Android build/artifact steps. This does not prove website behavior.
- Android release workflow run #38056491244 was observed in progress after merge; mobile remains on hold until website passes.
- Website: https://officialoroe-crypto.github.io/sage-one/
- Not verified yet: deployed commit contains fix; website onboarding returns 200; post-onboarding pages/buttons work; Google sign-in works. Developer mode can route to Owner Mode instead of Google login.
- Next: check GitHub Pages deployment status, hard-refresh website, complete onboarding with phone blank, and confirm backend POST /identity/onboarding returns 200. If 422, inspect Network request response. Then test key navigation/buttons and Google sign-in separately. Resume mobile only after website verification.
- Avoid local Flutter/Gradle builds if laptop heats up; prefer GitHub Actions artifacts. Never store raw logs containing identifiers or secrets in public memory.

## Active checkpoint — Public marketing website launch (2026-10-11)
- Owner approved creating and launching the public SAGE ONE marketing website, free-first, without duplicating existing work.
- Audit found an existing landing page at `website/index.html`, `website/styles.css`, and `website/app.js`; visual direction already matches the near-black/cyan/violet orbital SAGE identity. `website/README.md` described a website workflow path that was not found; the existing Pages workflow manually published the Flutter app at the root.
- Open PR #218: https://github.com/officialoroe-crypto/sage-one/pull/218 on branch `feature/public-marketing-site-launch-20261011-v2`.
- Changes in PR: SEO/Open Graph metadata, orbital favicon, main CTA to `/sage-one/app/`, clearer statement that some capabilities remain in development, reduced-motion and IntersectionObserver fallback, and a combined Pages workflow publishing marketing site at `/sage-one/` and Flutter app at `/sage-one/app/`.
- Workflow runs for PR head `aacd92e86abb4bfc7a17ec96426ef8f73212961c`: SAGE CI run #1779 queued, Android Release #334 queued, public website workflow #185 waiting when checked. No CI or deployment result yet.
- Deployment is intentionally not called launched until checks pass, PR merges, and Pages/browser verification confirms the public URL. Do not resume mobile testing ahead of website verification.
- Next: monitor PR #218 checks; fix failures; after successful checks merge as authorized by the owner's explicit launch request, verify Pages deployment, then ask owner to inspect the public page and confirm the web-app link. If Pages is configured for a custom domain or not GitHub Actions, adjust configuration rather than claim success.

## Latest website launch status — 2026-10-11
- The first website launch PR #217 was closed because its branch fell behind main while the required continuity checkpoint was saved. No work was discarded; changes were reapplied on a fresh branch based on current main.
- Active PR #218: https://github.com/officialoroe-crypto/sage-one/pull/218, branch `feature/public-marketing-site-launch-20261011-v2`.
- Current Actions: website workflow run #187 was cancelled because its shared concurrency group conflicted with another workflow. The workflow now uses an isolated `sage-one-public-pages` group; latest website workflow run #190 is queued. SAGE CI run #1797 is queued and Android Release run #341 is pending. No latest run has completed yet.
- A prior PR workflow attempt failed before steps/logs were available; the workflow was refactored to separate build validation from protected deployment. Latest run #190 is queued after isolating Pages concurrency; no successful build or deployment result is available yet.
- Deployment remains unverified. Do not merge until required checks pass; then verify GitHub Pages deployment and the `/sage-one/` marketing page plus `/sage-one/app/` link.


## Latest website launch checkpoint — 2026-10-10
- Owner reaffirmed that making the SAGE ONE web application live is the top priority; laptop is lagging with Opera/ChatGPT consuming substantial CPU. Avoid local Flutter/Gradle builds and use GitHub Actions; suggested checking Opera's task manager (Shift+Esc where supported), closing unnecessary tabs/extensions, and Windows Task Manager sorted by CPU.
- PR #218 merged successfully into `main` using squash merge: https://github.com/officialoroe-crypto/sage-one/pull/218. Merge commit: `3d951d2c7ffb3ed1d1ec70edb64c09d29432f4b4`.
- Verified PR-head SAGE CI run #1801 succeeded: https://github.com/officialoroe-crypto/sage-one/actions/runs/38058424862.
- Verified PR-head public website workflow run #192 succeeded: https://github.com/officialoroe-crypto/sage-one/actions/runs/38058424871. Flutter pub get, analyze, tests, web build under `/sage-one/app/`, and combined site packaging all passed. Upload/deploy steps were correctly skipped on pull_request.
- Not yet verified: post-merge GitHub Pages deployment run, actual public page rendering, app deep link, or browser onboarding/auth flows. Attempts to access the live URLs via the available web fetch were blocked/unavailable, which is not proof the URLs are down.
- Intended URLs remain https://officialoroe-crypto.github.io/sage-one/ (marketing site) and https://officialoroe-crypto.github.io/sage-one/app/ (web app). Do not call launch complete until a main-branch Pages deployment succeeds and the owner/browser confirms both URLs.
- Next: inspect GitHub Actions deployment on main / Pages settings; then verify both URLs. Only after website verification resume onboarding/button checks and later Android Google sign-in. Do not use local heavy builds while CPU is high.


## Backend connection diagnosis — 2026-10-10
- Owner ran `curl -i http://127.0.0.1:8010/identity/config`; curl returned error 7, could not connect. `netstat -ano | findstr :8010` produced no visible output, consistent with no process listening on port 8010 at that time.
- This establishes that the local endpoint is unreachable; it does not yet establish whether the intended backend should run on 8010 or whether the public Pages app is mistakenly configured to call localhost.
- Next: ask owner to list `C:\SageOne` and `C:\SageOne\Backend` (Git Bash: `cd /c/SageOne && ls`, then `ls /c/SageOne/Backend`) to identify actual local checkout/backend structure and startup instructions. Do not run a local Flutter/Gradle build; CPU is already high. If the error is from the public deployed web app, localhost is the visitor's machine and production must use a reachable HTTPS backend URL.
