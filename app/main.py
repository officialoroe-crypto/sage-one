from __future__ import annotations

import json
import os
from typing import Any, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.core import sage
from brain.router import router
from config.settings import settings
from database.connection import SessionLocal, Base, engine
from database import repository

from missions.engine import mission_engine
from missions.planner import planner
from execution.engine import execution_engine
from execution.trace import execution_trace

from permissions.engine import permissions
from tools.registry import registry
from agents.manager import agents
from tasks.engine import tasks
from notifications.service import list_notifications, mark_read, mark_all_read
from missions.api import router as mission_api_router
from identity.api import router as identity_api_router
from world_intelligence.api import router as world_api_router
from economy.api import router as economy_api_router


# ============================================================
# APP
# ============================================================

app = FastAPI(
    title="SAGE ONE",
    version="6.0.0",
    description="SAGE ONE personal AI execution core",
)


def _cors_origins() -> list[str]:
    configured = os.getenv("SAGE_CORS_ORIGINS", "")
    if configured.strip():
        return [origin.strip().rstrip("/") for origin in configured.split(",") if origin.strip()]
    return [
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:7357",
        "http://127.0.0.1:7357",
    ]


# Browser clients use Authorization headers, so origins must be explicit rather
# than a wildcard. The list is configurable for future HTTPS deployments.
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure newly introduced durable tables exist when the API starts.
Base.metadata.create_all(bind=engine)

# Mission progress/history/control endpoints are kept in their own router so
# the mobile API surface can evolve without bloating this application module.
app.include_router(mission_api_router)
app.include_router(identity_api_router)
app.include_router(world_api_router)
app.include_router(economy_api_router)


# ============================================================
# REQUEST MODELS
# ============================================================

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None
    goal: Optional[str] = None
    task: Optional[str] = None
    project: Optional[str] = None
    context: Optional[dict[str, Any]] = None


class ExecuteRequest(BaseModel):
    goal: str
    session_id: Optional[str] = None
    max_steps: int = Field(default=20, ge=1, le=100)


class MemoryRequest(BaseModel):
    content: str
    memory_type: str = "general"
    importance: int = Field(default=5, ge=1, le=10)
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    source: str = "user"


class PermissionRequest(BaseModel):
    permission: str
    allowed: bool
