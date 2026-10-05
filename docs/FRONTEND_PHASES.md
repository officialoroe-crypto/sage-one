# Flutter Frontend Delivery — 30 Phases

Production frontend: Flutter. Canonical design source: owner-supplied composite SAGE ONE interface board. The source board is a visual reference, not an asset pack; exact artwork must be supplied as original image assets before claiming pixel-perfect reproduction.

## Current status — 2026-10-05

| Phase | Deliverable | Current status |
|---|---|---|
| 01 | Splash / app-entry transition | **Implemented — PR #125 CI green; awaiting review/merge** |
| 02 | Welcome / onboarding | **Implemented — PR #128 CI green; PR #127 is superseded** |
| 03 | Language selection | **Implemented on PR #129 branch; analyzer fix just applied, fresh CI pending** |
| 04 | Login / sign-up | Backend identity contracts exist; no separate Phase 04 implementation yet. feat/flutter-phase-04-auth is currently identical to the Phase 03 branch |
| 05 | KYC verification | Backend abstraction exists; production provider/UI pending |
| 06 | Profile creation | Backend/profile flow exists; dedicated visual pass pending |
| 07 | First-run completion | Pending |
| 08 | Home / Command Center | Functional on main; PR #122 visual v2 is active but its completion-dialog test currently needs fresh CI after a deterministic test fix |
| 09 | Voice listening | Pending |
| 10 | Voice response | Pending |
| 11 | Chat interface | Pending |
| 12 | Research / search | Functional screen exists; visual/product pass pending |
| 13 | Results / artifact reveal | Partial in PR #122; real HTTP/HTTPS artifact opening implemented |
| 14–21 | Apps, Earnings, Marketplace, Jobs, Learning, Community, File Manager, AI Studio | Pending |
| 22 | Spark Wallet | Backend economy foundation exists; visual pass pending |
| 23 | Payment UI | Backend primitives exist; provider readiness + UI pending |
| 24 | Transactions | Backend foundation exists; visual pass pending |
| 25 | User Profile | Pending |
| 26 | Evolution dashboard | Backend-backed Flutter screen exists; visual integration pending |
| 27 | Unified 13-stage Evolution | Design lab + transition engine exist; production integration and visual regression coverage remain |
| 28 | Settings / themes | Pending |
| 29 | Notifications / activity | Notification foundation exists; activity UI pending |
| 30 | Responsive QA / accessibility / errors / Android release | Pending |

## Active PR/branch map

- #122 Command Center v2: active; latest tested head failed only the completion-dialog widget test. Fix committed; fresh CI pending.
- #125 Phase 01 Splash: CI green.
- #128 Phase 02 Onboarding: CI green.
- #129 Phase 03 Language: analyzer failure fixed; fresh CI pending.
- #127 Phase 02: duplicate/superseded by #128.
- #112 Command Center: superseded by newer Command Center work.
- #115 Evolution design lab: remains a valid isolated design input.
- feat/flutter-phase-04-auth currently contains exactly the Phase 03 branch state and is not a distinct Phase 04 implementation.

## What must happen next

1. Get fresh CI green on #122 and #129.
2. Review/merge the verified Phase 01–03 sequence in dependency order.
3. Decide and implement the actual Phase 04 authentication visual flow without breaking private-owner mode.
4. Integrate the 13-stage Evolution design lab + transition engine into production Evolution.
5. Finish the remaining core product surfaces: voice, chat, file operations, integrations, Spark/transactions UI, profile/settings, activity.
6. Perform real-device/manual QA and Android release hardening.
7. Complete external blockers only when moving toward multi-user/public release: SMS provider, long-lived Google session refresh, payment/provider configuration, and multi-tenant ownership.

## Validation rules

- Do not call a phase complete until its success path, failure path, refresh/restart behavior, regression tests, and reference/manual review are covered.
- Use GitHub Actions for heavy validation; keep the development laptop out of the critical test loop.
- Preserve the private-owner entry path while public identity/KYC remains future scope.
- Evolution is progression/achievement; Spark is an internal economic credit. Never conflate them.
