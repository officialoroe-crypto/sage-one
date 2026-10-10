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
- Current Actions: website workflow run #187 is building; SAGE CI run #1791 has Python passing while Flutter tests are running; Android Release run #338 is running. Latest website job was still at Flutter SDK setup when last checked.
- A prior PR workflow attempt failed before steps/logs were available; the workflow was refactored to separate build validation from protected deployment. Latest run has started normally but has not yet completed.
- Deployment remains unverified. Do not merge until required checks pass; then verify GitHub Pages deployment and the `/sage-one/` marketing page plus `/sage-one/app/` link.
