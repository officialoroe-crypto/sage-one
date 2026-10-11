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

`.github/workflows/sage-one-god-mode-pages.yml` validates the marketing page, runs Flutter analysis/tests, and builds a Flutter web QA artifact on relevant pull requests and main pushes. **The Flutter app build is not published to GitHub Pages during QA.**

The public Pages artifact contains only the static marketing site. Publishing it requires a deliberate manual workflow dispatch. Do not add `frontend/build/web` to the public Pages artifact until the owner approves public app release after both web and mobile QA pass. Repository Pages must be configured to use GitHub Actions.

The web QA build is uploaded separately as a GitHub Actions artifact for inspection. Artifact availability does not prove live-browser behavior or authenticated backend access.

## Design direction

The website follows the SAGE ONE cinematic system: near-black foundation, cyan/blue/violet intelligence accents, gold for economy/premium signals, orbital-core motifs, restrained motion and responsive layouts. The landing page describes the product direction without claiming that unfinished integrations are already live.
