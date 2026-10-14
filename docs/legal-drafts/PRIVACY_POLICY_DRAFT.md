# SAGE ONE Privacy Policy — Internal Draft Only

**DRAFT — NOT FOR PUBLICATION.** Working draft, not legal advice or a compliance claim. Complete all placeholders, verify live data flows, and obtain qualified Nepal legal review before publishing.

- **Operator/legal entity:** [INSERT LEGAL OPERATOR NAME]
- **Public contact:** [INSERT PRIVACY/CONTACT EMAIL]
- **Business address and jurisdiction:** [INSERT VERIFIED DETAILS]
- **Effective date:** [INSERT DATE]

## 1. Scope
SAGE ONE is an AI assistant and execution workspace. Features, providers, and data flows may differ by deployment. This policy must describe the exact live website, mobile app, backend, hosting, and enabled features.

## 2. Information the current code may process
Confirm each item against the release candidate and remove fields that are not necessary:
- Google identity claims needed for sign-in, such as provider subject, email, name, and profile image URL.
- Profile/onboarding fields supported by the backend: name, phone, address, age, basic information, help intent, capabilities, and memory-consent state. Review whether age, address, and phone are necessary; do not collect them merely because fields exist.
- Prompts, conversation messages, session identifiers, task/activity records, and saved memories when those features are used.
- Technical data processed by hosting, security, and service providers, which may include IP address, timestamps, browser/device information, and diagnostic logs. Verify provider logs and retention.
- Browser-local state: current website code stores a broad application state object in localStorage, which may include profile and local chat/search state. Document the exact fields and deletion behavior.
- Voice input/output: document whether speech is processed locally or by browser/device/cloud services, what audio or transcripts are transmitted or retained, and how users can disable it. Do not publish until verified.

## 3. Purposes and choices
Describe the specific purpose for each field and feature. Use information only for the purpose explained when collected, subject to applicable law. Memory learning must remain off unless the user has made the required informed choice. Optional marketing consent, if introduced, must be separate from necessary service processing.

## 4. AI and other providers
Depending on deployment configuration, prompts or context may be sent to the selected AI/model provider. List the actual providers enabled, their roles, data handling terms, and whether data may be processed outside Nepal. Do not state that prompts are never shared unless architecture and provider terms prove it.

## 5. Sharing and international processing
List hosting, database, authentication, AI, voice, payment, analytics, support, and security providers that actually receive data. Explain what each receives, why, where it is processed, and retention/deletion controls. Do not list a provider as connected if it is not used.

## 6. Retention, access, correction, export and deletion
[DEFINE RETENTION PERIODS BY DATA CATEGORY.] Explain how users can access, correct, export, or request deletion of profile, conversations, memories, and task history; describe backup/log deletion limits. Implement these workflows before promising them here.

## 7. Security
Describe only controls that are implemented and verified. Never promise that the service is impossible to hack or completely secure.

## 8. Children and sensitive information
[DEFINE MINIMUM AGE AND GUARDIAN PROCESS AFTER LEGAL REVIEW.] Tell users not to submit government IDs, biometrics, passwords, payment-card data, or other sensitive information unless a reviewed feature explicitly requires it and safeguards are in place.

## 9. Cookies and browser storage
Link to the Cookie Policy after it is reviewed. Inventory cookies, localStorage, sessionStorage, service workers, analytics, Google sign-in, and third-party requests.

## 10. Rights, complaints and changes
[INSERT RIGHTS/COMPLAINT PROCESS REQUIRED BY APPLICABLE LAW.] Provide the verified contact above. State when this policy changes and how users will be informed.

## Publication gate
Do not publish until every placeholder is resolved, every data flow is verified, optional consent is wired to actual behavior, data minimization is complete, and qualified counsel has reviewed Nepal and other relevant laws.
