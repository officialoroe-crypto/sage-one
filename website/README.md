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

## Deployment and release boundary

**Publishing is paused during the current product rebuild.** The workflow may run CI, build the Flutter web app for QA, and upload a short-retention inspection artifact, but it has no Pages package/deploy job. Neither pushes to `main`, pull requests, nor manual workflow dispatch publishes the website or app.

The currently deployed website remains unchanged until the owner later requests a release and a separate, reviewed deployment workflow is restored. Do not publish `frontend/build/web` while voice, authentication, KYC, backend wiring, economy, and UI repairs are underway.

The web QA build is uploaded separately as a GitHub Actions artifact for inspection. Artifact availability does not prove live-browser behavior or authenticated backend access.

## Design direction

The website follows the SAGE ONE cinematic system: near-black foundation, cyan/blue/violet intelligence accents, gold for economy/premium signals, orbital-core motifs, restrained motion and responsive layouts. The landing page describes the product direction without claiming that unfinished integrations are already live.
