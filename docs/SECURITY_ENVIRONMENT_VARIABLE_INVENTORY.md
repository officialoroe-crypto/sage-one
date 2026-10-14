# SAGE ONE Environment Variable Security Inventory

**Status:** Source-code inventory only. This does not verify the actual Render environment, GitHub secrets, or local .env values. Never paste secret values into ChatGPT or commit them.

## Secret values — store only in the hosting provider's secret/environment settings
- `GEMINI_API_KEY`: provider API secret.
- `GROQ_API_KEY`: provider API secret.
- `OPENROUTER_API_KEY`: provider API secret.
- `CEREBRAS_API_KEY`: provider API secret.
- `SAGE_PAYMENT_SECRET_KEY`: payment secret; leave unset until a real payment integration is approved and tested.
- `SAGE_DATABASE_URL`: database connection string; treat as secret because it may contain credentials.

Do not put these values in browser code, HTML, source maps, logs, screenshots, public issue comments, or frontend build variables.

## Identity, security and deployment controls
- `SAGE_ENV`: current code defaults to `development`. Set an explicit production value for a production deployment and add startup validation so a missing/unknown value cannot silently enable development defaults.
- `SAGE_PRIVATE_MODE`: private-mode control. Set explicitly for each environment.
- `SAGE_DEV_MODE`: developer mode. Must be explicitly disabled in hosted production; do not rely on defaults.
- `SAGE_OWNER_AUTH_SUBJECT`: configured owner identity subject. Treat as sensitive configuration; do not publish its value. Production authentication currently restricts access to this configured owner identity.
- `GOOGLE_CLIENT_ID`: OAuth client ID is normally public configuration, not a client secret. It still must match the authorized origins and redirect configuration in Google Cloud.
- `SAGE_CORS_ORIGINS`: explicit allowed origins. Include only exact, trusted HTTPS origins in production; do not add localhost to production.
- `SAGE_ENV_FILE`: local environment-file path. Avoid setting a workstation-specific path on hosted services.
- `SAGE_WORKSPACE`: workspace path/configuration; ensure it cannot point to sensitive files exposed by a static web server.

## Model and runtime configuration
- `SAGE_MODEL`, `SAGE_GEMINI_MODEL`, `SAGE_GROQ_MODEL`, `CEREBRAS_MODEL`, `SAGE_OLLAMA_MODEL`, `SAGE_ROUTING_MODE`, `SAGE_PREFER_LOCAL`, `OLLAMA_BASE_URL`: verify intended provider/model, allowed endpoint, and cost/privacy behavior.
- `SAGE_WORKER_ENABLED`, `SAGE_WORKER_POLL_SECONDS`: verify worker behavior and prevent accidental duplicate processing.
- `SAGE_WORLD_MAX_SOURCES_PER_DOMAIN`: runtime source limit.

## Findings requiring remediation/verification
1. `config/settings.py` falls back to `SAGE_ENV=development` when missing and derives private/developer-mode defaults from it. Add production startup validation and explicit deployment configuration.
2. `database/connection.py` falls back to `sqlite:///./sage_one.db` if `SAGE_DATABASE_URL` is absent. Require a durable database configuration in hosted production; test migrations, backup and restore.
3. `config/settings.py` attempts a legacy local path `C:/SageOne/Backend/.env` when the configured/default env file is missing. Remove or strictly limit this workstation-specific fallback for hosted production.
4. Current source checks do not reveal whether any required variable is actually set in Render or GitHub. Inspect those dashboards directly with values masked; verify names, environment scope, and last-rotation date.
5. Perform a full Git-history secret scan and dependency scan. The limited pattern search of selected current files is not a historical scan and does not clear the repository of secrets.

## Safe validation checklist
- [ ] Review secret names and presence in Render without copying values into chat.
- [ ] Confirm production/staging use separate credentials and database instances.
- [ ] Confirm no secret appears in the frontend bundle, source maps, artifacts, logs, or Git history.
- [ ] Confirm API keys are least-privilege and rotate any key found exposed, using a safe replacement plan.
- [ ] Confirm production fails closed if required security settings are missing.
