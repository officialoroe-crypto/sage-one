# SAGE ONE — 13 Evolution System Design Lab

**Status:** Independent design workbench. Not integrated into the SAGE ONE application.
**Source of truth:** `docs/design/LOCKED_EVOLUTION_REFERENCE.md` and the original user-approved image stored unchanged in the owner's ChatGPT Library.

## Purpose
Develop the 13-stage Evolution experience as a self-contained design package while the owner continues designing the main app frontend. This folder must remain isolated from production app code.

## Non-negotiable principles
- Preserve the exact 13 stage names and order.
- Low / Mid / High are intensity states within a stage, never additional ranks.
- Skill/achievement progression defines Evolution; money progression is a separate path.
- Spark is platform economy credit, not Evolution and not a substitute for achievement.
- Evolution is lifetime achievement; withdrawing money never reduces it.
- Permanent SAGE identity is blue/black. Stage material is an accent layer, not a full-screen recolor.
- Keep the original image's logo, Buddha, mountain/Everest, moon, sky, settlement, coin motifs, typography, composition and relative placement as the visual benchmark.
- Never invent final hex palette values. The reference explicitly calls the palette conceptual and not finalized.
- Do not change the separately approved Home orb instruction.

## Workbench contents
- [Stage system](STAGES.md): exact stage order, material direction and three intensity states.
- [Progression model](PROGRESSION.md): skill path vs money path, achievements and lifetime rule.
- [Motion storyboard](MOTION.md): nine-step rank transition and motion principles.
- [Composition and assets](COMPOSITION_ASSETS.md): layout regions and required source assets.
- [Review checklist](REVIEW_CHECKLIST.md): fidelity, content, motion and handoff checks.
- [39-state matrix](STATE_MATRIX.md): Low / Mid / High visual direction for every stage.
- [Board layout](BOARD_LAYOUT.md): reference composition and reading order.
- [Visual token register](VISUAL_TOKEN_REGISTER.md): semantic roles; no invented final hex values.
- [Delivery plan](DELIVERY_PLAN.md): independent design work sequence and review package.
- [Individual stage sheets](STAGE_SHEETS.md): index for thirteen stage-specific art-direction briefs.
- [Transition keyframes](TRANSITION_KEYFRAMES.md): nine-beat storyboard with entry/exit visual checks.

## Isolation rule
This package is design documentation only. Do not import it into Flutter/React, change app navigation, add APIs, or alter backend economy logic. Any future app integration requires a separate explicit user decision and a separate work claim.
