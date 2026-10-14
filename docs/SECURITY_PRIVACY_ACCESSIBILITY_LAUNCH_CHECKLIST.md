# SAGE ONE — Functional, Security, Privacy, Accessibility & Launch Readiness

**Status:** Worklist recorded; checklist items are not claims of implementation or verification.
**Owner rule:** Do not deploy, publish, enable public access, or release the app/site until the owner explicitly approves. Private/staging test environments only.
**Evidence rule:** Mark each item separately as Specified, Implemented, Connected, Tested, Verified, or Blocked. A green build is not runtime proof. Never record PASS without repeatable evidence.

## 0. Safety and working rules
- [ ] Preserve existing user changes and data; inspect before modifying.
- [ ] Never print, commit, or expose secret values. Report secret names and locations only, with values redacted.
- [ ] Do not rotate/revoke credentials without checking dependencies and preparing a safe replacement plan.
- [ ] Do not deploy or make public DNS/hosting changes without explicit owner approval.
- [ ] Create a private/staging test path for multiple devices with authentication; do not use production data for tests.
- [ ] Record test scope, environment, date, result, evidence, and remaining uncertainty.

## 1. Backend, live smoke test, Chat and persistence
- [ ] Find why the live-backend smoke-test job was skipped; distinguish workflow conditions from backend health.
- [ ] Run safe, read-only health/config smoke tests against the intended test environment.
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
