# SAGE ONE Website

The `website/` directory contains the public-facing SAGE ONE landing page and clearly labelled interactive previews.

## Boundaries

- This site explains the SAGE ONE vision, workflow, intelligence and Evolution.
- The chat and phone pages are previews; their replies are scripted and their example controls do not call the live backend.
- SP (SAGE Spark Points) are internal non-cash points. SS is a separate intended money unit; live payments, exchange rates, wallet transactions and cash-out are not enabled.
- The website does not expose authenticated workspace data or claim that preview actions have executed.
- The authenticated product remains the Flutter application and SAGE Core APIs.

## Local preview

From the repository root, serve the website directory:

```text
python -m http.server 8080 --directory website
```

Then open `http://127.0.0.1:8080`.

## Deployment

No deployment or public release is authorized during the current QA work. The Pages workflow may publish the site when a future release is explicitly approved. Legal pages and publication review remain deferred until the end.

## Contents

The landing page includes the SAGE ONE brand, Learn-to-Evolution progression, 13-rank Evolution explorer, separate SP/SS status, a roadmap and project status. The phone and chat pages demonstrate visual interactions only; they must not be treated as live authentication, AI, payments, or account balances.
