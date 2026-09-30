#!/usr/bin/env python3
"""Validate SAGE ONE's active AI work claims without external dependencies."""
from pathlib import Path

path = Path("coordination/ACTIVE_WORK.yaml")
if not path.exists():
    raise SystemExit("coordination/ACTIVE_WORK.yaml is missing")

text = path.read_text(encoding="utf-8")
required = ("version:", "updated_at:", "claims:")
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("Missing required coordination keys: " + ", ".join(missing))

if "claims: []" in text:
    print("AI coordination check: PASS (no active claims)")
    raise SystemExit(0)

fields = ("id:", "agent:", "branch:", "base_sha:", "scope:", "objective:", "status:", "started_at:", "updated_at:")
missing = [item for item in fields if item not in text]
if missing:
    raise SystemExit("Active claims require fields: " + ", ".join(missing))

print("AI coordination check: PASS (claim structure present)")
