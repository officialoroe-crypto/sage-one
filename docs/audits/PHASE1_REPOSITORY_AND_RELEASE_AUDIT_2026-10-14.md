# SAGE ONE — Phase 1 Bulk Repository and Release Audit

**Audit date:** 2026-10-14  
**Baseline main SHA:** `3f0f0cabcca63c27cb513374abb0bfb05912b83d`  
**Audit branch:** `fix/phase1-pages-release-gate-20261014`  
**Scope:** Current GitHub main, latest relevant GitHub Actions runs, open maintenance/release PRs, current website structure, and selected backend/auth fixes.

This is an evidence-based first pass, not a claim that every tracked file, screen, API, animation, device flow, or deployment has been exhaustively tested.

## 1. Current main: CI evidence

The following workflows completed successfully on main SHA `3f0f0cabcca63c27cb513374abb0bfb05912b83d`:

- [SAGE CI — run 38498809028](https://github.com/officialoroe-crypto/sage-one/actions/runs/38498809028): Python checks/tests and Flutter analysis/tests passed.
- [Public Website and Web App — run 38498809095](https://github.com/officialoroe-crypto/sage-one/actions/runs/38498809095): website JavaScript syntax check, Flutter analysis/tests, Flutter web build, Pages artifact upload, and Pages deployment passed.
- [Android Release — run 38498809151](https://github.com/officialoroe-crypto/sage-one/actions/runs/38498809151): Android release validation, APK/AAB builds, and artifact upload passed.

**Boundary:** These results prove the named automated jobs ran successfully. They do not prove physical-device Google sign-in, microphone permissions, live backend requests, authenticated browser workflows, or every website interaction works end-to-end.

## 2. P0 release finding: the Flutter web app is included in the public Pages artifact

The current workflow `.github/workflows/sage-one-god-mode-pages.yml` copies both:

- `website/.` to the Pages root; and
- `frontend/build/web/.` to `public_site/app/`.

The successful Pages run above confirms that the workflow uploaded and deployed this combined artifact. This means the Flutter app route is published at `/sage-one/app/`; it has not been kept out of public Pages output by the current workflow.

The current Freebuff workspace at `website/` is a separate, intended website experience and must be preserved. Its real paths include:

- `website/index.html`
- `website/css/styles.css`
- `website/js/app.js`
- `website/js/backend.js`
- `website/img/sage-mark.png`

### Safe correction prepared on this branch

The updated workflow keeps the current Freebuff website at the Pages root and continues to validate the Flutter app, but uploads the Flutter web build only as a short-lived QA artifact. The public Pages artifact contains the current website only. The change also stops an active Pages deployment from being cancelled by another workflow run.

This branch has **not** been merged or deployed. The new workflow must pass its own GitHub Actions checks and be reviewed before release.

## 3. Open PR reconciliation

Do not merge old branches just because they are green or have a mergeable flag. Compare their contents against current main first.

| PR | Finding on current main | Phase 1 action |
|---|---|---|
| [#228 — cleanup and self-repair](https://github.com/officialoroe-crypto/sage-one/pull/228) | Open and mergeable. Current SAGE CI and Android Release runs on its latest inspected head succeeded. Its own manifest still says repository-wide asset/reference inspection remains incomplete. | Keep as the central cleanup/rules PR; review its remaining scope and do not call P0 complete yet. |
| [#227 — major-work rule](https://github.com/officialoroe-crypto/sage-one/pull/227) | Open and mergeable; overlaps the canonical-rules work in #228. | Compare and consolidate rather than merging duplicate instructions separately. |
| [#225 and #219 — hold public app until QA](https://github.com/officialoroe-crypto/sage-one/pull/225) | These branches target the earlier marketing-site structure and test root paths such as `website/styles.css`, `website/app.js`, and `website/favicon.svg`, which are not the current Freebuff paths. | Do not merge as-is. Preserve their release-safety intent through the current-main workflow correction in this branch. |
| [#224 — orbital branding and voice entry](https://github.com/officialoroe-crypto/sage-one/pull/224) | Its requested orbital splash treatment and prominent Voice Command entry are not present in current `main.dart` / `splash.dart`. The branch is not currently mergeable. | Rebase/reconcile with current main, run Flutter checks, and verify the actual phone/microphone experience before considering complete. |
| [#223 — CORS allowlist](https://github.com/officialoroe-crypto/sage-one/pull/223) | The intended CORS fix is already present in current `app/main.py`: the canonical GitHub Pages origin remains allowed when custom origins are configured. | Treat this older branch as superseded; validate deployed runtime behavior separately. |
| [#222 — owner onboarding flags](https://github.com/officialoroe-crypto/sage-one/pull/222) | Current `identity/api.py` already returns `owner_mode` and `developer_mode` at the top level of the Google login response. | Treat the duplicate backend change as superseded; still verify real owner onboarding on device. |
| [#190 — Android Google sign-in config](https://github.com/officialoroe-crypto/sage-one/pull/190) | Current `frontend/lib/core/identity_client.dart` already attempts to load the server/web client ID from `/identity/config` when needed and reports actionable configuration errors. | Do not merge the older branch blindly. Physical-device sign-in is still an unresolved verification requirement until tested. |
| [#221 — onboarding input and Enter behavior](https://github.com/officialoroe-crypto/sage-one/pull/221) | Still requires a direct diff-versus-current-main review before any decision. | Keep in the reconciliation list; check whether its changes are already present and whether it has current CI. |

## 4. P0 inventory gaps still open

The repository cleanup manifest and current project state identify unfinished work that must not be marked complete prematurely:

- Classify tracked files and assets, trace references, and identify verified duplicates/residuals.
- Visually inspect and hash the design assets; locate or reconcile the canonical logo source asset.
- Check stale project-state dates and conflicting instructions after comparing current source.
- Run broken-link and asset-reference checks.
- Audit critical UI actions for real backend requests, error states, persistence, and false-success behavior.
- Verify the live website and backend together in a browser; check authentication, chat, task creation/execution, refresh/restart behavior, and errors.
- Verify the actual Android device separately, including Google sign-in and voice/microphone behavior.

No production data, secrets, or canonical assets should be deleted as part of generic cleanup.

## 5. Release and implementation rules

- Preserve the current Freebuff website, Flutter app source, FastAPI backend, and all existing AI provider adapters.
- Keep the Flutter web QA artifact separate from the public Pages artifact until the owner explicitly approves publishing it.
- Never expose provider secrets in browser code.
- Do not mark API, authentication, research, media generation, or animations as verified just because source code or CI exists.
- Use reviewable branches and PRs; no merge or production deployment is performed by this audit branch.
- Prefer free-first solutions; no surprise paid calls.
- Record evidence and update the canonical project state only after checking the resulting commit and test/deployment evidence.

## 6. Exit criteria for Phase 1

Phase 1 is complete only when:

1. The current website remains intact and its static assets are validated.
2. The release workflow publishes the intended website but keeps the Flutter web QA build out of public Pages output.
3. The new workflow passes SAGE CI, website validation, Flutter analysis/tests/build, and release workflow checks.
4. Open PRs are classified as merge, rebase/cherry-pick, superseded, or close—with rationale—and no stale duplicate change is merged blindly.
5. The relevant asset/reference and documentation checks are completed or explicitly blocked with reasons.
6. The project state points to the actual current commit and distinguishes automated CI from browser/device verification.
7. The owner reviews the PR before any merge or deployment.

## 7. Next phase after this gate

Once the release gate and PR reconciliation are accepted, move to the real core loop:

**sign in → send chat → receive a real provider response → create task → execute through worker → persist result → verify and display it.**

Only after that end-to-end loop is tested should the next bulk batch expand provider routing (preserve Groq, Cerebras, Gemini, Ollama; add OpenRouter with tests), then research/memory and media workflows.
