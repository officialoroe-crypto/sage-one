# SAGE ONE Workspace — Freebuff Prototype Integration

This folder preserves the 37-route vanilla-JavaScript SAGE ONE workspace from the uploaded archive and connects its first live flows to the canonical SAGE Core API.

## Preview URL
After merge and successful GitHub Pages deployment:
`https://officialoroe-crypto.github.io/sage-one/workspace/`

The existing Flutter app remains at `/sage-one/app/`. This workspace is a separate web surface and does not replace the Flutter app or landing page.

## Connected flows
- Google Identity Services obtains a Google ID token.
- `POST /identity/google` verifies it.
- Live workspace access is granted only when the API returns `owner_mode: true`.
- Chat calls `POST /chat`.
- The explicit “Queue my last request as a task” follow-up calls `POST /command`.
- The token remains in JavaScript memory and is not written to localStorage/sessionStorage.

Default API base: `https://sage-one-api.onrender.com`. Set `window.SAGE_API_BASE_URL` before `js/backend.js` loads to override it.

## Important limits
This is the first integration slice, not a claim that every screen is production-ready. Research Lab progress, image/video generation, KYC, premium payments, Spark purchases/transfers/withdrawals, marketplace checkout, and seeded jobs/courses/earnings are not real integrations. Actions that would imply real money movement, verification, research completion, or media generation are blocked with a clear message. Local demo balances are reset to zero. Remaining catalog and workflow screens still need their individual API contracts and end-to-end tests.

## Deployment requirements
- The Render API is online and `/identity/config` responds.
- `GOOGLE_CLIENT_ID` is configured on the API.
- Production `OWNER_AUTH_SUBJECT` matches the owner Google account.
- Google OAuth allows `https://officialoroe-crypto.github.io`.
- Backend CORS allows the GitHub Pages origin.
- Test real owner sign-in, chat response, queued task, and worker completion before calling the app production-ready.

This source change alone does not prove a successful production deployment or end-to-end test.
