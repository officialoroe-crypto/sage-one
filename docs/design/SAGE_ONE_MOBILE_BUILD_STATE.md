# SAGE ONE — Mobile Design Build State

Last updated: 2026-09-23

## Design source of truth

- Figma file: **SAGE ONE — UI & Workflow**
- Figma file key: `FoZ4PhSqXYTCdF6Jy3jLDQ`
- Figma pages currently reserved by the Starter plan:
  - Cover
  - Foundations
  - Mobile Screens
- Canonical SAGE ONE logo remains owner-controlled and must not be replaced by an approximation.

## V1 mobile structure

Target first-run flow:
Splash → Welcome → Login → OTP → Profile → Onboarding → Memory/Privacy → Workspace

Core app areas:
Home → Chat → Research → Create → Execute → Spark → Memory → Profile

## Visual system

- Foundation: near-black / deep-space background
- Intelligence: cyan + electric blue
- Evolution/recovery: violet
- Economy/Spark: gold
- Success: green
- Failure: red/orange
- Thin luminous borders
- Cinematic depth without turning every surface into a glowing neon card
- SAGE orbital core is the primary system visualization
- Mobile interaction must remain one-handed and task-first

## Current Figma foundation

Token collection: `SAGE Tokens`

Current tokens:
- color/bg/void
- color/bg/surface
- color/border/cyan
- color/intelligence/cyan
- color/intelligence/blue
- color/evolution/violet
- color/economy/gold
- color/state/success
- color/state/failure
- color/text/primary
- color/text/secondary
- spacing/xs, sm, md, lg, xl
- radius/sm, md, lg

Current first screen:
- Name: `SAGE Mobile — Command Center`
- Node ID: `3:35`
- Size: 390×844
- Includes top identity/status, greeting, orbital core, Research/Create/Execute quick actions, and five-item mobile navigation.

## Implementation rule

Figma defines the visual contract. Flutter implements the approved contract. Do not redesign the Flutter screen independently and then try to force Figma to match it.

When the canonical logo asset is available to Figma, replace only the temporary orbital-mark placeholder; do not alter the approved logo artwork.

## Latest build batch

- Figma onboarding frames added: Splash, Welcome, Profile Setup, Memory & Privacy.
- Flutter onboarding implementation now uses the SAGE cinematic theme and preserves the existing identity/OTP/memory-consent contract.
- Added onboarding gate regression tests.
- SAGE WORKFLOW architecture specification added at `docs/architecture/SAGE_WORKFLOW.md`.

## Next synchronized build batch

1. Finish the mobile foundation and reusable visual components.
2. Design the first-run onboarding screens.
3. Redesign the Flutter shell/navigation to match the approved mobile structure.
4. Implement Home/Command Center from the Figma screen.
5. Add Chat, Research, Create, Execute, Spark, Memory and Profile shells.
6. Connect existing backend capabilities to the new UI without changing backend contracts unnecessarily.
7. Add focused Flutter tests and let GitHub Actions perform the heavy validation.
8. Update this document and PROJECT_STATE.md after each coherent batch.
