# SAGE ONE — Screen-Aware Assistant

Status: New owner-requested feature, recorded 2026-10-11. This is a specification, not a claim of implementation.

## Goal
Help the user understand and act on content visible on screen while chatting, translating, writing, learning, building websites, coding, and typing.

Examples:
- Explain a message or page.
- Translate context and suggest replies in another language.
- Suggest what to say next in friendly, professional, concise, or respectful tone.
- Explain visible code, errors, unfamiliar concepts, and website-building steps.
- Offer text that the user can review, edit, copy, or explicitly insert.

## Permission and privacy
- Screen reading is opt-in and visibly active. Never silently capture or continuously upload the screen.
- Show what is shared and provide an always-accessible pause/stop control.
- Ask for OS permissions and use the narrowest supported scope.
- Explain cloud processing and obtain appropriate consent; prefer on-device processing where practical.
- Exclude/redact passwords, authentication codes, payment details, and sensitive notifications where possible.
- Respect protected content, OS policies, accessibility permissions, and app restrictions.
- Never bypass security or privacy controls.
- Do not record audio or read messages in the background without explicit opt-in and platform permission.
- Suggestions do not send messages, submit forms, publish code, or execute external actions without explicit user approval.

## Modes
1. User-invoked screenshot/share → contextual answer.
2. Selected text/region → explain, translate, summarize, or rewrite.
3. Guided overlay with clear active indicator and pause control, only where supported.
4. Accessibility-assisted mode using OS APIs only with explicit permission.
5. Developer/learning mode for visible code, terminal output, UI, and concepts; never claim access to hidden source.

## Implementation sequence
Audit Flutter, Android/Huawei, web, and desktop capabilities first. Begin with user-invoked screenshot/text share, contextual response, and user-controlled copy. Add continuous awareness/overlay only after platform, permission, and privacy review. Separate capture, OCR, language detection, model calls, suggestions, and user-approved actions. Use existing/free infrastructure where possible.

## Required states and tests
Permission explanation/grant/deny; capture preview; sensitive-content warning; active indicator and immediate stop; offline/provider failure and retry; unsupported-platform fallback; editable suggested reply; confirmation before sending/submitting/publishing/executing. Tests must prove no capture or external action occurs without consent.

Do not advertise as available until platform integration, privacy controls, and end-to-end tests are verified.
