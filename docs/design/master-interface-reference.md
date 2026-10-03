# SAGE ONE — Master Interface Reference

**Status:** Owner-provided visual reference; design baseline  
**Source image:** `Untitled front.jpg` (owner attachment in the 2026-10-02 project conversation)  
**Image dimensions:** 2048 × 1194 px  
**Implementation target:** Existing Flutter application  
**Scope:** Entire product UI, from first launch and authentication through the core experience, app hub, Spark economy and Evolution.

> This document records the attached composite board as the source of truth for the next frontend design pass. Do not replace it with an independently invented visual direction. The source JPEG is retained as the conversation attachment; it has not yet been added as a binary Git object to this branch.

## 1. Overall visual language

- Dark navy / near-black base with deep blue cosmic lighting.
- Fine cyan-blue strokes, restrained luminous edges and rounded glass-like panels.
- White and pale-blue typography with cyan highlights.
- Consistent SAGE logo, wordmark and visual identity across every screen.
- Cinematic mountain / moon / Buddha hero artwork where shown in the reference; preserve the artwork composition and do not substitute generic stock imagery.
- Evolution material colours are accent layers. They must not recolour the entire product UI.
- Layouts are dense but structured: clear section headings, aligned cards, predictable spacing and strong contrast.

## 2. Screen families visible on the master board

### Entry and identity
1. Splash and onboarding
2. Language selection
3. Login / sign-up
4. KYC verification
5. Profile creation
6. Welcome to SAGE ONE

### Core experience
7. Main Home / Command Center
8. Chat interface
9. Search / research mode
10. Results and action suggestions
11. SAGE Apps hub

### Mini-apps
12. Earnings system
13. Marketplace
14. Jobs
15. Learning
16. Community
17. File Manager
18. AI Studio

### Wallet and personal identity
19. Spark currency system
20. Payment integration
21. Spark & money system
22. User profile / identity
23. Evolution dashboard
24. Transaction and fee information
25. Dark mode / theme selection
26. UI elements and reusable components

### Evolution presentation
27. The 13 Evolution ranks
28. Three intensity states: Low / Mid / High
29. Bronze Low → Mid → High progression example
30. Evolution transition storyboard
31. Permanent SAGE identity vs Evolution material accents
32. Animation and motion guidance

## 3. Evolution rules shown on the board

- There are 13 named Evolution stages: Bronze, Silver, Gold, Platinum, Jade, Ruby, Sapphire, Emerald, Diamond Sovereign, Black Opal Realm, Painite Core, Void Matter and Californium Overlord.
- Each stage has Low, Mid and High intensity states. These are visual intensities within the same stage, not additional ranks.
- Evolution is a lifetime achievement; withdrawing Spark does not reduce it.
- Spark and Evolution are separate systems. Spark is the platform economy; Evolution represents earned skill / achievement progression.
- Money can support progression and unlock system capability, but skill and achievement define visual Evolution.
- Keep the SAGE blue/black identity permanent. Evolving changes the material/accent layer, particles and glow—not the whole interface.
- Exact final 13-stage accent palette is not locked by the source board; use its colours as visual direction until the owner confirms the palette.

## 4. Animation principles

- Use cinematic but controlled motion; avoid constant distracting movement on every component.
- The main SAGE orb may continuously glow, but must remain a clean sphere: no decorative rings, orbit paths, outlines or objects placed around it unless the owner later changes this rule.
- State transitions should have clear timing and visual hierarchy.
- Evolution transition reference sequence: particles accelerate; energy concentrates; screen darkens; a shockwave / burst occurs; old material breaks; new material forms; new particles appear; new rank crystallizes; interface settles.
- Provide reduced-motion behaviour and avoid animation that blocks input or accessibility.

## 5. Implementation principles

- Flutter remains the production frontend framework.
- Preserve existing API clients, task submission, polling, authentication and backend contracts. Do not replace real functionality with mock data.
- Build shared design tokens and reusable widgets before duplicating styles across screens.
- Implement screen families in small reviewable batches. Keep the 13-stage Evolution visual lab separate from production integration until the owner approves it.
- Do not infer or invent payment provider capabilities, KYC rules, file-open permissions or wallet operations; reflect the backend contracts that actually exist.
- Keep all screen layouts responsive to phone sizes; the composite board is a visual map, not a literal single-screen layout.

## 6. Suggested implementation sequence

1. Audit existing Flutter screens and map each one to the relevant panel in the master board.
2. Establish design tokens, typography, background treatment, cards, buttons, fields, navigation and logo usage.
3. Finish the Home / Command Center and voice / chat states.
4. Implement authentication, onboarding, KYC and profile creation.
5. Build the Apps hub and mini-app shells, then connect existing backend features.
6. Implement Spark wallet and transaction surfaces against verified backend APIs.
7. Build Evolution screens and animations in the separate lab, then integrate after visual approval.
8. Run analyzer, widget tests and visual regression checks at phone breakpoints.

## 7. Owner review checkpoints

- Approve the extracted screen inventory before implementing all screens.
- Review the shared design system before broad screen conversion.
- Review each batch against the source image; do not silently change layout, logo, hero art, iconography or colour treatment.
- Treat ambiguous tiny text in the composite as unreadable rather than guessing product rules. Ask the owner only when a detail changes behaviour or layout materially.
