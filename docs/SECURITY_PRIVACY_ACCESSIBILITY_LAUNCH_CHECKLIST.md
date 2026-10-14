# SAGE ONE — Functional, Security, Privacy, Accessibility & Launch Readiness

**Status:** Worklist recorded; checklist items are not claims of implementation or verification.
**Owner rule:** Do not deploy, publish, enable public access, or release the app/site until the owner explicitly approves. Private/staging test environments only.
**Evidence rule:** Mark each item separately as Specified, Implemented, Connected, Tested, Verified, or Blocked. A green build is not runtime proof. Never record PASS without repeatable evidence.

**Initial live smoke evidence (2026-10-14 UTC):** GitHub Actions run [38617788443](https://github.com/officialoroe-crypto/sage-one/actions/runs/38617788443) passed the read-only health/config checks and unauthenticated Chat rejection. The same workflow run built the Flutter web QA artifact successfully; this was QA-only and did not deploy. Browser QA run [38617788746](https://github.com/officialoroe-crypto/sage-one/actions/runs/38617788746) passed 16 Playwright tests, but the saved-history/activity/authenticated-chat tests use mocked API responses. They do not prove durable production persistence or a real model reply.

## Initial code-inspection findings (2026-10-15; not a complete audit)

These are observed from repository source, not from a live penetration test. Findings remain open unless explicitly marked otherwise.

- **Workflow behavior confirmed:** the website workflow previously used `if: github.event_name != 'pull_request'` on its live-backend smoke job, so that job was deliberately skipped for PR runs. A draft security PR now removes that condition so the read-only smoke can run during PR validation; its actual result must still be checked.
- **CORS needs tightening:** `app/main.py` currently allows all methods and headers, enables credentials, and includes localhost origins alongside the canonical frontend origin. Review exact required origins/methods/headers and production-only behavior before public hosting.
- **API security headers were absent in the inspected main version:** a separate draft PR adds baseline API response headers and tests. It does not yet set static-site CSP or prove the hosting proxy emits HSTS.
- **Chat input bounds were missing:** a separate draft PR adds message/label length limits and regression tests. Other request models and nested context still need an input-size/validation review.
- **Environment fail-closed behavior needs review:** `config/settings.py` defaults `SAGE_ENV` to development and derives private/developer defaults from it. Production must explicitly set and validate environment settings; verify the deployed environment without exposing values.
- **Data minimization risk:** `identity/api.py` onboarding/profile models accept phone, address, age, basic-info and help-intent fields. Confirm each field is necessary, explain it before collection, define retention/deletion, and avoid collecting address/age unless required.
- **Database deployment risk:** `database/connection.py` falls back to a local SQLite file if `SAGE_DATABASE_URL` is absent. Production startup should require an intentional durable database configuration and documented backup/restore.
- **Browser-side data retention risk:** `website/js/core.js` persists the full SAGE state object under `sage-one-state-v1` in localStorage, including user profile fields and local chat/search state. Inventory exactly which fields are used, minimize or remove unnecessary personal data, clear appropriate state on sign-out/reset, and document local storage and deletion behavior; localStorage is not encrypted storage.
- **Third-party request observed:** `website/index.html` loads Google Fonts from Google-hosted domains. Inventory its privacy impact and decide whether to self-host or disclose it; inspect all other scripts/embeds.
- **Dependency policy needs work:** `requirements.txt` contains broad version ranges and includes pytest in the runtime requirements file. Review lockfiles, production/dev dependency separation, vulnerabilities and licenses before changing versions.
- **Accessibility source scan:** multiple dynamic form templates use sibling `<label>` elements without `for` associations (the scan found 17 label tags and no `for=` attributes across the website JS files inspected). Verify/fix label-to-control associations and keyboard/focus behavior. This is a source-level finding, not a complete WCAG audit.
- **Policy pages/consent:** no Privacy, Terms, Cookie, or Refund policy references were found in the website JS files inspected. Internal draft documents are being added separately; they are not public-facing pages and must not be treated as legally complete.
- **Legal scope:** official Nepal Law Commission sources identify the Privacy Act, 2075 and E-Commerce Act, 2081; the Electronic Transactions Act, 2063 and Consumer Protection Act, 2075 are also relevant review candidates. Applicability and effective requirements need qualified Nepal legal review; cookie-consent requirements depend on actual tracking and user jurisdictions.

## Artifacts added during the initial pass
- [x] Record this full worklist in the repository.
- [x] Add a source-derived environment-variable inventory with secrets redacted and deployment limitations stated.
- [x] Add internal-only drafts for Privacy Policy, Terms and Conditions, Cookie Policy, Refund/Cancellation Policy, and form-consent copy. These are not public website pages and are not approved for publication.
- [ ] Convert policy drafts into accessible public pages only after operator details, data flows, and legal review are complete.
- [ ] Verify actual hosted environment values and settings; this cannot be done from repository source alone.

## Deferred website polish and legal-compliance backlog — owner-requested (2026-10-15)

**Priority rule:** finish the real core work first (authenticated backend Chat, persistence/account isolation, Google sign-in, real device voice, core security and test verification). Keep the following tasks queued for the later website polish/accessibility/legal phase. Do not deploy or publicly release until the owner explicitly approves.

### Later legal, privacy and compliance work
- [ ] Review applicability and implement the legally appropriate requirements for Nepal, including the Privacy Act, 2075; E-Commerce Act, 2081; Electronic Transactions Act, 2063; and Consumer Protection Act, 2075, with qualified local legal advice.
- [ ] Complete and legally review Privacy Policy, Terms and Conditions, Cookie Policy, Refund/Cancellation Policy, and form-consent notices before publication.
- [ ] Determine whether cookie consent is required from actual cookies, local storage, analytics, embeds and third-party requests; implement consent controls where required.
- [ ] Minimize collected data, verify analytics and third-party embeds, remove fake reviews and unsupported claims, verify business/operator details, and check image/font/media copyright and licensing.
- [ ] Check security, privacy, accessibility and consumer-law obligations for the actual deployed site/app and the jurisdictions served.

### Later website usability, SEO, assets and responsive design work
- [ ] Add/verify vertical scrolling where content requires it and horizontal scrolling only for intentional, usable overflow areas; prevent accidental page-level horizontal overflow.
- [ ] Find and fix broken internal/external links and verify every footer link.
- [ ] Add a functional mobile navigation menu.
- [ ] Add a correct favicon and app/site icons.
- [ ] Fix unique, accurate page titles and add useful meta descriptions to each relevant page.
- [ ] Add an approved custom photo/hero image to the appropriate page; confirm ownership/licensing and add suitable alternative text.
- [ ] Update copyright year to the correct current year and verified business/operator details.
- [ ] Compress/resize images and use appropriate modern formats without visibly damaging quality.
- [ ] Find and fix every broken or inert button; add truthful success and error messages for real outcomes and failures.
- [ ] Remove placeholder copy, unfinished demo text, fake reviews, unsupported claims, and unused/dead navigation items.
- [ ] Fix mobile overflow and layout problems, including narrow screens and landscape; optimize every page for mobile and desktop.
- [ ] Make the logo clickable and route it to the intended home page.
- [ ] Make phone numbers clickable with tel: links and email addresses clickable with mailto: links only when verified contact details are available.
- [ ] Check keyboard operation, visible focus, semantic labels, contrast, alt text, clear button names, and accessible error/success announcements.
- [ ] Test responsive layouts and interactions on desktop browsers and actual mobile devices, not only screenshots or builds.

### Completion evidence required
- [ ] Record each item as Specified, Implemented, Connected, Tested, Verified, or Deferred/blocked.
- [ ] Attach link-check, responsive-browser, accessibility, image-size, and interaction test evidence.
- [ ] Do not mark a task complete because its markup or code merely exists.
- [ ] Keep this backlog in the repository and carry it into future SAGE ONE work sessions; do not ask the owner to repeat this list.

## 0. Safety and working rules
- [ ] Preserve existing user changes and data; inspect before modifying.
- [ ] Never print, commit, or expose secret values. Report secret names and locations only, with values redacted.
- [ ] Do not rotate/revoke credentials without checking dependencies and preparing a safe replacement plan.
- [ ] Do not deploy or make public DNS/hosting changes without explicit owner approval.
- [ ] Create a private/staging test path for multiple devices with authentication; do not use production data for tests.
- [ ] Record test scope, environment, date, result, evidence, and remaining uncertainty.

## 1. Backend, live smoke test, Chat and persistence
- [ ] Find why the live-backend smoke-test job was skipped; distinguish workflow conditions from backend health.
- [x] Run safe, read-only live smoke checks on the configured Render backend: /health healthy, /identity/config success with Google client ID configured, and unauthenticated POST /chat rejected with HTTP 401 (run 38617788443). This is not an authenticated model-response test.
- [ ] Verify authenticated requests return genuine provider/model replies, not canned/demo success.
- [ ] Verify messages persist, sessions reopen, errors/timeouts are visible, and unauthorized access is denied.
- [ ] Verify provider keys remain server-side and missing provider configuration fails honestly.
- [ ] Verify rate limits, request validation, timeouts, and safe error responses.
- [ ] Record PASS/FAIL/BLOCKED with redacted logs.

## 2. History, Activity Center and task ownership
- [ ] Verify sessions, messages, archive/restore state, activity entries, notifications, and task history persist after restart/re-login.
- [ ] Verify records are scoped to the authenticated account on every read, write, update, archive, and delete path.
- [ ] Test cross-account ID guessing/IDOR and confirm no data leakage or mutation.
- [ ] Verify there is no fake activity, earnings, task completion, or hardcoded online status.
- [ ] Test database transaction/error handling and migration/restart behavior.

## 3. Google sign-in and device verification
- [ ] Verify allowed origins, client IDs, redirect URIs, token audience/issuer/expiry/signature, state/nonce protections as applicable, and backend session creation.
- [ ] Test sign-in/out, expired/invalid token handling, onboarding, and protected-route redirects.
- [ ] Reproduce and resolve the reported origin_mismatch on the intended web origin.
- [ ] Test real Google sign-in on the Huawei P40 Pro and capture redacted evidence.
- [ ] Do not treat config endpoints or dev login as proof of real Google sign-in.
- [ ] Confirm authentication secrets are never shipped in frontend bundles.

## 4. Voice on real devices
- [ ] Test microphone permission request, denial, revocation, device/browser support, and visible listening/mute state.
- [ ] Test speech-to-text with actual microphone input, not only typed transcript fixtures.
- [ ] Test spoken replies through the actual TTS/browser/device audio path.
- [ ] Test voice commands, interruption/stop, follow-ups/context switching, and failure recovery.
- [ ] Test Nepali speech/replies where supported and document platform limitations.
- [ ] Verify recording/transcript retention, notice/consent, and deletion behavior.
- [ ] Record device/browser/OS, steps, results, and evidence; do not infer device success from CI.

## 5. Safe multi-device hosting plan (no release yet)
- [ ] Choose a staging/private hosting architecture and verify access control before connecting devices.
- [ ] Require HTTPS, authenticated access, restrictive CORS, secure sessions/tokens, and least-privilege service identities.
- [ ] Separate staging and production secrets/data; use managed secret storage or hosting environment variables.
- [ ] Restrict database network access to the application; enable encryption in transit/at rest where supported, backups, retention, restore tests, and least-privilege credentials.
- [ ] Configure health checks, redacted structured logs, monitoring, alerts, resource limits, and rollback.
- [ ] Verify the site is not publicly reachable until the owner approves exposure.
- [ ] No production deployment, public release, or domain cutover without explicit owner approval.

## 6. Security audit and remediation
- [ ] Inventory environment variables and secret consumers; verify .env files and local state are ignored and never served by the web server.
- [ ] Check frontend bundles, source maps, logs, artifacts, config endpoints, and public files for exposed keys/private data.
- [ ] Scan Git history for credentials/sensitive files without reproducing secret values. If exposed, treat credentials as compromised and rotate via an approved plan; deleting a commit alone is insufficient.
- [ ] Audit authentication/authorization on every sensitive API route, including admin/owner/developer routes; enforce server-side role checks and deny by default.
- [ ] Test IDOR/BOLA, privilege escalation, CSRF where relevant, session fixation/replay, CORS, SSRF, path traversal, injection, unsafe file upload, and mass assignment as applicable.
- [ ] Validate/sanitize form and API input with schemas, size limits, allowlists where appropriate, and safe output encoding.
- [ ] Add per-IP/per-account rate limits and abuse controls; do not trust client-supplied identity or forwarded IP headers without trusted proxy configuration.
- [ ] Configure CSP, HSTS once HTTPS is established, X-Content-Type-Options, Referrer-Policy, frame restrictions, and suitable Permissions-Policy without breaking required flows.
- [ ] Ensure production debug/verbose errors are disabled; validate secure defaults and fail-closed configuration.
- [ ] Review password hashing and account recovery. If passwords are stored, use a suitable adaptive hash such as Argon2id or bcrypt with safe parameters; never store plaintext/reversible passwords.
- [ ] Review database permissions, query safety, migrations, backups, retention, encryption, and recovery.
- [ ] Review dependencies for vulnerabilities, stale/unused packages, license constraints, lockfiles, and transitive risks; update and retest in reversible steps.
- [ ] Add/run secret scanning, dependency scanning, static analysis, and security regression tests where available.
- [ ] Review CI permissions, untrusted pull-request execution, artifact retention/content, deployment credentials, branch protection, and workflow pinning.
- [ ] Create a threat model and prioritized risk register; document deferred/accepted risks and owner decisions.

## 7. Legal, privacy and consumer-facing content
- [ ] Inventory each collected data field, purpose, lawful basis/consent where applicable, processor/provider, storage location, retention period, access path, and deletion path.
- [ ] Collect only data necessary for documented product purposes; avoid sensitive data without a clear need and safeguards.
- [ ] Draft a plain-language Privacy Policy covering operator/business identity/contact, data collected, purposes, processors/sharing, international transfers, retention, security, user rights, and complaints.
- [ ] Draft Terms and Conditions covering account use, acceptable use, ownership/licensing, user content, AI limitations, third-party services, termination, lawful liability terms, governing law, and disputes.
- [ ] Draft a Cookie Policy based on actual cookies, local storage, SDKs, and tracking.
- [ ] Inspect analytics, pixels, third-party embeds, fonts, video, OAuth, error reporting, and SDKs; document what runs before/after consent.
- [ ] Determine consent requirements per technology and jurisdiction. If non-essential cookies/tracking require consent, block them until valid opt-in and provide real reject/withdraw controls. Do not add a meaningless banner.
- [ ] Draft a Refund/Cancellation Policy consistent with actual products, payment providers, consumer law, and whether purchases/refunds are enabled.
- [ ] Add specific, unbundled form consent/acknowledgements only where needed; distinguish required processing from optional marketing consent; avoid pre-ticked optional consent.
- [ ] Provide privacy notice at collection and retention/deletion controls where applicable.
- [ ] Verify real operator/business details, contacts, pricing, refund claims, and product/AI claims. Remove fake reviews, fabricated testimonials, unsupported guarantees, and false online/verified indicators.
- [ ] Check image, font, video, music, and other asset licenses/attribution; keep evidence of permissions.
- [ ] Assess applicable Nepal law, including the Privacy Act 2075 and relevant electronic-transactions, consumer-protection, contract, and sector-specific rules. Determine whether other jurisdictions apply based on users/operations. Obtain qualified Nepal legal review before public launch. Do not assume a named DPDP Act applies without verifying the exact law and effective date.
- [ ] Treat policy drafts as pending review; do not claim legal compliance without evidence and qualified advice.

## 8. Accessibility and truthful UX
- [ ] Audit semantic structure, titles/headings, labels, focus order, visible keyboard focus, keyboard-only use, error announcements, and accessible validation.
- [ ] Add meaningful alt text to informative images and empty alt text to decorative images; assess licensing separately.
- [ ] Measure text/UI contrast and fix failures; do not rely on color alone.
- [ ] Use descriptive button/link labels and accessible names for icon-only controls.
- [ ] Test zoom/reflow, responsive layouts, reduced motion, touch targets, and basic screen-reader use.
- [ ] Remove fake reviews, fake counters/earnings, unsupported security/privacy promises, and simulated transaction/verification success.
- [ ] Clearly mark unavailable/unconnected features and prevent misleading success states.

## 9. Release gate — blocked until owner approval
- [ ] Functional checks pass for backend, Chat, persistence, History/Activity/task ownership, Google sign-in, and voice, or blockers are explicitly accepted by the owner.
- [ ] No unresolved critical/high security findings, unless explicitly documented and accepted by the owner.
- [ ] Privacy/terms/cookies/refund content reviewed against real data flows and qualified legal advice where needed.
- [ ] Accessibility and asset-license checks have evidence; known issues are documented.
- [ ] Staging multi-device tests pass; backup restore and rollback are tested.
- [ ] Present final release checklist to the owner. **Do not deploy until explicit approval is received.**

## Compact owner prompt for future implementation sessions

> Work on SAGE ONE in the canonical GitHub repository only. First recover current project state, audit `AI_COLLABORATION.md`, `PROJECT_STATE.md`, `TODO.md`, `coordination/ACTIVE_WORK.yaml`, open PRs, current main SHA, workflows, environment/config code, and existing tests. Finish the approved core product priorities before this deferred website/legal polish queue. Never expose, print, commit, or ask the owner to paste secrets; inspect only masked variable names/presence and verify host settings with the owner. Audit authorization and account/data isolation on every API route, admin/owner/developer paths, production debug/docs, CORS, headers/CSP, request size/input validation, rate limits, abuse/cost limits, session/token expiry, CSRF where relevant, SSRF/path traversal/IDOR, uploads, logs, database migrations/backups/restore, dependency vulnerabilities/licenses, and full Git-history secrets. Rotate any confirmed leaked secret immediately using a safe replacement plan. Add and test accessible Privacy, Terms, Cookie, Refund/Cancellation and form-consent pages only after live data flows, tracking, operator details and applicable Nepal requirements are verified with qualified local counsel. Audit cookies, localStorage, analytics, embeds, third-party requests, data minimization/retention/deletion, image/font/media licenses and truthful claims. Then fix links/footer/buttons/messages/placeholders/navigation, vertical and intentional horizontal scrolling, mobile menu, favicon, titles/meta, copyright year, optimized approved images, clickable logo/phone/email, keyboard/forms/labels/focus/contrast/alt text, and responsive mobile/desktop layouts. Use Playwright and existing cloud CI, capture reproducible evidence, fix only on an isolated feature branch, bound repair attempts, update the durable checklist/memory, and request owner approval. Do not deploy, publish, enable public access, merge risky changes, or claim legal/security compliance without explicit approval and verified evidence. No guarantee of zero vulnerabilities or legal liability is possible; flag unresolved risks and require Nepal legal review before launch.

