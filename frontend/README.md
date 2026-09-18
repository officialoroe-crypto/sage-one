# SAGE ONE Flutter Frontend

First mobile command-center slice for SAGE ONE.

## Design direction

- Premium dark interface
- One primary command surface
- Background execution is visible but does not block the user
- Research, Tasks, Projects, and Agent are first-class modules
- Minimal chrome; the command is the product

## Backend connection

The API base defaults to Android emulator forwarding (`http://10.0.2.2:8010`). Override it with `--dart-define=SAGE_API_URL=http://YOUR_BACKEND_HOST:8010`.

Current integration points:

- `GET /brain/routing`
- `POST /execute/background`
- `GET /tasks/{task_id}` (client ready; task polling UI follows)
