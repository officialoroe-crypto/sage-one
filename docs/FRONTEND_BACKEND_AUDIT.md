# SAGE ONE Frontend / Backend Audit

Last updated: 2026-10-10 (website-first QA checkpoint)

## Audit rules

This is an evidence log, not a claim that the app is end-to-end complete. A screen rendering, a successful build, a static route-contract check, or a route existing in FastAPI does not prove that a live user journey succeeds. Keep automated CI, mocked interaction tests, real-device behavior, and external-provider setup as separate verification categories.

## Latest baseline

- Current main baseline before this corrective PR: `2b0872b6da04db35c83872cf9adfd3857537aa57`.
- PR #201 merged as `ad769fdc66ed55d098019bdb38634550abbf2f2e`; the latest PR-head SAGE CI and Android Release passed. Artifact `11664548324` was uploaded by [run 38036670372](https://github.com/officialoroe-crypto/sage-one/actions/runs/38036670372).
- PR #202 More-menu fix merged as `876168e7d85c5e035e31c23523d2e18baa06a16a`; SAGE CI and Android Release passed.
- PR #218 marketing-site work merged as `3d951d2c7ffb3ed1d1ec70edb64c09d29432f4b4`. [Pages run 38058717863](https://github.com/officialoroe-crypto/sage-one/actions/runs/38058717863) successfully deployed a combined marketing-page + Flutter-web artifact (`11671519061`). This deployed the app before web/mobile QA was complete and is being corrected.
- Current main SAGE CI [run 38058766698](https://github.com/officialoroe-crypto/sage-one/actions/runs/38058766698) passed; Android Release [run 38058766769](https://github.com/officialoroe-crypto/sage-one/actions/runs/38058766769) was still running at the last check.
- The route-contract test checks recognized Flutter API paths against FastAPI routes. It is a static contract check, not a live-server integration test.

## Screen-to-backend map

| Screen / entry | Frontend behavior and API methods | Backend route family | Audit status |
|---|---|---|---|
| Splash / app shell | Startup transition; bottom navigation; More menu | No direct API from splash; shell polls notifications | Navigation paths identified; full tap-by-tap test still open |
| Login / Auth Gate / Private Owner Gate | Restore token, sign in, clear stale session, select private owner path | `/identity/config`, `/identity/dev-login`, `/identity/google`, `/identity/me` | Widget tests exist for login and stale-session fallback; Huawei run still required |
| Onboarding | Profile setup, capabilities, OTP UI | `/identity/onboarding/options`, `/identity/onboarding`, `/identity/phone/send`, `/identity/phone/verify` | Backend calls exist; real OTP provider delivery requires external setup |
| Language Selection | Local language selection UI | No direct backend call identified | Persist/restore behavior needs interaction review |
| Command Center | Worker health, submit background task, poll task status | `/worker/health`, `/execute/background`, `/tasks/{task_id}` | API wiring identified; live worker path needs end-to-end test |
| Agent | Submit background task and poll status | `/execute/background`, `/tasks/{task_id}` | API wiring identified; live worker path needs end-to-end test |
| Voice Command | Submit spoken command and poll task | `/command`, `/tasks/{task_id}` | Mock tests exist; physical microphone/speech test pending |
| Voice Mode | Submit background work and poll task | `/execute/background`, `/tasks/{task_id}` | Mock tests exist; physical microphone/STT/TTS test pending |
| Research | Start research, retrieve history/result, inspect task, cancel | `/tools/execute` (research tools), `/execute/background`, `/tasks/{task_id}`, `/tasks/{task_id}/cancel` | Widget coverage exists; source/provider-backed live research not yet device-verified |
| Tasks | List, refresh/poll, cancel tasks | `/tasks`, `/tasks/{task_id}`, `/tasks/{task_id}/cancel` | Widget coverage exists; live worker execution still needs testing |
| Create | Create workspace, project, workflow | `/workflow/workspaces`, `/workflow/workspaces/{id}/projects`, `/workflow/projects/{id}/workflows` | Mock API tests exist |
| Projects | List workspaces/projects and open project detail | `/workflow/workspaces`, `/workflow/workspaces/{id}/projects` | Mock API tests exist |
| Project Detail | Commands, assets, relations, workflow definitions | `/command`, `/workflow/projects/{id}/assets`, `/workflow/projects/{id}/relations`, `/workflow/projects/{id}/workflows` | Mock API tests exist; each action still needs success/error/cancel coverage review |
| Memory | List, review, add, confirm/update, delete memories | `/identity/memory`, `/identity/memory/review`, `/identity/memory/{id}` | Memory review and dialog regression tests exist |
| Owner Console | Owner status/audit and Spark/evolution controls | `/economy/owner/status`, `/economy/owner/audit`, `/economy/owner/spark/*`, `/economy/owner/evolution/*` | Owner-gated backend routes and tests exist; UI error-path coverage needs review |
| Economy | Wallet and premium-work cost reads | `/economy/me`, `/economy/costs` | Mock screen coverage exists |
| Evolution | Wallet/evolution tiers and progress | `/economy/me`, `/economy/evolution/tiers` | Mock screen coverage exists |
| World Intelligence | Status, knowledge, due topics, refresh | `/world/status`, `/world/knowledge`, `/world/due`, `/world/refresh` | Mock coverage exists; mutation owner-check fix is in PR #203 |
| Sales | Leads, lead detail/history, approve outreach, convert, follow-up | `/sales/leads`, `/sales/leads/{id}`, `/sales/leads/{id}/history`, `/sales/leads/{id}/approve-outreach`, `/sales/leads/{id}/convert-customer`, `/sales/leads/{id}/follow-up` | Mock screen coverage exists; live provider/outreach behavior needs validation |
| Spark Wallet | Read balance and ledger | `/economy/me` | Connected read-only surface; no claim of external monetary value |
| Transactions | Display Spark ledger entries | `/economy/me` | Connected to internal ledger data; not a full external payment transaction history |
| Profile | Load and save profile | `/identity/me` GET/PATCH | Form-validation and failure-path regression coverage should be confirmed in CI |
| Settings | Read/update supported profile preferences | `/identity/me` GET/PATCH | API wiring exists; each setting's persistence must be verified |
| Notifications | List, mark one read, mark all read | `/notifications`, `/notifications/{id}/read`, `/notifications/read-all` | Regression tests exist |
| Payments | Read provider status only | `/economy/payment/status` | Intentionally no payment-creation action until a real provider is configured |
| File Manager | Read tasks and display available task artifacts | `/tasks` | Artifact listing is connected; richer file browse/export actions are not established by this screen |
| AI Studio | List/create workflow workspaces | `/workflow/workspaces` | Workspace creation is connected; broader prompt/agent-template features remain incomplete |
| Apps | Buttons show explicit not-connected explanation | No live integration endpoint | Placeholder, truthfully labelled |
| Earnings | Buttons show explicit not-connected explanation | No live earnings endpoint wired from this screen | Placeholder |
| Marketplace | Browse/search listings, publish listing, inquire, view seller inquiries, close own listing | `/marketplace/listings`, `/marketplace/listings/mine`, `/marketplace/listings/{id}/inquiries`, `/marketplace/inquiries/mine` | Backend-backed MVP merged via PR #210; add live web smoke tests, authorization/ownership and duplicate-inquiry checks. Checkout/payment settlement remains unconnected |
| Jobs | Browse/search jobs, publish a job, apply, view own postings/applications and close a posting | `/jobs`, `/jobs/mine`, `/jobs/applications/mine`, `/jobs/{id}/applications` | Backend-backed MVP merged via PR #210; add live web smoke tests, authorization/ownership and duplicate-application checks |
| Learning | Browse learning paths and save completed lesson progress | Learning-path and lesson-progress API methods in `SageApi` | Backend-backed learning MVP merged via PR #213; verify web persistence, error recovery and lesson-completion behavior against the live backend |
| Community | Buttons show explicit not-connected explanation | No live community endpoint wired from this screen | Placeholder |
| KYC / Identity Verification | Buttons show explicit not-connected explanation | No provider-backed KYC workflow wired from this screen | Placeholder; provider/legal setup required |
| First Run | Buttons show explicit not-connected explanation | No live setup workflow wired from this screen | Placeholder |

## High-priority frontend remediation (PR #201 — merged)

The merged fix adds retry/error-clearing UI for Spark Wallet, Transactions, Evolution, Notifications, Payments, File Manager, and AI Studio; validation and retained input for project commands, workflow assets, and sales follow-ups; Chat session/history/command recovery with a five-consecutive-failure cap on automatic task-status polling; and exception handling when opening artifact URLs.

The pre-merge PR checks passed: SAGE CI ran 218 Python tests, Flutter analysis, and 61 Flutter tests; Android Release passed analysis, tests, API URL validation, APK build, App Bundle build, and artifact upload. The latest main commit `ff646d0a0767ef927d77598ed7b13abb8f818068` has fresh passing SAGE CI and Android Release runs; its artifact is `11664978073`. These automated checks do not replace physical-device or provider verification.

## Confirmed security fix

World Intelligence refresh and global upgrade-proposal creation now require the authenticated caller's `owner_mode` claim. PR #203 added these checks and regression tests asserting that non-owner claims receive HTTP 403; the owner refresh test is preserved. PR #203 is merged, and its SAGE CI and Android Release runs passed. This is an authorization boundary; it should not be weakened by bypassing the claims check inside the permission engine.

## Runtime and device connection requirements

- Flutter Web / Windows desktop default: `http://localhost:8010`.
- Android emulator default: `http://10.0.2.2:8010`.
- Huawei physical-device development APK: `http://127.0.0.1:8010` with the backend running on the PC and `adb reverse tcp:8010 tcp:8010` active. Alternatively, build with a reachable backend URL.
- The current Android artifact is a private development/testing path using local HTTP, not a production-store release. Production requires deployed HTTPS, production auth/configuration, signing, and release compliance.
- GitHub Pages without a public backend URL can only access a backend reachable from the browser's device.

## Known gaps / external dependencies

- Community, Apps, Earnings, KYC and First Run still expose placeholder actions. Jobs, Marketplace and Learning now have backend-backed MVP screens merged into main; live-browser/backend verification and edge-case regression remain required. Payment checkout/settlement is intentionally not connected.
- Payments reports provider status only; no live payment creation/settlement.
- Production SMS/OTP provider and credentials.
- Production Google OAuth/identity configuration and long-lived session UX.
- Full multi-tenant isolation if SAGE becomes a shared public service.
- Broader third-party integrations, permissioned publishing, analytics feedback, and production monitoring/backups.
- Physical Huawei test of owner login, backend connectivity, microphone permission/STT, TTS, app restart/session restore, and task execution.
- Full button-by-button success/error/cancel coverage and visual/reference regression remain in progress.

## Next verification order — website first, then mobile

1. Merge the release-boundary correction only after SAGE CI and public-site workflow validation pass. Run the manual Pages workflow to replace the combined public artifact with the marketing site only; verify the `/app/` route is no longer published.
2. Run the Flutter web app locally against the actual backend. First resolve the known port discrepancy: Flutter web defaults to `http://localhost:8010`, while an earlier owner checkpoint showed the backend responding on port `8000`. Inspect the server command and provide a matching explicit `SAGE_API_URL` to both API and identity clients.
3. Browser test onboarding with phone blank (PR #214's fix), auth/developer-mode routing, primary navigation, Chat/session/task lifecycle, profile/memory, Jobs, Marketplace, Learning, settings, notifications and form-validation errors. Record each case as pass/fail with console/network evidence.
4. Check real backend persistence, response shapes and cross-user ownership boundaries for Jobs/Marketplace/Learning; the current CI mocks and static route-contract checks don't prove a live request succeeds.
5. After website bugs are fixed, test Android using a new GitHub Actions artifact from the verified main commit. Verify backend reachability, sign-in, Chat/task execution, memory, notifications and project actions before voice/STT/TTS.
6. Run the Huawei device checks only after web QA passes; use the known authorized ADB executable path and verify the intended port mapping rather than copying example output into the terminal.
7. Only after web + mobile verification and external-provider checks pass should an authenticated app build be intentionally released publicly.

