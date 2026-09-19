from __future__ import annotations

import json
from typing import Any, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app.core import sage
from brain.router import router
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


# ============================================================
# APP
# ============================================================

app = FastAPI(
    title="SAGE ONE",
    version="6.0.0",
    description="SAGE ONE personal AI execution core",
)

# Ensure newly introduced durable tables exist when the API starts.
Base.metadata.create_all(bind=engine)

# Mission progress/history/control endpoints are kept in their own router so
# the mobile API surface can evolve without bloating this application module.
app.include_router(mission_api_router)


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


class MissionCreateRequest(BaseModel):
    goal: str
    priority: int = Field(default=3, ge=1, le=5)
    session_id: Optional[str] = None


class MissionPlanRequest(BaseModel):
    goal: str
    session_id: Optional[str] = None
    priority: int = Field(default=3, ge=1, le=5)


class MissionExecuteRequest(BaseModel):
    max_steps: int = Field(default=20, ge=1, le=100)


class TaskStatusRequest(BaseModel):
    result: Optional[str] = None
    error: Optional[str] = None


class TaskCreateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1, max_length=20000)
    priority: int = Field(default=3, ge=1, le=5)
    agent: str = Field(default="general", min_length=1, max_length=100)
    session_id: Optional[str] = None
    parent_task_id: Optional[str] = None


# ============================================================
# SERIALIZATION HELPERS
# ============================================================

def _serialize(value: Any) -> Any:
    """
    Convert common SAGE/SQLAlchemy/Pydantic objects into JSON-safe data.
    """

    if value is None:
        return None

    if isinstance(value, (str, int, float, bool)):
        return value

    if isinstance(value, dict):
        return {
            str(key): _serialize(item)
            for key, item in value.items()
            if key != "_sa_instance_state"
        }

    if isinstance(value, (list, tuple, set)):
        return [_serialize(item) for item in value]

    if hasattr(value, "model_dump"):
        try:
            return _serialize(value.model_dump())
        except Exception:
            pass

    if hasattr(value, "__dict__"):
        try:
            return {
                str(key): _serialize(item)
                for key, item in value.__dict__.items()
                if key != "_sa_instance_state"
            }
        except Exception:
            pass

    return str(value)


def _context_to_string(context: Optional[dict[str, Any]]) -> str:
    if not context:
        return ""

    try:
        return json.dumps(context, ensure_ascii=False)
    except Exception:
        return str(context)


# ============================================================
# ROOT
# ============================================================

@app.get("/")
def root():
    return {
        "name": "SAGE ONE",
        "version": "6.0.0",
        "status": "online",
        "architecture": "mission_planner_execution_verification_trace",
        "execution": "enabled",
        "trace": "enabled",
    }


@app.get("/orchestrator")
def orchestrator_status():
    return {
        "name": "SAGE ONE",
        "status": "online",
        "components": {
            "brain": True,
            "memory": True,
            "missions": True,
            "tasks": True,
            "execution": True,
            "verification": True,
            "permissions": True,
            "tools": True,
            "agents": True,
            "trace": True,
        },
    }


# ============================================================
# SESSION
# ============================================================

@app.post("/session")
def create_session():
    db = SessionLocal()

    try:
        session_id = repository.create_session(db)

        session = repository.get_session(db, session_id)

        if session is not None:
            return {
                "success": True,
                "session": _serialize(session),
            }

        return {
            "success": True,
            "session": {
                "id": str(session_id),
            },
        }

    finally:
        db.close()


@app.get("/session/{session_id}")
def get_session(session_id: str):
    db = SessionLocal()

    try:
        session = repository.get_session(db, session_id)

        if not session:
            raise HTTPException(
                status_code=404,
                detail="Session not found",
            )

        return {
            "success": True,
            "session": _serialize(session),
        }

    finally:
        db.close()


# ============================================================
# CHAT
# ============================================================

@app.post("/chat")
def chat(request: ChatRequest):
    try:
        context_parts = []

        if request.goal:
            context_parts.append(f"Current goal: {request.goal}")

        if request.task:
            context_parts.append(f"Current task: {request.task}")

        if request.project:
            context_parts.append(f"Current project: {request.project}")

        extra_context = _context_to_string(request.context)

        if extra_context:
            context_parts.append(f"Additional context: {extra_context}")

        context = "\n".join(context_parts)

        session_id = request.session_id

        if not session_id:
            db = SessionLocal()

            try:
                session_id = repository.create_session(db)
            finally:
                db.close()

        result = sage.handle(
            user_message=request.message,
            session_id=session_id,
            context=context,
        )

        return {
            "success": True,
            "session_id": session_id,
            "response": _serialize(result),
        }

    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


# ============================================================
# DIRECT EXECUTION
# ============================================================

@app.post("/execute")
def execute(request: ExecuteRequest):
    """
    High-level synchronous execution endpoint.

    Use /execute/background for durable work that must survive the
    HTTP request and be processed by the dedicated worker.
    """

    try:
        plan_result = planner.plan(
            goal=request.goal,
            session_id=request.session_id,
            priority=3,
        )

        plan_result = _serialize(plan_result)

        mission_id = None

        if isinstance(plan_result, dict):
            mission = plan_result.get("mission")

            if isinstance(mission, dict):
                mission_id = mission.get("id")

            if mission_id is None:
                mission_id = plan_result.get("mission_id")

        if mission_id is None:
            raise RuntimeError(
                "Planner completed but did not return a mission ID."
            )

        execution_result = execution_engine.execute_mission(
            mission_id=mission_id,
            max_steps=request.max_steps,
        )

        return {
            "success": True,
            "mission_id": mission_id,
            "plan": plan_result,
            "result": _serialize(execution_result),
        }

    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


@app.post("/execute/background")
def execute_background(request: ExecuteRequest):
    """Queue goal execution as a durable task for the background worker.

    The HTTP process does not perform the AI work. The task is persisted
    first, then the dedicated worker claims it, executes the goal, and stores
    the final result or failure on the task record.
    """

    agent_name = agents.choose(request.goal)
    if not agents.exists(agent_name):
        agent_name = "general"

    task = tasks.create(
        title=request.goal.strip()[:120],
        description=request.goal.strip(),
        priority=3,
        agent=agent_name,
        session_id=request.session_id,
    )

    return {
        "success": True,
        "status": "queued",
        "message": "Execution queued for the durable background worker.",
        "task": task,
    }


# ============================================================
# MEMORY
# ============================================================

@app.get("/memory")
def get_memory():
    db = SessionLocal()

    try:
        memories = repository.get_memories(db)

        return {
            "success": True,
            "memories": _serialize(memories),
        }

    finally:
        db.close()


@app.post("/memory")
def add_memory(request: MemoryRequest):
    db = SessionLocal()

    try:
        memory = repository.add_memory(
            db,
            content=request.content,
            memory_type=request.memory_type,
            importance=request.importance,
            confidence=request.confidence,
            source=request.source,
        )

        return {
            "success": True,
            "memory": _serialize(memory),
        }

    finally:
        db.close()


# ============================================================
# BRAIN
# ============================================================

@app.get("/brain/health")
def brain_health():
    return _serialize(router.health())


@app.get("/brain/routing")
def brain_routing(description: str):
    """Explain which provider strategy SAGE would use for a task."""
    try:
        return {
            "success": True,
            "routing": _serialize(router.routing(description)),
        }
    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


# ============================================================
# TOOLS
# ============================================================

@app.get("/tools")
def list_tools():
    return {
        "success": True,
        "tools": _serialize(registry.list()),
    }


@app.get("/tools/schemas")
def tool_schemas():
    return {
        "success": True,
        "schemas": _serialize(registry.schemas()),
    }


@app.post("/tools/execute")
def execute_tool(
    tool_name: str,
    arguments: Optional[str] = None,
):
    try:
        parsed_arguments: dict[str, Any] = {}

        if arguments:
            decoded = json.loads(arguments)
            if not isinstance(decoded, dict):
                raise ValueError("Tool arguments must be a JSON object.")
            parsed_arguments = decoded

        result = sage._execute_tool(
            tool_name,
            parsed_arguments,
        )

        if isinstance(result, dict) and result.get("success") is True:
            return {
                "success": True,
                "tool": tool_name,
                "result": _serialize(result.get("result")),
            }

        return {
            "success": False,
            "tool": tool_name,
            "error": result.get("error", "Tool execution failed.")
            if isinstance(result, dict)
            else "Tool execution failed.",
        }

    except Exception as exc:
        return {
            "success": False,
            "tool": tool_name,
            "error": str(exc),
        }

# ============================================================
# PERMISSIONS
# ============================================================

@app.get("/permissions")
def get_permissions():
    return {
        "success": True,
        "permissions": _serialize(
            permissions.get_permissions()
        ),
    }


@app.post("/permissions")
def set_permission(request: PermissionRequest):

    permissions.set_permission(
        request.permission,
        request.allowed,
    )

    return {
        "success": True,
        "permission": request.permission,
        "allowed": request.allowed,
    }


# ============================================================
# AUDIT
# ============================================================

@app.get("/audit")
def audit():
    db = SessionLocal()

    try:
        actions = repository.get_actions(db)

        return {
            "success": True,
            "actions": _serialize(actions),
        }

    finally:
        db.close()


@app.get("/audit/legacy")
def audit_legacy():
    return {
        "success": True,
        "audit": _serialize(permissions.audit()),
    }


# ============================================================
# TASKS
# ============================================================

@app.post("/tasks")
def create_background_task(request: TaskCreateRequest):
    task = tasks.create(
        title=request.title,
        description=request.description,
        priority=request.priority,
        agent=request.agent,
        session_id=request.session_id,
        parent_task_id=request.parent_task_id,
    )
    return {
        "success": True,
        "status": "queued",
        "task": task,
    }


@app.get("/tasks")
def get_tasks(status: Optional[str] = None):
    if status is not None and status not in tasks.VALID_STATUSES:
        raise HTTPException(status_code=400, detail="Invalid task status")

    return {
        "success": True,
        "tasks": tasks.list(status=status),
    }


@app.get("/tasks/{task_id}")
def get_task(task_id: str):
    task = tasks.get(task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return {
        "success": True,
        "task": task,
    }


@app.post("/tasks/{task_id}/cancel")
def cancel_task(task_id: str):
    task = tasks.cancel(task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return {
        "success": True,
        "task": task,
    }


# ============================================================
# MISSIONS
# ============================================================

@app.post("/missions")
def create_mission(request: MissionCreateRequest):

    mission = mission_engine.create_mission(
        goal=request.goal,
        priority=request.priority,
        session_id=request.session_id,
    )

    return {
        "success": True,
        "mission": _serialize(mission),
    }


@app.get("/missions/{mission_id}")
def get_mission(mission_id: str):

    mission = mission_engine.get_mission(mission_id)

    if not mission:
        raise HTTPException(
            status_code=404,
            detail="Mission not found",
        )

    return {
        "success": True,
        "mission": _serialize(mission),
    }


@app.post("/missions/plan")
def plan_mission(request: MissionPlanRequest):

    try:
        result = planner.plan(
            goal=request.goal,
            session_id=request.session_id,
            priority=request.priority,
        )

        return {
            "success": True,
            "plan": _serialize(result),
        }

    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


@app.get("/missions/{mission_id}/tasks")
def mission_tasks(mission_id: str):

    return {
        "success": True,
        "tasks": _serialize(
            mission_engine.get_tasks(mission_id)
        ),
    }


@app.get("/missions/{mission_id}/ready")
def mission_ready_tasks(mission_id: str):

    return {
        "success": True,
        "tasks": _serialize(
            mission_engine.get_ready_tasks(mission_id)
        ),
    }


@app.post("/missions/{mission_id}/tasks")
def create_mission_task(
    mission_id: str,
    title: str,
    description: str,
    agent: str = "general",
    priority: int = 3,
):

    task = mission_engine.create_task(
        mission_id=mission_id,
        title=title,
        description=description,
        agent=agent,
        priority=priority,
    )

    return {
        "success": True,
        "task": _serialize(task),
    }


# ============================================================
# MISSION TASK OPERATIONS
# ============================================================

@app.post("/missions/tasks/{task_id}/start")
def start_task(task_id: str):

    return {
        "success": True,
        "task": _serialize(
            mission_engine.start_task(task_id)
        ),
    }


@app.post("/missions/tasks/{task_id}/complete")
def complete_task(
    task_id: str,
    request: TaskStatusRequest,
):

    return {
        "success": True,
        "task": _serialize(
            mission_engine.complete_task(
                task_id,
                result=request.result,
            )
        ),
    }


@app.post("/missions/tasks/{task_id}/fail")
def fail_task(
    task_id: str,
    request: TaskStatusRequest,
):

    error = request.error or "Task failed."

    return {
        "success": True,
        "task": _serialize(
            mission_engine.fail_task(
                task_id,
                error=error,
            )
        ),
    }


@app.post("/missions/tasks/{task_id}/verify")
def verify_task(task_id: str):

    """
    Manual verification endpoint.

    The execution engine normally performs verification itself.
    This endpoint explicitly marks the task as passed using the
    mission engine's verification API.
    """

    result = mission_engine.verify_task(
        task_id,
        passed=True,
        evidence="Manually verified through SAGE ONE API.",
    )

    return {
        "success": True,
        "task": _serialize(result),
    }


# ============================================================
# MISSION REFRESH
# ============================================================

@app.post("/missions/{mission_id}/refresh")
def refresh_mission(mission_id: str):

    return {
        "success": True,
        "mission": _serialize(
            mission_engine.refresh_mission_status(
                mission_id
            )
        ),
    }


# ============================================================
# MISSION EXECUTION
# ============================================================

@app.post("/missions/{mission_id}/execute")
def execute_mission(
    mission_id: str,
    request: MissionExecuteRequest,
):

    try:
        result = execution_engine.execute_mission(
            mission_id=mission_id,
            max_steps=request.max_steps,
        )

        return _serialize(result)

    except Exception as exc:
        return {
            "success": False,
            "status": "failed",
            "mission_id": mission_id,
            "error": str(exc),
        }


@app.post("/missions/{mission_id}/execute-next")
def execute_next_task(
    mission_id: str,
):

    try:
        result = execution_engine.execute_next(
            mission_id
        )

        return _serialize(result)

    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


@app.post("/missions/tasks/{task_id}/execute")
def execute_single_task(
    task_id: str,
):

    try:
        result = execution_engine.execute_task(
            task_id
        )

        return _serialize(result)

    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


# ============================================================
# EXECUTION TRACE
# ============================================================

@app.get("/missions/{mission_id}/trace")
def get_mission_trace(
    mission_id: str,
):

    return _serialize(
        execution_trace.get_mission_trace(
            mission_id
        )
    )


@app.get("/missions/{mission_id}/result")
def get_mission_result(
    mission_id: str,
):

    return _serialize(
        execution_trace.get_mission_result(
            mission_id
        )
    )


@app.get("/missions/{mission_id}/trace/summary")
def get_trace_summary(
    mission_id: str,
):

    trace = execution_trace.get_mission_trace(
        mission_id
    )

    if not trace.get("success"):
        return trace

    return {
        "success": True,
        "mission_id": mission_id,
        "summary": _serialize(
            trace.get("summary")
        ),
    }


# ============================================================
# NOTIFICATIONS
# ============================================================

@app.get("/notifications")
def get_notifications(
    session_id: Optional[str] = None,
    unread_only: bool = False,
    limit: int = 50,
):
    return {
        "success": True,
        "notifications": list_notifications(
            session_id=session_id,
            unread_only=unread_only,
            limit=limit,
        ),
    }


@app.post("/notifications/{notification_id}/read")
def read_notification(notification_id: str):
    notification = mark_read(notification_id)
    if notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    return {"success": True, "notification": notification}


@app.post("/notifications/read-all")
def read_all_notifications(session_id: Optional[str] = None):
    return {
        "success": True,
        "marked_read": mark_all_read(session_id=session_id),
    }


# ============================================================
# AGENTS
# ============================================================

@app.get("/agents")
def list_agents():

    try:
        return {
            "success": True,
            "agents": _serialize(
                agents.list()
            ),
        }

    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


@app.get("/agents/{agent_name}")
def get_agent(agent_name: str):

    try:
        agent = agents.get(agent_name)

        if not agent:
            raise HTTPException(
                status_code=404,
                detail="Agent not found",
            )

        return {
            "success": True,
            "agent": _serialize(agent),
        }

    except HTTPException:
        raise

    except Exception as exc:
        return {
            "success": False,
            "error": str(exc),
        }


# ============================================================
# HEALTH
# ============================================================

@app.get("/health")
def health():

    return {
        "success": True,
        "service": "SAGE ONE",
        "version": "6.0.0",
        "status": "healthy",
    }
