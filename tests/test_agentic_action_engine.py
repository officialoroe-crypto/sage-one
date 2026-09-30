from dataclasses import dataclass
from typing import Any

from agentic.engine import AgenticActionEngine
from agentic.models import ActionRequest
from permissions.engine import PermissionEngine
from tools.registry import ToolRegistry


@dataclass
class FakeLog:
    action_id: str
    status: str
    error: str | None = None
    result: Any = None


class FakeLogStore:
    def __init__(self) -> None:
        self.rows: dict[str, FakeLog] = {}
        self.starts = 0
        self.finishes = 0

    def start(self, **kwargs) -> str:
        self.starts += 1
        action_id = kwargs["action_id"]
        self.rows[action_id] = FakeLog(action_id, "started")
        return action_id

    def finish(self, **kwargs) -> None:
        self.finishes += 1
        row = self.rows[kwargs["action_id"]]
        row.status = kwargs["status"]
        row.error = kwargs.get("error")
        row.result = kwargs.get("result")


def build_engine(handler, *, permission="tool.execute", risk="low"):
    registry = ToolRegistry()
    registry.register(
        name="demo_tool",
        description="Test tool.",
        capability="test.execute",
        risk=risk,
        permission=permission,
        handler=handler,
        parameters={
            "required": ["name"],
            "properties": {
                "name": {"type": "string"},
            },
        },
    )
    permissions = PermissionEngine()
    logs = FakeLogStore()
    return AgenticActionEngine(
        registry=registry,
        permission_engine=permissions,
        log_store=logs,
    ), logs


def test_allowed_action_executes_and_is_verified():
    calls = []

    def handler(name: str):
        calls.append(name)
        return {"success": True, "message": f"Hello {name}"}

    engine, logs = build_engine(handler)

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={"name": "SAGE"},
            owner_authorized=True,
        )
    )

    assert result.success is True
    assert result.status == "completed"
    assert result.verification_status == "passed"
    assert result.result["message"] == "Hello SAGE"
    assert calls == ["SAGE"]
    assert logs.starts == 1
    assert logs.finishes == 1


def test_owner_authorization_is_fail_closed():
    calls = []

    def handler(name: str):
        calls.append(name)
        return {"success": True}

    engine, logs = build_engine(handler)

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={"name": "SAGE"},
            owner_authorized=False,
        )
    )

    assert result.success is False
    assert result.status == "denied"
    assert "owner" in result.permission_reason.lower()
    assert calls == []
    assert logs.finishes == 1


def test_disabled_permission_denies_before_execution():
    calls = []

    def handler(name: str):
        calls.append(name)
        return {"success": True}

    engine, logs = build_engine(
        handler,
        permission="file.write",
        risk="low",
    )

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={"name": "SAGE"},
            owner_authorized=True,
        )
    )

    assert result.success is False
    assert result.status == "denied"
    assert calls == []
    assert logs.finishes == 1


def test_risk_above_autonomous_limit_denies():
    calls = []

    def handler(name: str):
        calls.append(name)
        return {"success": True}

    engine, logs = build_engine(
        handler,
        permission="memory.write",
        risk="high",
    )

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={"name": "SAGE"},
            owner_authorized=True,
        )
    )

    assert result.success is False
    assert result.status == "denied"
    assert "risk" in result.permission_reason.lower()
    assert calls == []
    assert logs.finishes == 1


def test_unknown_tool_is_denied_and_never_called():
    engine, logs = build_engine(lambda name: {"success": True})

    result = engine.execute(
        ActionRequest(
            tool_name="does_not_exist",
            arguments={},
            owner_authorized=True,
        )
    )

    assert result.success is False
    assert result.status == "denied"
    assert result.permission == "unknown"
    assert logs.finishes == 1


def test_invalid_arguments_are_rejected_before_handler():
    calls = []

    def handler(name: str):
        calls.append(name)
        return {"success": True}

    engine, logs = build_engine(handler)

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={},
            owner_authorized=True,
        )
    )

    assert result.success is False
    assert result.status == "invalid_arguments"
    assert "required argument" in result.error.lower()
    assert calls == []
    assert logs.finishes == 1


def test_argument_type_is_validated():
    calls = []

    def handler(name: str):
        calls.append(name)
        return {"success": True}

    engine, logs = build_engine(handler)

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={"name": 123},
            owner_authorized=True,
        )
    )

    assert result.success is False
    assert result.status == "invalid_arguments"
    assert "type string" in result.error.lower()
    assert calls == []
    assert logs.finishes == 1


def test_handler_exception_is_captured_and_logged():
    def handler(name: str):
        raise RuntimeError("boom")

    engine, logs = build_engine(handler)

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={"name": "SAGE"},
            owner_authorized=True,
        )
    )

    assert result.success is False
    assert result.status == "failed"
    assert "RuntimeError: boom" in result.error
    assert result.verification_status == "failed"
    assert logs.rows[result.action_id].status == "failed"


def test_tool_reported_failure_is_not_marked_success():
    def handler(name: str):
        return {"success": False, "error": "not completed"}

    engine, logs = build_engine(handler)

    result = engine.execute(
        ActionRequest(
            tool_name="demo_tool",
            arguments={"name": "SAGE"},
            owner_authorized=True,
        )
    )

    assert result.success is False
    assert result.status == "failed"
    assert result.verification_status == "failed"
    assert "not completed" in result.error
    assert logs.rows[result.action_id].status == "failed"
