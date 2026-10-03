# Flutter Frontend Delivery — 30 Phases

Production frontend: Flutter. Canonical design source: owner-supplied composite SAGE ONE interface board. The source board is a visual reference, not an asset pack; exact Buddha/Everest/moon/logo artwork must be supplied as original image assets before claiming pixel-perfect reproduction.

## Delivery phases

| Phase | Deliverable | Status |
|---|---|---|
| 01 | Splash screen and app-entry transition | In progress — PR #125 |
| 02 | Welcome / onboarding introduction | Planned |
| 03 | Language selection | Planned |
| 04 | Login / sign-up | Existing backend identity contracts; visual pass pending |
| 05 | KYC verification | Backend abstraction exists; production provider/UI integration pending |
| 06 | Profile creation | Existing onboarding profile flow; visual pass pending |
| 07 | Welcome to SAGE ONE / first-run completion | Planned |
| 08 | Home / Command Center | Existing functional screen; visual redesign in PR #122, overlaps PR #112 |
| 09 | Voice listening mode | Pending |
| 10 | Voice response mode | Pending |
| 11 | Chat interface | Pending |
| 12 | Research / search interface | Existing research screen; visual pass pending |
| 13 | Results and completed-task artifact reveal | Partial implementation in PR #122; CI repair in progress |
| 14 | Apps Hub | Pending |
| 15 | Earnings interface | Pending |
| 16 | Marketplace | Pending |
| 17 | Jobs | Pending |
| 18 | Learning | Pending |
| 19 | Community | Pending |
| 20 | File Manager | Pending |
| 21 | AI Studio | Pending |
| 22 | Spark Wallet | Existing economy foundation; visual pass pending |
| 23 | Payment integration UI | Existing backend/payment primitives require provider readiness and visual pass |
| 24 | Transactions and fee history | Partial economy foundation; visual pass pending |
| 25 | User Profile | Pending |
| 26 | Evolution dashboard | Existing backend-backed Flutter screen; visual pass pending |
| 27 | 13 Evolution ranks and Low/Mid/High intensity | Separate design lab/transition PRs; not integrated until owner approval |
| 28 | Settings and themes | Pending |
| 29 | Notifications and activity | Notifications foundation exists; activity visual pass pending |
| 30 | Responsive QA, motion/accessibility, error handling and Android release | Pending |

## Automation / validation

- Every PR is validated by GitHub Actions `SAGE CI`: Python regression suite, Flutter analyzer and Flutter widget tests.
- Android release artifacts are built by `.github/workflows/sage-one-android-apk.yml` after main pushes or manual workflow dispatch with a device-reachable API URL.
- Existing local `dev_agent` is a controlled coding loop requiring a checked-out workspace and configured AI provider; it is not a remote unattended 30-phase GitHub executor. Do not run it without a real provider/workspace and explicit scoped claim.
- Existing durable `automation/service.py` schedules user tasks into the backend task engine; it is runtime user automation, not a safe source-code editor.
- GitHub Actions + PRs + coordination claims are the active safe development automation path.

## Rules

- Complete one phase as a reviewable PR or a tightly related small phase batch.
- Never mark a phase complete until Flutter CI passes and its screen is manually/reference reviewed.
- Preserve current backend APIs and private-owner path.
- Do not invent missing reference artwork or claim pixel-perfect parity without the actual source assets.
- Keep the 13-stage Evolution lab separate until explicitly approved for app integration.
