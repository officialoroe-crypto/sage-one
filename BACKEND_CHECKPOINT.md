# SAGE ONE Backend Checkpoint

## Current boundary

The backend exposes both synchronous execution and durable background execution.

- `POST /execute` performs a request-scoped execution.
- `POST /execute/background` persists a task and returns immediately.
- `GET /tasks/{task_id}` is the durable polling surface for the frontend.
- The dedicated worker claims queued tasks, runs the orchestrator, and persists completion/failure.
- Provider routing keeps medium/heavy inference cloud-only; local Ollama remains restricted by the routing policy.

## Frontend contract

The first Flutter interface can be built against these stable backend surfaces without needing direct access to internal Python modules:

- `GET /health`
- `GET /orchestrator`
- `POST /session`
- `POST /chat`
- `POST /execute/background`
- `GET /tasks`
- `GET /tasks/{task_id}`
- `POST /tasks/{task_id}/cancel`
- `GET /brain/health`
- `GET /brain/routing?description=...`
- `GET /memory`
- `POST /memory`
- `GET /agents`
- `GET /tools`
- `GET /missions/{mission_id}`
- `GET /missions/{mission_id}/trace`
- `GET /missions/{mission_id}/result`

## Important behavior

Background execution is durable. The API request no longer creates an in-process asyncio task that can disappear when the web process restarts. The persisted task is owned by the background worker and can be recovered after lease expiry.

## Next phase

After this checkpoint passes CI and is explicitly merged, start the Flutter frontend around the existing API contract. Do not rebuild backend foundations while designing the interface unless CI or an integration test exposes a real contract defect.
