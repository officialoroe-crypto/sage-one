# SAGE ONE — Exact UI Replication & Implementation Brief

## Goal
Bring the existing React + Vite prototype as close as possible to the supplied SAGE ONE master UI blueprint. Treat the reference image as the visual source of truth. Preserve existing code, components, navigation, and work. Do not rebuild from scratch or migrate to Flutter unless the owner explicitly asks.

## Source assets
- Master blueprint: `src/imports/ChatGPT_Image_Sep_29__2026__10_58_14_AM__2_.png` (also duplicated at `src/assets/reference.png`). Inspect it before coding.
- Logo: use the owner's original SAGE orbit-S logo asset. Do not redraw with text, emoji, or generic S. If the exact asset is missing, ask for it instead of approximating.
- Background: use the exact mountain/city/night-sky artwork or a faithful source asset. Do not substitute generic gradients or stock art.

## Visual requirements
1. Match dark navy/black cosmic palette, cyan/blue neon edges, restrained purple accents, subtle stars, mountain/city skyline, typography, spacing, proportions, card borders, and glow intensity.
2. Match the logo's S silhouette, orbital ring, orbiting coin/dot, color, glow, and wordmark lockup using the real asset.
3. Create reusable tokens/components for colors, fonts, cards, buttons, chips, progress bars, navigation, logo, status bar, and background.
4. Make the UI responsive and accessible; avoid clipping at phone dimensions. Don't treat a static phone frame as a responsive product.
5. Use designed icons/assets rather than emoji placeholders where the blueprint uses custom iconography.
6. Implement only intended animations; keep them smooth and lightweight.

## Blueprint screens
Splash; welcome/onboarding; sign-up/login; identity/KYC; Home; voice listening and response; task completion; Apps Hub; Marketplace; Jobs; Learning; Community; File Manager; AI Studio; Evolution; Spark/economy; navigation/settings; user journey. Use existing components wherever possible and ensure each screen is reachable.

## Evolution
Owner's wider direction calls for 13 distinct evolution themes/levels. Current `src/screens/EvolutionScreen.tsx` defines 10 rank entries. Do not invent missing names, thresholds, perks, or order. Extract confirmed details from the blueprint and project docs; list unclear details in `IMPLEMENTATION_GAPS.md`. Use one data-driven shared theme engine/config, not 13 duplicated screens. Themes can define palette, background, particles/stars, glow, emblem, transition, and card treatment.

## Functionality and safety
- Keep React + TypeScript + Vite unless a concrete blocker is found.
- Separate UI from data/services. Treat balances, jobs, listings, rank, and activity as demo data until backed by real API responses.
- Inspect the existing SAGE backend/API contract before integration. Use an environment variable for API base URL; add only placeholder values to `.env.example`. Never commit secrets.
- Don't fake success for login, KYC, payments, voice, or AI generation.
- Voice UI should represent listening/speaking, waveform, stop/interruption, and text fallback; connect only to real supported services.
- Do not implement real payments or financial claims without explicit requirements and a reviewed provider integration.

## Workflow
1. Inspect project and reference; report existing vs missing pieces.
2. Map each blueprint area to existing components and maintain a checklist.
3. Implement in phases: (A) exact logo/background/type/tokens; (B) Splash/Onboarding/Auth; (C) Home/navigation; (D) voice/chat; (E) feature screens; (F) Evolution/Spark; (G) responsive/accessibility polish.
4. Work on a feature branch. Never push to main, auto-merge, delete files, or change backend contracts without approval.
5. Run supported build/typecheck/tests after each phase and report exact commands/results honestly.
6. Compare screenshots at matching viewport size; correct logo, background, typography, alignment, spacing, color, and assets.
7. Keep `IMPLEMENTATION_GAPS.md` updated with done, remaining, missing assets, assumptions, and next step.

## Done means
- Original logo and exact background artwork, not approximations.
- All blueprint screens exist and are navigable.
- Phone layout closely matches the master image.
- 13 evolution themes follow confirmed source details; unknowns are flagged, not fabricated.
- API-backed features use verified endpoints or are clearly marked unconnected.
- Checks are reported truthfully and changes remain in a reviewable branch/PR.

## Owner preference
Keep instructions beginner-friendly and concise. Explain what changed, what remains, and one next action. Preserve existing work and ask before destructive/high-impact changes.
