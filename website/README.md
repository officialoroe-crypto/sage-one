# SAGE ONE Website

The `website/` directory contains the SAGE ONE landing page and explicitly labelled interactive previews.

## Boundaries

- The landing page explains the SAGE ONE product direction.
- The Chat and phone-app pages are previews. Sign-in, balances, notifications and chat replies shown there are simulated unless a page explicitly says otherwise.
- Do not enter private, personal, or sensitive information into a preview.
- The authenticated product remains the Flutter application and SAGE Core APIs.
- Do not present draft policy documents as legal advice or proof of compliance.

## Local preview

From the repository root, run:

```text
python -m http.server 8080 --directory website
```

Then open `http://127.0.0.1:8080`.

## Quality checks

The `.github/workflows/sage-one-god-mode-pages.yml` workflow checks page metadata, favicons, local links and assets, image alt attributes, accessible button/input names, mobile-menu wiring, JavaScript syntax, and the Flutter web app. It uploads a short-lived QA artifact only.

**This workflow does not publish or deploy the website or app.** Public release requires a separate, explicit owner decision after legal, privacy, accessibility, image-rights, real-device, and functional verification.

## Contents and claims

The landing page includes an Evolution explorer, the SP/SS distinction and a roadmap. SP are internal non-cash points; SS payment features are not active. No exchange rate or spend limit is published as approved. Confirm business/operator details, public claims and money rules before public release.

## Design direction

Near-black foundation, cyan/blue/violet intelligence accents, gold for economy signals, orbital-core motifs, restrained motion, and responsive layouts. The site should clearly distinguish implemented and verified functionality from roadmap items and scripted previews.
