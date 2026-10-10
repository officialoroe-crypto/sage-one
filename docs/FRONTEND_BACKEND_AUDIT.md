# SAGE ONE Frontend / Backend Audit

Last updated: 2026-10-10

## Audit rules

This is an evidence log, not a claim that the app is end-to-end complete. A screen rendering, a successful build, a static route-contract check, or a route existing in FastAPI does not prove that a live user journey succeeds. Keep automated CI, mocked interaction tests, real-device behavior, and external-provider setup as separate verification categories.

## Latest baseline

- Current main at audit start: `8fde9c3322711b075c210da7af77154cb591c35b`.
- SAGE CI, Android Release, and Developer Website workflow runs for that main commit were successful.
- PR #192 is merged. It fixed memory dialog controller lifetime, stale-session recovery, project/sales dialog controller lifetime, profile loading lifecycle, and AI Studio workspace validation.
- The route-contract test checks recognized Flutter API paths against FastAPI routes. It is a static contract check, not a live-server integration test.
- Follow-up security fix under review: PR #203 requires owner claims before World Intelligence refresh and upgrade-proposal mutations. Its CI result is pending at the time of this update.

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
| Marketplace | Buttons show explicit not-connected explanation | No live marketplace endpoint wired from this screen | Placeholder |
| Jobs | Buttons show explicit not-connected explanation | No live jobs endpoint wired from this screen | Placeholder |
| Learning | Buttons show explicit not-connected explanation | No live learning endpoint wired from this screen | Placeholder |
| Community | Buttons show explicit not-connected explanation | No live community endpoint wired from this screen | Placeholder |
| KYC / Identity Verification | Buttons show explicit not-connected explanation | No provider-backed KYC workflow wired from this screen | Placeholder; provider/legal setup required |
| First Run | Buttons show explicit not-connected explanation | No live setup workflow wired from this screen | Placeholder |

## Confirmed security finding

The main FastAPI app boundary verifies an identity token for protected routes, but identity does not automatically mean owner authority. Before PR #203, World Intelligence mutation handlers passed `owner_authorized=True` to the permission engine without checking the caller's actual `owner_mode` claim. PR #203 adds the owner claim check to refresh and upgrade-proposal creation and adds regression tests. Do not call this fixed until PR CI passes and the change is merged.

## Runtime and device connection requirements

- Flutter Web / Windows desktop default: `http://localhost:8010`.
- Android emulator default: `http://10.0.2.2:8010`.
- Huawei physical-device development APK: `http://127.0.0.1:8010` with the backend running on the PC and `adb reverse tcp:8010 tcp:8010` active. Alternatively, build with a reachable backend URL.
- The current Android artifact is a private development/testing path using local HTTP, not a production-store release. Production requires deployed HTTPS, production auth/configuration, signing, and release compliance.
- GitHub Pages without a public backend URL can only access a backend reachable from the browser's device.

## Known gaps / external dependencies

- Marketplace, Jobs, Learning, Community, Apps, Earnings, KYC and First Run actions are placeholders.
- Payments reports provider status only; no live payment creation/settlement.
- Production SMS/OTP provider and credentials.
- Production Google OAuth/identity configuration and long-lived session UX.
- Full multi-tenant isolation if SAGE becomes a shared public service.
- Broader third-party integrations, permissioned publishing, analytics feedback, and production monitoring/backups.
- Physical Huawei test of owner login, backend connectivity, microphone permission/STT, TTS, app restart/session restore, and task execution.
- Full button-by-button success/error/cancel coverage and visual/reference regression remain in progress.

## Next verification order

1. Finish CI for PR #203 and merge only if required checks pass.
2. Add/complete action-level tests for each live screen action: assert HTTP method/path, payload, success state, error state, loading state, and cancellation behavior.
3. Keep placeholder actions explicitly labelled as not connected until their real backend/provider exists.
4. Re-run the screen-to-route contract test and compare every API method against its FastAPI route and response shape.
5. Build the APK from the exact merged `main` commit using the intended Huawei ADB reverse configuration.
6. Install that exact artifact on the Huawei phone and verify login, chat/task execution, memory, notifications, project actions, and voice on-device.
7. Only after these checks pass, claim the private demo is end-to-end ready.
