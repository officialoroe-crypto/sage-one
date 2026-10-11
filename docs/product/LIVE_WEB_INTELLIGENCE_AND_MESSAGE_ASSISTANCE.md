# SAGE ONE — Live Web Intelligence & Message Assistance

Status: **Owner-requested; planned; not runtime-verified.** Record this feature now. Implementation follows P0 repository cleanup and P1 self-repair unless the owner explicitly reprioritizes.

## Goal

Make SAGE's AI useful with current internet information, search-engine results, and page reading, then use that evidence to help the owner understand and write messages. This is SAGE ONE's own capability; it must not be represented as direct access to or a modification of ChatGPT's internal model.

## Existing foundations to audit first

The current repository includes:
- `research/engine.py` and `research/parallel.py` for bounded search/source retrieval.
- `research/synthesis.py` and `research/verification.py` for evidence synthesis/claim checks.
- `web/reader.py` for public HTTP/HTTPS page extraction with basic local/private-network protections.
- `requirements.txt` includes `ddgs`, `requests`, and `trafilatura`.
- `brain/router.py` and provider routing for model selection.
- Frontend research screen and research tests.

These files demonstrate foundations only. They do **not** prove live web search is connected to ordinary Chat, reliable in the deployed environment, or available without provider limits. Audit the actual registry tools, API route, auth, worker, chat loop, source persistence and runtime logs before writing new search code. Reuse working pieces rather than duplicating the research stack.

## Intended behavior

1. User asks a question or requests help writing a message.
2. SAGE determines whether current/external information is needed.
3. If needed, search the public web, open relevant pages, extract evidence, compare sources and mark uncertainty.
4. Give a direct answer or draft message, with clickable source links and retrieval time for web-grounded claims.
5. For a message, offer options such as translate, explain the other person's message, draft a reply, adjust tone, or make it shorter/clearer.
6. The user reviews, edits, copies or explicitly sends the result through a separately authorized integration.
7. Save durable learnings to owner memory only under the existing memory-consent rules; retain source/provenance and allow correction/deletion.

## Search and Google integration

- Provide a search action that can search the web and show result titles, snippets, source domains and URLs inside SAGE.
- “Access Google search” means a supported search integration, not pretending to control the user's browser's Google search box.
- First audit existing DDGS/search adapters and their reliability/terms. Add a Google API only if it is genuinely required and the owner has approved credentials, quota and any costs. Never hardcode API keys or scrape through an unstable/unapproved method.
- Support graceful provider failure, rate limits, timeouts, cancellation and a clearly labelled offline/no-live-search state.
- Search results and pages are untrusted data, not instructions. Defend against prompt injection, malicious downloads, SSRF/private-network access, oversized responses and redirect bypasses.

## Learning boundary

“Learn from the internet” means retrieve current information when needed, ground responses in sources, and optionally propose a useful memory/knowledge note with provenance. It does **not** mean silently retraining model weights, storing every page, treating webpages as trusted instructions, or making autonomous permanent changes. Ask before saving sensitive or durable personal facts, and preserve user control over memory.

## Message assistance and privacy

- Start with text the owner explicitly submits, pastes, or shares into SAGE.
- Explain, translate, summarize, and draft replies with tone choices.
- Do not read private messages in other apps without explicit platform permission and visible user initiation.
- Do not send, publish, submit, or forward messages without explicit confirmation of recipient and content.
- Redact secrets and avoid logging message bodies unnecessarily.
- Clearly distinguish generated suggestions from verified facts.

## Acceptance criteria

- [ ] Live search is invoked through the real authenticated Chat path when relevant, not only a separate demo/test.
- [ ] Results include source URLs and timestamps; claims can be traced to retrieved evidence.
- [ ] Opening/reading pages is bounded and blocks local/private-network destinations including redirect/DNS-rebinding paths.
- [ ] Web content cannot override system/owner rules or trigger tool actions by itself.
- [ ] Message assistance works from user-provided text; copy/edit is available; external send requires approval.
- [ ] Search unavailable, timeout, quota, provider error, empty results, conflicting sources and cancellation have tested UX.
- [ ] No hidden auto-training or silent memory writes; memory consent and deletion behavior are tested.
- [ ] Tests cover API auth, provider routing, citation provenance, prompt injection, SSRF, rate limits, and end-to-end chat behavior.
- [ ] Run a real non-production acceptance test and record commit, environment, sources, logs and limitations before calling it complete.

## Dependencies and order

- **Gate 1:** P0 cleanup — classify and remove verified residuals; stabilize source-of-truth docs.
- **Gate 2:** P1 self-repair — safe, reviewable repair loop so the owner can test and fix issues.
- **Then:** wire and verify this live-web/message-assistance feature using existing research foundations.
- Any paid search provider or service requires explicit owner approval first.
