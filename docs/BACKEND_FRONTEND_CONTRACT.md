# Backend ↔ Frontend Work Contract

## Backend owns
API contracts, authentication, authorization, database models/migrations, memory, research/task execution, Spark ledger, Activity Center reward validation, background workers, integrations, CI, security and deployment interfaces.

## Frontend owns
Screens, navigation, visual design, design tokens, typography, animations, responsive layouts, loading/error/empty states and user interaction presentation.

## Rules
1. Frontend consumes documented backend contracts; it must not invent server behavior.
2. Backend exposes stable versioned contracts and explicit error states.
3. Breaking API changes require updating this document and frontend consumers together.
4. End-to-end QA must test real backend calls, not only mocked success screens.
5. Every important route/button/link must have a verified destination/action.
6. Secrets never live in frontend source or GitHub.


## Sales Engine API

The Sales Engine is exposed under `/sales` and is owner/profile scoped through the existing authentication boundary.

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/sales/discover` | Search for business candidates through the configured discovery provider. |
| POST | `/sales/leads` | Create a durable sales lead. |
| GET | `/sales/leads` | List the authenticated profile's leads, optionally filtered by status. |
| GET | `/sales/leads/{lead_id}` | Retrieve one scoped lead. |
| POST | `/sales/leads/{lead_id}/audit` | Audit online presence, calculate opportunity score, and generate sales intelligence/outreach draft. |
| PATCH | `/sales/leads/{lead_id}/status` | Move a lead through the sales pipeline. |
| GET | `/sales/leads/{lead_id}/activities` | Read the lead activity history. |
| POST | `/sales/leads/{lead_id}/outreach/approve` | Explicitly approve or reject the generated outreach draft; approval does not send a message. |

### Sales safety rules
- Discovery and audit are analysis capabilities; they do not contact businesses automatically.
- Outreach is generated as a draft and requires explicit owner approval before becoming `outreach_ready`.
- Lead reads and mutations are scoped to the authenticated profile.
- Frontend must treat discovery, audit, and outreach as potentially slow operations and provide loading/error states.
