# SAGE ONE Website Workspace

The Freebuff-exported workspace is the intended SAGE ONE website experience. Its source lives in this directory:
- `index.html` — workspace entry point
- `css/` — responsive visual system and animation
- `js/` — screens, navigation, voice capture, and the authenticated SAGE Core bridge
- `img/` — workspace imagery and brand assets

The Flutter mobile app remains in `frontend/`; FastAPI remains the canonical backend.

## Preview locally without publishing

1. Download the latest successful **SAGE ONE Marketing Website and Web App QA** run from GitHub Actions.
2. Download the artifact named `sage-one-website-workspace-qa-<commit>` and extract it to a folder, for example `C:\\SageOne\\website-qa`.
3. Open Command Prompt in that extracted folder and run:

```bat
py -m http.server 8080
```

4. Open `http://127.0.0.1:8080` in Chrome or Opera. Keep the server window open while testing.

Microphone input requires a supported browser and microphone permission. Voice recognition shows a transcript and waits for you to review and send it. Google sign-in from a local preview also requires `http://localhost:8080` or `http://127.0.0.1:8080` to be an authorized origin in the Google OAuth configuration. Do not paste OAuth secrets or tokens into chat.

## Current backend boundaries

- Google owner sign-in, chat, and explicitly queued tasks are connected in code but still require real browser end-to-end verification.
- Phone verification depends on an actual configured SMS provider.
- Formal KYC, external payments, research, and media-generation providers are not to be marked complete unless the real provider is connected and verified.
- Prototype-only actions must clearly say they are unavailable and must not fake a transaction, verification, generated file, or completed task.

## Release boundary

**Publishing is paused during the current rebuild.** The GitHub Actions workflow validates the workspace, runs Flutter analysis/tests, builds the Flutter web app for QA, and uploads short-retention inspection artifacts. It has no Pages package/deploy job. Pushes to main, pull requests, and manual workflow dispatch do not publish the website or app.

The currently deployed public website remains unchanged until a later release is explicitly requested. QA artifacts are for private inspection only and do not prove live-browser behavior or authenticated backend access.
