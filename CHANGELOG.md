# SAGE ONE — CHANGELOG

## 2026-09-17

### Research OS
- Search system confirmed working.
- Multiple-query search works.
- Deduplication works.
- Source IDs, URLs, snippets, provenance and timestamps are present.
- Previous test produced 6 unique sources from 3 queries.
- Web Reader / research synthesis work has progressed to reading multiple sources and producing evidence items.

### CI
- Compilation succeeds.
- Pytest currently fails because the top-level `execution` package cannot be imported.
- Cause identified as CI not putting the repository root on `PYTHONPATH`.
- Immediate next fix: CI import path.

### Worker Architecture
- Identified that the current worker needs stronger durability.
- Required improvements documented:
  - atomic claiming
  - worker leases
  - heartbeat
  - retry/backoff
  - crash recovery
  - idempotency

### Performance Architecture
- Recent tests have pushed the laptop CPU to approximately 100%.
- New architectural requirement established:
  heavy AI/research must eventually run in cloud/background workers.
- Local Ollama should not automatically become the fallback for heavy work.
- SAGE should classify tasks as LIGHT / MEDIUM / HEAVY.
- A local resource guard is planned.

## Earlier Known Milestones

### Backend
- FastAPI/Uvicorn backend established.
- Backend has been run on port 8010 using the project virtual environment.
- Database initialization produced:
  `SAGE DATABASE INITIALIZED.`

### Flutter
- Flutter stable environment configured.
- Flutter doctor was previously green.
- Multiple connected devices were available.

### Gemini
- An unavailable Gemini model name caused a 404.
- Later Gemini usage encountered free-tier request quota limits.

### Ollama
- `llama3.2:3b` produced an empty summary / 0 claims during reliability testing.
- This contributed to the decision to strengthen cloud provider routing and structured-output validation.
