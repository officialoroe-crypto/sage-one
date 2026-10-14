# SAGE ONE Website

The `website/` directory is the public-facing SAGE ONE landing surface.

## Boundaries

- This site explains SAGE ONE, SAGE WORKFLOW, Intelligence, Spark and Evolution.
- It does not expose authenticated workspace data.
- It does not pretend that publishing, social connections, research or execution are available from the public landing page.
- The authenticated product remains the Flutter application and SAGE Core APIs.

## Local preview

Serve this directory with any static HTTP server. For example:

```text
python -m http.server 8080 --directory website
```

Then open `http://127.0.0.1:8080`.

## Product workspace and release boundary

The Freebuff-exported workspace is the intended website experience. Its source lives in `website/index.html`, `website/css/`, `website/js/`, and `website/img/`. The authenticated Flutter app remains in `frontend/`, and FastAPI remains the canonical backend.

**Publishing is paused during the current rebuild.** The GitHub Actions workflow validates the workspace, runs Flutter analysis/tests, builds the Flutter web app for QA, and uploads short-retention inspection artifacts. It has no Pages package/deploy job. Pushes to main, pull requests, and manual workflow dispatch do not publish the website or app.

The currently deployed public site remains unchanged until the owner later requests a release and a separate, reviewed deployment workflow is restored. Do not publish the Flutter build while voice, authentication, KYC, backend wiring, economy, and UI repairs are underway.

A QA artifact is for inspection only. It does not prove live-browser behavior or authenticated backend access.
