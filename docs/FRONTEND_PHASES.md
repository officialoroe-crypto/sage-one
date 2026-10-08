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
| 09 | Voice listening mode | Implemented — device speech-to-text command capture |
| 10 | Voice response mode | Implemented — device TTS for durable task results |
| 11 | Chat interface | Implemented — persistent session + durable `/command` polling |
| 12 | Research / search interface | Existing research screen; visual pass pending |
| 13 | Results and completed-task artifact reveal | Implemented — task result + project artifact persistence |
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
| 27 | Unified 13-stage Evolution system | Integrate all 13 ranks, canonical rank order/materials, Low/Mid/High intensity states, transition animations, progression evidence and rank identity into the production app; use existing backend catalog and settlement APIs |
| 28 | Settings and themes | Pending |
| 29 | Notifications and activity | Notifications foundation exists; activity visual pass pending |
| 30 | Responsive QA, motion/accessibility, error handling and Android release | Pending |

## Unified Evolution integration

Evolution is now a first-class part of SAGE ONE, not a separate product or isolated deliverable. The 13-stage design lab (PR #115) and transition engine (PR #121) are implementation inputs to the production Evolution experience. Reconcile them into the app in a controlled integration branch; do not leave them permanently disconnected. Spark remains a separate economic balance and must not be conflated with Evolution achievement/progression. Evolution is earned through verified achievement; wallet withdrawal or Spark spending must not reduce lifetime Evolution progress. The production UI should connect Home rank summary, Profile identity, Evolution detail, rank transition/reveal and relevant achievement surfaces. Keep canonical SAGE blue/black identity persistent; rank materials are accent layers, with Low/Mid/High changing intensity/particles only, not taking over the entire UI.

## Automation / validation

- Every PR is validated by GitHub Actions `SAGE CI`: Python regression suite, Flutter analyzer and Flutter widget tests.
- Android release artifacts are built by `.github/workflows/sage-one-android-apk.yml` after main pushes or manual workflow dispatch with a device-reachable API URL.
- Existing local `dev_agent` is a controlled coding loop requiring a checked-out workspace and configured AI provider; it is not a remote unattended 30-phase GitHub executor. Do not run it without a real provider/workspace and explicit scoped claim.
- Existing durable `automation/service.py` schedules user tasks into the backend task engine; it is runtime user automation, not a safe source-code editor.
- GitHub Actions + PRs + coordination claims are the active safe development automation path.

## Rules

- Complete one phase as a reviewable PR or a tightly related small phase batch. Core execution, voice and owner developer-control batches are now merged/validated on main.
- Never mark a phase complete until Flutter CI passes and its screen is manually/reference reviewed.
- Preserve current backend APIs and private-owner path.
- Do not invent missing reference artwork or claim pixel-perfect parity without the actual source assets.
- Integrate the 13-stage Evolution lab and transition engine into the production SAGE ONE app under the unified Evolution scope; do not conflate Evolution with Spark.
