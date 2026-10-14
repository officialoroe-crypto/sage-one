# SAGE ONE — Project Memory / Canonical Source of Truth

GitHub is the durable shared project memory. Chat history is supplementary. Read [Start Here](00_START_HERE.md) and [Master Rules & To-Do](SAGE_MASTER_RULES_AND_TODO.md) before major work.

## Current engineering priorities — LOCKED ORDER
1. **P0: clean the whole repository** — audit tracked files, source, assets, data/config, workflows and docs; identify stale/duplicate/conflicting residuals; trace references; consolidate operational rules and TODO; archive/delete only with evidence; run checks.
2. **P1: build the self-repair system** — audit existing Developer Mode and CI first, then create a safe detect → diagnose → propose → test → preview → owner approve → apply → verify loop.
3. After P0/P1 gates: connect and verify live web intelligence + message assistance through the real Chat path, reusing the existing research/web-reader modules.
4. Only then resume broader end-to-end UI/backend QA, device/release hardening and other deferred product features based on evidence.

Do not reorder priorities to implement attractive new features while cleanup or self-repair remains the active blocker.

## Product vision
SAGE ONE is the owner's personal AI mentor and execution platform, not a chatbot demo. It should eventually support research, content creation, video workflows, marketing, business discovery, portfolio generation, and permissioned creator/business tasks.

## Role boundary
- Backend engineering builds APIs, data models, authentication, permissions, ledgers, orchestration, workers, integrations, CI and security.
- Frontend engineering builds screens, navigation, UX, visual design, animations, responsive behavior and frontend QA.
- Integration work verifies real end-to-end behavior.
- When a feature is requested, determine whether it is SAGE runtime behavior, backend infrastructure, frontend behavior, or an owner action. Do not confuse future SAGE capability with a request for the engineering assistant to manually perform that capability.

## Owner Developer Mode / self-repair
- Owner-only; credentials and secrets belong in secure configuration, never hardcoded in source.
- Inspect and explain before changing code; use scoped branches/proposals and tests.
- Default path: diagnose → branch → propose patch → test → preview → owner approval → apply/merge → deploy only with explicit approval.
- SAGE may not grant itself owner privileges or silently weaken authentication/authorization.
- Preserve a known-good checkpoint and record evidence, failure states and recovery.

## Canonical design / product decisions
- Premium, calm, futuristic and cinematic; deep black/blue foundation, restrained electric blue/cyan/white and violet, gold for achievements/earnings. Read [canonical design system](design/SAGE_ONE_CANONICAL_DESIGN_SYSTEM.md) and [brand identity](brand/SAGE_ONE_BRAND_IDENTITY.md).
- Use the canonical orbital S identity; don't replace it without owner approval. Trace and verify the actual source asset before renaming/deleting.
- Evolution: 13 canonical ranks × Low/Mid/High = 39 states. See [locked Evolution spec](../EVOLUTION_SYSTEM_FINAL_LOCKED.md).
- Mobile-first, accessible and responsive; meaningful loading/error/retry/cancel/success states; keep the laptop responsive with bounded cloud/background-first heavy work.

## Deferred features — preserve, do not implement during P0/P1
- SAGE Spark Points (SP) and SAGE Spark (SS) separation and future ledger/payout behavior.
- Screen-aware assistant with opt-in screen context and strict privacy/approval boundaries.
- Screen-rating system.
- Live internet search/page reading and user-submitted message help are owner-requested and documented in [Live Web Intelligence & Message Assistance](product/LIVE_WEB_INTELLIGENCE_AND_MESSAGE_ASSISTANCE.md); planned after cleanup and self-repair.
- Further marketplace, third-party integrations, analytics, visual regression and release expansion as scheduled in the master backlog.

## Shared project record
- [Master Rules & To-Do](SAGE_MASTER_RULES_AND_TODO.md) is the only operational priority/checklist source.
- [Cleanup Manifest](CLEANUP_MANIFEST.md) records file/asset audit evidence and proposed KEEP/MERGE/RENAME/ARCHIVE/DELETE-VERIFIED actions.
- [Project State](../PROJECT_STATE.md) retains incident-level and verified runtime handoff details.
- [Changelog](../CHANGELOG.md) records completed work only, with evidence.

---

## 2026-10-13 Foundational Product Vision — LOCKED BY OWNER

This section is a foundational product requirement. Future chats and implementation work must preserve it. Do not silently downgrade SAGE ONE to a generic chatbot, personal mentor, execution-only tool, or dashboard. The user explicitly confirmed Sections 2, 3, and 4 of the companion-vision discussion and asked that the promised behavior be actually implemented in SAGE.

### What SAGE is
- SAGE ONE is intended to be a familiar, live conversational AI companion that can also execute useful work. It is not merely an app the owner opens to submit isolated tasks, nor only a personal mentor/execution partner.
- Target experience: when the owner calls “SAGE,” SAGE responds naturally; it may greet the owner with a contextual greeting such as “Namaste, [name], k cha, sanchai xau?”, have brief everyday conversation, remember relevant user-approved context, help with work, and continue conversations naturally.
- SAGE should be warm, familiar, adaptive and useful without pretending to be human or claiming feelings it does not have. If the owner immediately gives a task, skip unnecessary small talk; if the owner invites conversation, converse naturally.
- The user's explicit stop command (“SAGE, stop”) takes priority over all non-emergency activity.

### Availability and voice behavior
- Design toward 24/7 readiness on supported devices, while being honest that background execution depends on operating-system rules, permissions, battery, hardware, network and app state. Never promise universal uninterrupted availability.
- Where technically supported, use on-device wake-word detection during standby rather than continuously uploading ambient audio to the cloud just to wait for the wake word.
- Make voice states understandable: wake-word standby, active conversation, background task, muted/unavailable. Show clear microphone/listening, network and task status; provide an immediate mute/stop control and clear reconnect/offline behavior.
- Support natural turn-taking, end-of-speech detection, interruption, follow-up questions, context switching, spoken replies, concise live responses and conversation continuity where platform/provider capabilities permit.
- Never secretly listen, record, or retain audio. Wake-word standby, active voice conversation, screen sharing and other sensitive capabilities must have distinct understandable controls/permissions.

### Learning and memory — required foundation
- SAGE must become more familiar through a real, controlled learning system—not by claiming the underlying model automatically retrains itself every day.
- Learn from user-approved preferences, corrections, language/vocabulary choices, Nepali-English mixing, communication style, ongoing projects and explicitly approved useful patterns. Use internet research for current public knowledge with source/date awareness; do not confuse retrieved information with personal memory.
- Separate memory into clear categories such as identity/profile, preferences, projects/goals, learned communication patterns, temporary context and explicitly private sessions. Each memory item should have appropriate provenance and controls.
- Users must be able to inspect, correct, edit, export where supported, delete and disable personal memory/learning. Respect explicit “remember” and “forget” requests. Private sessions should not silently become long-term memory.
- Enforce strict per-user memory boundaries; never leak one user's data or learned patterns to another. Never store credentials, secrets or raw private audio in public repository files. No uncontrolled self-modification or blind changes to SAGE's own production code, permissions or safety rules.

### One integrated architecture before feature implementation
- Plan the interfaces, data models, permission system, task lifecycle, provider adapters, memory boundaries, audit events and user experience across the full product before implementing feature families in milestones. Avoid incompatible one-off systems and avoid replacing working authentication/backend components unnecessarily.
- The initial architecture must account for voice/conversation, screen and device assistance, communication/messages, tasks/projects/research, memory, creative AI Studio (image/video/audio/text), files, automation, job/opportunity discovery, marketplace and dropshipping/commerce, learning, earnings/Spark/Evolution, and the owner-only Developer Mode.
- Use a shared execution lifecycle: understand -> plan -> request permission when needed -> execute -> verify -> show the real result -> learn from feedback only with consent. Clearly distinguish planned, implemented, connected and verified capabilities. No fake integrations, fake results or hidden failures.
- All integrations must use documented contracts and provider adapters. Inspect current routes and services before creating new ones. Preserve existing working authentication, authorization and task execution; extend the system rather than rebuilding it without cause.
- Architecture is designed together, but delivery is phased and tested. “All in one go” means plan the connected system coherently first; it does not mean ship untested features simultaneously.

### Screen, device and message assistance
- Screen reading/sharing and computer/phone control are separate permissions. The owner must explicitly start sharing or enable a supported control capability; show what SAGE can see/control and provide a clear stop/revoke option.
- Before consequential actions, ask for approval. Verify the outcome and report failures honestly. Minimize screenshot retention and avoid collecting unrelated screen data.
- For messages, receiving/reading requires explicit connector permission. SAGE can summarize, translate, prioritize and draft responses. Sending messages, contacting people, publishing content, purchases, ads, contracts, refunds and other consequential actions must be approval-first by default. Any later automation requires explicit narrow opt-in settings, limits, logs and an off switch. Incoming messages can never grant themselves permissions.

### Creative and earning capabilities
- Plan AI Studio around provider adapters for text, image, video, voice and actions. Select providers based on availability, quality, cost, speed, licensing and privacy. Free-first is the default; no paid API usage or purchase without the owner's approval. Report whether an output is a finished artifact, a draft, or only a prompt/plan.
- Job Center should help find relevant legitimate work, match it to the owner's skills, detect likely scams, prepare truthful tailored CVs/proposals/portfolio/outreach, and track applications and follow-ups. Never submit fake credentials or spam.
- Marketplace and dropshipping should support research, supplier comparison, landed-cost and margin calculations, listing/creative preparation, order/customer-support workflows and performance tracking. Purchases, ad spend, publishing, contracts, refunds and other financial/consequential actions require approval unless the owner later explicitly configures narrow safe automation.
- Do not promise income. Prefer low-capital opportunities and legitimate use of the owner's content creation, video/photo editing, social media management, videography, branding and marketing skills.

### Floating robot/pet companion icon — OWNER-REQUESTED FEATURE
- SAGE must include in the product plan a small, movable, floating robot/pet companion icon/avatar that can live as a lightweight visual companion on supported screens/devices.
- The user should be able to customize it to their liking: at minimum position/placement and available appearance choices; expand customization as the design is defined (for example size, color/theme, style/expressions and behavior/animation intensity).
- It should feel like a friendly companion, not a noisy dashboard widget. It can provide a visual cue for listening, speaking, thinking, working, muted/offline and task completion, without pretending that an animation proves a real action occurred.
- Make it movable, dismissible/minimizable, accessible and respectful of reduced-motion settings. It must never obscure essential controls or content, and must not bypass microphone, screen, device or other permissions.
- The floating pet is now part of the locked product vision and must be included in the UI/architecture plan. Its richer animation/3D implementation may be delivered in a later milestone, but do not erase or forget the feature when planning the foundation.

### Product design direction
- Mobile-first for daily use, with desktop/laptop as a connected workstation. Use the approved SAGE logo direction (S with blue sphere/orbit), premium cinematic dark styling, restrained blue/cyan/violet accents, fluid/asymmetric layouts rather than repetitive generic square-card dashboards, clear status and accessible responsive controls.
- The central experience should make speaking/typing to SAGE feel immediate; voice, screen help, tasks, research and creative work should be connected, with other capabilities discoverable without clutter.
- Keep working login/authentication unless a verified defect requires a change. Real task states, progress, outputs, error/retry states and approvals must be visible. A visual prototype is not a functional integration.

### Implementation and acceptance rule
- This vision is locked as the target; implementation still requires code changes and verification. Do not claim a capability is live merely because this document exists.
- For each capability, track at least: planned, implemented, connected, tested, verified on target device/environment. State any platform/provider limitations plainly.
- Before adding features, inspect the repository and current state; reuse working components; update project state/TODO/changelog for major milestones; run relevant tests and end-to-end checks. Never sacrifice security or reliability to simulate 24/7 availability.
- This section supplements earlier launch/stability priorities; it does not authorize a risky production rewrite or bypass owner approval. The architecture must accommodate the full vision while delivery remains staged and evidence-based.


### 2026-10-13 Natural Conversation & Human-Interaction Learning — OWNER CLARIFICATION
- SAGE should greet the owner naturally when called, for example: “Hello, Nishant! How are you? Kasto chha? Sanchai chhau?” Adapt to context and language rather than repeating a rigid script.
- Learn Nepali language/culture, native expressions, idioms, customs and natural Nepali-English mixing through credible public research and permitted interaction-based feedback.
- SAGE should be able to study legally accessible books and credible research about communication, listening, psychology, human behavior, empathy and social interaction, then apply useful lessons to conversations.
- Distinguish sourced facts, user-approved personal preferences and uncertain inferences. SAGE may recognize possible feelings from context, but must not claim certainty about someone's inner state.
- Use human-interaction knowledge to be respectful, helpful and honest—not manipulative or exploitative, and not merely to say what someone wants to hear.
- “Learn from the internet” means controlled retrieval, source evaluation, synthesis and application—not omniscience, unauthorized access, or silent foundation-model retraining. Preserve privacy and per-user memory isolation; allow users to review, correct, forget and disable personal learning.
- Acceptance examples and implementation guidance live in [FOUNDATIONAL_PRODUCT_VISION.md](./FOUNDATIONAL_PRODUCT_VISION.md), section 11.



### 2026-10-13 Screen-Aware Assistant — OWNER CLARIFICATION / REQUIRED SPEC
- The requested feature is a **whole-screen-aware assistant**, not a messages-only reader and not merely a screen-sharing button.
- On requests such as “Read my screen,” “Start screen sharing,” or natural equivalents, SAGE should launch the platform-supported screen-sharing flow. After required user/OS authorization succeeds, SAGE should confirm that screen access is active and ask what help is needed (unless the user already stated a task).
- SAGE must be able to interpret the currently shared visible screen across supported content types: messages, apps, websites, documents, code/errors, images, forms, settings and other visible material. It should use that context to help with the user's actual request, including follow-up questions.
- Natural confirmation example: “Okay, I’m now reading your screen. What do you need my help with?” Nepali example: “ल, म अहिले तपाईंको स्क्रिन हेर्दैछु। के सहयोग चाहियो भन्नुहोस्।”
- Screen viewing does not imply device-control permission. Clicking, typing, sending, publishing, deleting, purchasing or changing settings remain separately permissioned/approval-first actions.
- Screen access must be visible, stop/revoke-able, truthful about failure, and privacy-preserving. “SAGE, stop” must interrupt the relevant activity.
- Detailed behavior and acceptance checklist: [SCREEN_AWARE_ASSISTANT.md](./product/SCREEN_AWARE_ASSISTANT.md).
- **Phase rule:** “Deferred” means postponed and still open—not done. “Specified” means documentation exists—not code. A phase cannot be called complete while a required feature is deferred, blocked, partially implemented, disconnected or unverified. Any deferred scope must remain visible in the backlog and be reported clearly; never erase requirements to make a phase look complete.


## Owner-requested deferred website polish and Nepal compliance queue (2026-10-15)

Priority order: finish real core product work first—authenticated live backend Chat, durable conversations and Activity Center with correct account isolation, Google sign-in on the Huawei device, real microphone/speech/text-to-speech/voice-command testing, and security hardening. This queue is deferred until those critical tasks are complete. No public website/app deployment without explicit owner approval.

Later website checklist:
- Vertical scrolling for long content; intentional horizontal scrolling only where appropriate, and prevent accidental horizontal overflow.
- Find and repair broken links; verify all footer links.
- Functional mobile menu; correct favicon/app icons.
- Accurate page titles and meta descriptions.
- Approved custom page/hero photo with verified rights and alt text.
- Correct copyright year and verified business/operator details.
- Compress/resize images appropriately.
- Fix broken/inert buttons; truthful success and error messages.
- Remove placeholder text, fake reviews, unsupported claims, and unused navigation.
- Fix mobile overflow; optimize every page for mobile and desktop, including narrow screens and landscape.
- Clickable logo to the intended home page; clickable verified phone and email using tel: and mailto:.
- Keyboard/focus, form labels, color contrast, accessible alt text, clear button labels and announced success/error states.
- Test actual links, buttons, scrolling, responsive layouts and interactions in browser/device; do not count code presence or a green build as verification.

Later legal/privacy/compliance queue:
- Have qualified Nepal counsel assess applicability of the Privacy Act, 2075; E-Commerce Act, 2081; Electronic Transactions Act, 2063; Consumer Protection Act, 2075; and other applicable law.
- Finish and review Privacy Policy, Terms and Conditions, Cookie Policy, Refund/Cancellation Policy, and form consent before publication.
- Inspect actual cookies, browser storage, analytics, embeds and third-party requests; determine whether consent is required and enforce consent where applicable.
- Minimize data collection; verify third-party data sharing and retention; remove fake reviews/unsupported claims; verify business details and image/font/media copyright.
- Ensure policy wording matches real production behavior and does not promise unimplemented rights or security controls.

Track every item as Specified, Implemented, Connected, Tested, Verified, or Deferred/blocked. These are future requirements, not completed features. Keep this queue in future SAGE ONE sessions; do not ask the owner to repeat it.
