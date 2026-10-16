# SAGE ONE n8n QA launcher (QA only)

This folder contains an importable n8n workflow that coordinates the existing GitHub Actions checks. It is a launcher, not a claim that the tests have passed.

## What it does
- Receives a POST request through a protected n8n webhook.
- Validates the requested Git branch/ref (defaults to `main`).
- Dispatches the Playwright website/browser + live API smoke workflow.
- Dispatches the Flutter analyze/test + Android QA APK build workflow.
- Returns a unique request ID and links to both GitHub Actions workflows.

## Import and configure
1. In n8n, choose **Workflows → Import from File** and import `sage-one-autonomous-qa.json`.
2. Open both **Start ... QA** HTTP Request nodes. Add GitHub API authentication using a GitHub credential; do not paste a token into the workflow or share it in chat.
3. Use a fine-grained GitHub token restricted to `officialoroe-crypto/sage-one`, with Actions: write and Contents: read. The token should not have repository administration, deployment, or write-to-code permissions.
4. Protect the **QA Request Webhook** with Header Auth credentials. Do not activate an unauthenticated public webhook.
5. Save, test with the workflow's Test URL, then activate only after both GitHub credential nodes are configured.
6. POST JSON such as `{"ref":"main"}` to the Production webhook URL. You can also pass a branch name, for example `{"ref":"redesign/flutter-app-brand-dashboard-20261016"}`.
7. Match the returned `request_id` to the run names in GitHub Actions. A successful webhook response means only that dispatch was accepted; inspect the actual job conclusions and uploaded artifacts.

## Important test boundaries
- Browser QA uses Playwright against the repository's QA website and includes live API smoke checks.
- Android QA runs Flutter analysis/tests and builds QA APK artifacts. GitHub-hosted runners do **not** control the user's Huawei P40 Pro, grant its microphone permission, or prove speech works on that device.
- To automate physical-phone interaction later, a trusted self-hosted runner must be configured on the Windows PC with Android platform-tools and the phone connected via USB debugging. Keep it locked to QA jobs and never expose ADB over the public internet.
- This workflow does not merge PRs, change source code, deploy, publish, touch production data, or report success based on dispatch alone.
- No secrets, OAuth client secrets, passwords, or tokens belong in this folder.
