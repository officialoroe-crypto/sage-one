# SAGE ONE Cookie and Browser Storage Policy — Internal Draft Only

**DRAFT — NOT FOR PUBLICATION.** A policy template alone cannot determine cookie-consent requirements. Complete technical inventory and legal review first.

- **Operator:** [INSERT VERIFIED LEGAL OPERATOR NAME]
- **Contact:** [INSERT CONTACT EMAIL]
- **Effective date:** [INSERT DATE]

## 1. Technologies to inventory
Current source inspection observed:
- Google Fonts requests from Google-hosted domains.
- Google Identity Services script for Google sign-in.
- Browser localStorage containing a broad SAGE application state object, which can include profile and local chat/search state.

This is not a complete network/cookie scan. Verify cookies, localStorage, sessionStorage, IndexedDB, service workers, analytics, advertising pixels, embedded media, error reporting, and production dependencies with browser devtools/network inspection.

## 2. Categories and purposes
[LIST EACH ACTUAL TECHNOLOGY, OPERATOR, PURPOSE, DATA RECEIVED, RETENTION, AND WHETHER IT IS ESSENTIAL OR OPTIONAL.] Do not claim that analytics or tracking is absent until verified.

## 3. Consent and controls
Determine requirements for Nepal and every other jurisdiction where the service is offered. Where consent is required for non-essential technologies, block them until opt-in and provide clear accept/reject choices and a way to withdraw or change the choice. Do not use a banner that merely dismisses without recording or enforcing consent.

## 4. Local storage and clearing data
Explain the actual local state stored, why it is needed, how long it remains, and how users can clear it. Implement reliable sign-out/reset/delete behavior and verify it. LocalStorage is not encrypted storage.

## 5. Third-party links and changes
List third parties only after verifying the live site. Their own privacy policies may also apply. Explain how users will be notified of material changes.

## Publication gate
Do not publish until a browser-based inventory is completed on desktop and mobile, required consent behavior is implemented, policy text matches observed network behavior, and legal review is complete.
