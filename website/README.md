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

## Deployment

`.github/workflows/sage-one-website.yml` deploys the directory to GitHub Pages when changes reach `main` and the repository Pages configuration permits the deployment.

## Design direction

The website follows the SAGE ONE cinematic system: near-black foundation, cyan/blue/violet intelligence accents, gold for economy/premium signals, orbital-core motifs, restrained motion and responsive layouts.
