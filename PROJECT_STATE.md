# SAGE ONE — PROJECT STATE

Last updated: 2026-10-09
Current main: b1f22d4b074a73f041b4b5db956b6b8848726e26

## Identity
- Project: SAGE ONE
- Assistant identity: sage.ai
- Purpose: personal AI mentor and execution partner
- Style: direct, practical, action-oriented, no unnecessary fluff/questions.
- Rules: no lying/hiding important information; permission-based actions.

## Development workflow
- Work in large logical batches.
- GitHub main is the canonical source of truth.
- Use branches/PRs for source changes.
- Use GitHub Actions for heavy validation so the development laptop stays usable.
- Never call a feature complete until success, failure, refresh/restart behavior and regression coverage are checked where practical.
- For work spanning separate AI accounts/sessions, update this file and the relevant task/PR handoff in GitHub; chat memory alone is not synchronization.
- Before resuming, inspect the current main SHA, this file, TODO.md, AI_COLLABORATION.md, coordination/ACTIVE_WORK.yaml, relevant open PRs, and workflow results. Do not rely on older chat summaries when live GitHub state is available.

## Current active handoff — physical Android Google Sign-In

**Status: BLOCKED / device verification pending. Do not mark fixed yet.**

### Observed user-facing error
`Google sign-in exception: code client configuration error. Server client must be provided on Android null`

The user taps “Continue with Google” on the physical Android phone and sees this error. The user also opened the backend `/identity/config` URL in the phone browser and could see the public Google OAuth client ID. That indicates the endpoint was reachable in the browser at that time; it does not prove the installed APK uses that same backend URL or that OAuth is correctly configured end-to-end.

### Environment reported during troubleshooting
- Windows machine: `DESKTOP-ODIMLJ4`; Windows username: `Nishant`.
- Local repo: `C:\\SageOne\\sage_core`; Git Bash path: `/c/SageOne/sage_core`.
- Backend Python environment: `C:\\SageOne\\Backend\\venv\\Scripts\\python.exe`.
- A backend endpoint was previously used at `http://192.168.1.75:8000/chat`.
- Later reported computer LAN IPv4: `192.168.254.3`.
- Config URL tested in phone browser: `http://192.168.254.3:8000/identity/config`.
- The endpoint previously returned `success: true`, a public Google OAuth Web client ID, `developer_mode: true`, and `owner_mode_available: true`.
- ADB path: `/c/Users/Nishant/AppData/Local/Android/Sdk/platform-tools/adb.exe`.
- Previously authorized device ID: `K5J0220415001640`.
- Previous log file: `/c/Users/Nishant/Downloads/sage-google-debug.txt`.
- Recheck the actual current PC IP, backend port/process, device authorization and build URL before relying on these values. This project has used both ports 8000 and 8010.

### Relevant pull requests
- Older PR #190: https://github.com/officialoroe-crypto/sage-one/pull/190
  - Branch: `fix/android-google-signin-client-config`
  - Head SHA: `549edda19a8303ee431eb5fcd4a837dc7d7da7a8`
  - Last inspected state: open, not merged.
- Newer current-main PR #195: https://github.com/officialoroe-crypto/sage-one/pull/195
  - Title: `fix(android): configure Google sign-in client from current main`
  - Branch: `fix/android-google-signin-client-config-current-main`
  - Base SHA: `b1f22d4b074a73f041b4b5db956b6b8848726e26`
  - Head SHA: `9cfdae4b0446af20a3794a46507b794c6a36fe27`
  - Last inspected state: open, not merged, mergeable.
  - This is the newer rebased PR to track; check live PR/CI state before acting. Do not treat PR #190 and #195 as merged or assume either resolves the device issue without a successful device test.
- The proposed code fetches the public Google OAuth Web/server client ID from `/identity/config` on Android when `SAGE_GOOGLE_SERVER_CLIENT_ID` is not supplied at build time. The backend still needs a valid Web application OAuth client ID configured as `GOOGLE_CLIENT_ID` / `settings.GOOGLE_CLIENT_ID`.
- The client must be a public OAuth client ID, never a client secret. Do not place secrets or tokens in this file.

### API URL and release artifact risk
- Flutter's API URL must be reachable from the phone. A physical Android phone's `localhost` points to the phone, not the PC.
- The Android workflow's emulator default `http://10.0.2.2:8010` is not the correct default for a physical phone.
- For the reported LAN setup, `http://192.168.254.3:8000` is a candidate only if the backend is currently listening on port 8000 and the phone can reach it. Verify before building.
- Another documented development route uses ADB reverse with a local API URL, but the port must match the running backend.
- A prior release run #37902855005 and artifact #11603397195 predate the user's later custom-URL run; do not call that artifact the latest custom build.
- The user reported that a later Android workflow completed successfully, but its exact run ID/artifact and embedded API URL were not independently verified at the time of this handoff.

### Exact next actions
1. Inspect PR #195 and its SAGE CI / Android release workflow checks. Prefer this newer current-main PR for the fix; do not merge without required checks and review.
2. Verify current backend port, LAN IP and `/identity/config` response; confirm phone reachability using the exact URL.
3. Open the latest successful Android workflow run and confirm the input `api_url` matches the verified backend URL.
4. Download that run's `sage-one-android-release` artifact, locate the APK within the ZIP instead of assuming its internal folder layout, and install it over USB.
5. Confirm which API URL the installed APK was built with, then retry Google Sign-In.
6. If it still fails, capture fresh Android logs immediately after the attempt and inspect OAuth client type, Android package name/SHA certificate registration, backend configuration, and server-client-ID initialization.
7. Run/inspect SAGE CI and Android release validation for PR #195. Record real results and run IDs here.
8. Only mark resolved after a successful physical-device sign-in and relevant regression checks. Installation or CI success alone is not proof.

### Git Bash commands for artifact installation
Find downloaded artifacts:
```bash
find /c/Users/Nishant/Downloads -maxdepth 1 -type f -iname '*sage-one-android-release*.zip' -printf '%TY-%Tm-%Td %TH:%TM  %p\\n' | sort -r
```

After choosing the ZIP belonging to the latest successful run:
```bash
mkdir -p /c/Users/Nishant/Downloads/sage-one-new-build
unzip -o "/c/Users/Nishant/Downloads/EXACT_ARTIFACT_FILENAME.zip" -d /c/Users/Nishant/Downloads/sage-one-new-build
find /c/Users/Nishant/Downloads/sage-one-new-build -type f -name 'app-release.apk' -print
```

Install the discovered APK:
```bash
APK="$(find /c/Users/Nishant/Downloads/sage-one-new-build -type f -name 'app-release.apk' -print -quit)"
test -n "$APK" || { echo "APK not found; inspect the extracted artifact."; exit 1; }
"/c/Users/Nishant/AppData/Local/Android/Sdk/platform-tools/adb.exe" devices
"/c/Users/Nishant/AppData/Local/Android/Sdk/platform-tools/adb.exe" install -r "$APK"
```

## Current verified product state
Main contains the real private-first execution core:
- Durable worker with atomic claim, ownership leases, heartbeat, retry/backoff and lease recovery.
- Mission planning with dependency-aware bounded execution.
- Real tool execution and verification.
- Research OS with search, web reading, evidence, claims, verification and persistent research records.
- Provider routing with cloud-first controls and protected local fallback.
- Durable notifications and Flutter task polling/filtering.
- Unified Chat `/command` loop with persistent session history and owner/project context.
- Completed durable tasks can index project results and consented experience memory.
- SAGE Voice wake listening, capture and TTS use the same durable command path; Android release validation ensures microphone permission.
- Owner Developer Mode provides non-mutating preview plus explicit approval-gated apply.
- Developer proposals are durable and owner-scoped across API restarts.
- Project detail can queue project-scoped commands.
- Sales Engine is executable end-to-end: discovery → audit → score → durable lead → intelligence → approval-gated outreach → activity history → customer conversion.
- Owner Sales UI exposes lead pipeline, lead detail, approval, customer conversion and human follow-up recording; it never sends external outreach automatically.
- Authenticated identity/profile/onboarding/memory foundations exist.
- Private mobile Memory screen supports profile-scoped read/add/delete and a pending review queue for unconfirmed auto-learned memories, with keep/reject actions.
- World Intelligence has status, knowledge, due items and refresh UI.
- Spark/Evolution foundations are backend-backed and exposed in Flutter.
- Apps Hub/ecosystem surfaces, file manager, AI Studio, wallet, payments, transactions, profile, settings and notifications are exposed from the private shell.
- Final frontend bulk PR #186 is merged. Its exact head passed SAGE CI (214 Python tests; 27 Flutter tests) and Android APK/AAB release validation; the release artifact was uploaded.
- Android release workflow accepts an explicit device backend URL and uses an emulator-reachable host default.
- SAGE CI passes Python compile/lint/tests plus Flutter analyzer/tests.

## Private-first owner mode
- SAGE ONE is currently being built for one owner before public release.
- The private mobile entry path does not require Google sign-in, phone OTP or KYC.
- Developer access is local/owner controlled and production does not inherit private access by default.
- Public signup, multi-tenant ownership, production KYC/SMS and payment-provider expansion remain later scope.

## Safety / authority
- Developer Mode cannot apply source changes without explicit approval.
- God Mode does not create external authority over banks, payments, third-party accounts or destructive external systems.
- Owner economy mutations are audited.
- World Intelligence cannot self-modify production code.

## Economy / Evolution
- Spark is an internal platform credit, not cash.
- Premium work uses a canonical cost catalogue with reservation → settle/refund lifecycle and owner-scoped idempotency.
- Terminal failure/cancellation refunds exactly once; crash reconciliation exists.
- Verified mission-task results settle lifetime Evolution achievement atomically and idempotently.
- Evolution remains separate from Spark spending.

## Security
- Web Reader validates HTTP/HTTPS targets, blocks private/reserved/link-local targets, validates redirect destinations and bounds content.
- Authentication ownership checks are applied to user/profile/task/project/developer surfaces.
- Developer proposals are owner-scoped by trusted authenticated identity.
- Public worker health does not expose private worker results.

## Validation — historical evidence
- SAGE CI after earlier integration: PASS — run #37886992614.
- God Mode Developer Website after earlier integration: PASS — run #37886992587.
- Android release validation on an earlier exact PR head: PASS; APK/AAB artifact uploaded — run #37886497229.
- Android release validation on an earlier merge commit was reported running at the time — run #37886992592.
- These are historical results; check current workflow runs before using them as evidence for PR #195 or the current physical-device issue.

## Important coordination truth
Several older feature branches and open PRs still exist. Their existence does not mean their work is absent from main. Current main must be treated as the canonical implementation; stale branches should be reconciled or closed only after their changes are compared with main.

## Real remaining blockers
1. Production SMS/OTP provider credentials and delivery.
2. Long-lived Google web token/session refresh UX.
3. Smoke-test the premium lifecycle against the user's configured local database/provider setup.
4. Broader analytics-driven feedback improvement loop.
5. Full multi-tenant isolation only if SAGE becomes a shared public service.
6. Pixel-level visual regression for Evolution animation milestones (existing tests verify the 13-stage catalog, intensity behavior, safe fallback and transition identity, but are not screenshot goldens).
7. Broader external integrations and production release hardening.
8. Manual device/reference review of the complete Flutter surface; CI cannot prove visual fidelity.
9. Physical Android smoke test against the actual configured backend; current Google Sign-In error is documented above.

## Continuity rule
Always inspect actual GitHub main and this file before architectural changes. Do not rely on stale branches or old chat state.

## Multi-AI development coordination
- GitHub main is the synchronization source of truth.
- `AI_COLLABORATION.md` defines claims, path locks, handoffs, reconciliation and branch/PR rules.
- `coordination/ACTIVE_WORK.yaml` is the machine-readable active claim registry; it was empty when last inspected.
- The repository already has a shared AI collaboration/control-plane system, including work claims, handoff contracts, overlap/stale-claim controls, and CI coordination enforcement. Continue using and extending this system rather than creating a parallel handoff process.
- The repository's durable execution core and unified Chat `/command` loop are implemented as listed above; do not restart them just to document this incident.
- Do not silently overwrite another active agent's work.
