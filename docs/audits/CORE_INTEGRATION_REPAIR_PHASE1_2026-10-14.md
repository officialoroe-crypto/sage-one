# SAGE ONE Core Integration Repair — Phase 1
Date: 2026-10-14
Status: Active implementation plan; no production release authorized.

## Non-negotiable release boundary
- Do not publish the Flutter web app or Android APK as a release.
- Do not trigger a public website deployment while product repairs are underway.
- CI builds and QA artifacts are allowed; they are not releases.
- Never report authentication, KYC, voice, payments, or task execution as working without evidence from the actual connected service.
- Preserve the existing FastAPI backend, Flutter app, owner-only Developer Mode, and user changes. Prefer repair and integration over architectural rewrites.

## Confirmed repository findings
- The Flutter app already contains VoiceCommandScreen using speech_to_text and flutter_tts; it submits through SageApi.submitCommand and polls the task API. The screen is linked from the More menu and command-center entry point. First verify reachability and runtime behavior rather than create a second unrelated voice implementation.
- frontend/lib/screens/command_center.dart already has a visible voice command button and an orbiting SAGE orb. Device/browser QA must determine why the user cannot access or use it in their current build.
- Flutter dependencies already include google_sign_in, speech_to_text, and flutter_tts.
- identity/api.py already exposes Google identity configuration/login, phone OTP send/verify, and onboarding endpoints. SMS delivery reports not_configured when no SMS provider is configured; do not fake a successful OTP.
- frontend/lib/screens/final_surfaces.dart includes Spark wallet and transaction views connected to /economy/me. Actual monetary operations and provider-backed payments still require an audit of each action and the backend ledger.
- website/index.html is the public marketing landing page and references root-level website/styles.css, website/favicon.svg, and website/app.js. It is not the authenticated workspace.
- website/js/app.js and website/js/backend.js are a separate older workspace prototype. backend.js says only identity, chat, and explicitly queued tasks are live; many other screens remain prototype-level. Simulated auth/KYC/payment handlers must not be presented as real verification or transactions.
- .github/workflows/sage-one-god-mode-pages.yml has had path assumptions that do not match the actual public landing page. Validate the actual entry point and assets before any future deployment.

## Fast implementation batches

### Batch 1 — Stop releases and establish truth
- Keep public Pages deployment disabled while repair work is underway.
- Keep Flutter web builds as private, short-retention QA artifacts only.
- Correct website validation to inspect files actually referenced by website/index.html.
- Maintain a feature inventory with evidence, owner, status, dependencies, and acceptance tests.

### Batch 2 — Voice-first user verification
- Put a clear voice command entry point on the primary command screen.
- Show explicit states: microphone permission, ready, listening, transcript captured, sending, working, completed, failed.
- Show exactly what SAGE heard before sending; do not auto-execute a potentially consequential command without user confirmation.
- Ensure commands use the existing authenticated API/task pipeline and display the real task ID/status/result.
- Fix Nepali/English speech locale selection and speech output language; never claim to be listening when the OS/browser has not granted microphone access.
- Add tests for permission denial, unsupported speech engine, empty transcript, send failure, task completion, and task failure.

### Batch 3 — Identity and verification
- Verify Google sign-in configuration separately for web and Android, including client ID, token audience/issuer validation, owner gating, and backend session behavior.
- Audit phone OTP delivery provider and configuration. If unavailable, display a truthful SMS provider not configured status.
- Decide KYC provider and compliance requirements before implementing document/face verification. Until then, provide a clear not configured state, secure upload design, consent, status and audit trail—not a fake verified badge.
- Add integration tests for invalid tokens, non-owner accounts, expired OTP, and incomplete onboarding.

### Batch 4 — Backend wiring and dead-button audit
- Enumerate every Flutter and website control; classify as connected, broken, prototype-only, disabled, or missing.
- For each live action, trace UI → API client → FastAPI route → service/database/worker → displayed result.
- Make errors visible and retryable; remove fabricated success states and fake default balances.
- Preserve authentication and owner-only authorization. Never place secrets in frontend bundles.

### Batch 5 — Economy and payments
- Treat Spark as an internal ledger credit, distinct from real currency and payment processing.
- Audit balance reads, rewards, debits, duplicate requests, transaction history and owner-only controls.
- Make ledger writes server-side and idempotent; test concurrency and unauthorized access.
- Connect external payment processing only after provider, credentials, webhook verification, refunds and failure states are defined. Keep unavailable providers clearly marked as not configured.

### Batch 6 — Animation, design, and end-to-end QA
- Align the S mark, blue sphere, orbital ring/coin, and cinematic purple/sky-blue accents with the agreed design.
- Tie motion to real voice/task states rather than decorative false ready indicators.
- Test responsive layouts, keyboard controls, accessibility, reduced motion, and every visible button/link.
- Run Python tests, Flutter analyze/tests, JavaScript syntax checks, API integration tests, then manual Android/browser checks.
- Do not release until critical issues are closed and the owner explicitly requests a release.

## Acceptance gate
A feature is only done when code is reviewed, relevant automated tests pass, the connected service is configured, failure states are tested, and the real app/browser/device behavior is confirmed. A green build alone does not prove that Google sign-in, SMS, KYC, microphone, or payments work end to end.
