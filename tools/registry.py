from dataclasses import dataclass, field
from typing import Any, Callable

from tools.contracts import SIDE_EFFECT_CLASSES


@dataclass
class ToolDefinition:
    name: str
    description: str
    capability: str
    risk: str
    permission: str
    handler: Callable[..., Any]
    parameters: dict = field(default_factory=dict)
    output_schema: dict | None = None
    cost_policy: dict | None = None
    timeout_seconds: float | None = None
    retry_policy: dict | None = None
    verification_policy: dict | None = None
    audit_policy: dict | None = None
    side_effect_class: str = "READ_ONLY"


class ToolRegistry:
    def __init__(self):
        self._tools = {}

    def register(
        self,
        name: str,
        description: str,
        capability: str,
        risk: str,
        permission: str,
        handler: Callable[..., Any],
        parameters: dict | None = None,
        output_schema: dict | None = None,
        cost_policy: dict | None = None,
        timeout_seconds: float | None = None,
        retry_policy: dict | None = None,
        verification_policy: dict | None = None,
        audit_policy: dict | None = None,
        side_effect_class: str = "READ_ONLY",
    ):
        if name in self._tools:
            raise ValueError(f"Tool already registered: {name}")
        if side_effect_class not in SIDE_EFFECT_CLASSES:
            raise ValueError(
                f"Unsupported side_effect_class: {side_effect_class}"
            )
        if timeout_seconds is not None and timeout_seconds <= 0:
            raise ValueError("timeout_seconds must be positive.")
        self._tools[name] = ToolDefinition(
            name=name,
            description=description,
            capability=capability,
            risk=risk,
            permission=permission,
            handler=handler,
            parameters=parameters or {},
            output_schema=output_schema,
            cost_policy=cost_policy,
            timeout_seconds=timeout_seconds,
            retry_policy=retry_policy,
            verification_policy=verification_policy,
            audit_policy=audit_policy,
            side_effect_class=side_effect_class,
        )

    def get(self, name: str) -> ToolDefinition | None:
        return self._tools.get(name)

    def exists(self, name: str) -> bool:
        return name in self._tools

    def list(self):
        return [
            {
                "name": tool.name,
                "description": tool.description,
                "capability": tool.capability,
                "risk": tool.risk,
                "permission": tool.permission,
                "parameters": tool.parameters,
                "output_schema": tool.output_schema,
                "cost_policy": tool.cost_policy,
                "timeout_seconds": tool.timeout_seconds,
                "retry_policy": tool.retry_policy,
                "verification_policy": tool.verification_policy,
                "audit_policy": tool.audit_policy,
                "side_effect_class": tool.side_effect_class,
            }
            for tool in self._tools.values()
        ]

    def schemas(self):
        schemas = []
        for tool in self._tools.values():
            schemas.append(
                {
                    "type": "function",
                    "function": {
                        "name": tool.name,
                        "description": tool.description,
                        "parameters": {
                            "type": "object",
                            **tool.parameters,
                        },
                    },
                }
            )
        return schemas

    def execute(self, name: str, arguments: dict):
        tool = self.get(name)
        if not tool:
            raise ValueError(f"Unknown tool: {name}")
        return tool.handler(**arguments)


registry = ToolRegistry()


# Durable research retrieval is registered here so it becomes available to
# every API process that imports the central tool registry. This avoids a
# second execution path and keeps the retrieval layer reusable by mobile,
# desktop, and future agent surfaces.
from research.persistence import research_persistence


def _research_list(session_id: str | None = None, limit: int = 20):
    return research_persistence.list(session_id=session_id, limit=limit)


def _research_get(research_id: str):
    return research_persistence.get(research_id)


def _research_by_task(task_id: str):
    return research_persistence.get_by_task(task_id)


registry.register(
    name="research_list",
    description="List durable research report records, newest first.",
    capability="research_retrieval",
    risk="low",
    permission="research.read",
    handler=_research_list,
    parameters={
        "properties": {
            "session_id": {"type": "string"},
            "limit": {"type": "integer", "minimum": 1, "maximum": 100, "default": 20},
        },
    },
)

registry.register(
    name="research_get",
    description="Retrieve one complete durable research report including its evidence and citation graph.",
    capability="research_retrieval",
    risk="low",
    permission="research.read",
    handler=_research_get,
    parameters={
        "required": ["research_id"],
        "properties": {"research_id": {"type": "string"}},
    },
)

registry.register(
    name="research_by_task",
    description="Retrieve the durable research report associated with a background task.",
    capability="research_retrieval",
    risk="low",
    permission="research.read",
    handler=_research_by_task,
    parameters={
        "required": ["task_id"],
        "properties": {"task_id": {"type": "string"}},
    },
)


# ------------------------------------------------------------
# WORLD INTELLIGENCE TOOLS
# ------------------------------------------------------------
from world_intelligence import world_intelligence


def _world_status():
    return world_intelligence.status()


def _world_observe(topic: str, max_queries: int = 3, max_results_per_query: int = 4):
    return world_intelligence.observe(
        topic=topic,
        max_queries=max_queries,
        max_results_per_query=max_results_per_query,
    )


def _world_learn(topic: str, max_queries: int = 3, max_results_per_query: int = 4):
    return world_intelligence.learn(
        topic=topic,
        max_queries=max_queries,
        max_results_per_query=max_results_per_query,
    )


def _world_due():
    return {"success": True, "topics": world_intelligence.due()}


def _world_upgrade_proposal(
    title: str,
    reason: str,
    benefit: str,
    evidence: list[str] | None = None,
):
    return world_intelligence.propose_upgrade(
        title=title,
        reason=reason,
        benefit=benefit,
        evidence=evidence,
    )


registry.register(
    name="world_intelligence_status",
    description="Inspect SAGE ONE public-world learning status and stale knowledge topics.",
    capability="world.intelligence",
    risk="low",
    permission="world.read",
    handler=_world_status,
    parameters={"properties": {}},
)

registry.register(
    name="world_observe",
    description="Observe current public-world information using bounded web research without modifying SAGE.",
    capability="world.observe",
    risk="low",
    permission="world.observe",
    handler=_world_observe,
    parameters={
        "required": ["topic"],
        "properties": {
            "topic": {"type": "string"},
            "max_queries": {"type": "integer", "minimum": 1, "maximum": 5},
            "max_results_per_query": {"type": "integer", "minimum": 1, "maximum": 5},
        },
    },
)

registry.register(
    name="world_learn",
    description="Learn and persist source-backed public-world knowledge for SAGE ONE.",
    capability="world.learn",
    risk="low",
    permission="world.learn",
    handler=_world_learn,
    parameters={
        "required": ["topic"],
        "properties": {
            "topic": {"type": "string"},
            "max_queries": {"type": "integer", "minimum": 1, "maximum": 5},
            "max_results_per_query": {"type": "integer", "minimum": 1, "maximum": 5},
        },
    },
)

registry.register(
    name="world_due",
    description="List public-world knowledge topics that need a refresh.",
    capability="world.intelligence",
    risk="low",
    permission="world.read",
    handler=_world_due,
    parameters={"properties": {}},
)

registry.register(
    name="world_upgrade_proposal",
    description="Create a human-reviewable proposal for a SAGE ONE capability improvement; never self-modifies code.",
    capability="world.upgrade_proposal",
    risk="medium",
    permission="world.propose_upgrade",
    handler=_world_upgrade_proposal,
    parameters={
        "required": ["title", "reason", "benefit"],
        "properties": {
            "title": {"type": "string"},
            "reason": {"type": "string"},
            "benefit": {"type": "string"},
            "evidence": {"type": "array", "items": {"type": "string"}},
        },
    },
)


from events.service import event_store


def _execution_events(
    action_id: str | None = None,
    session_id: str | None = None,
    mission_id: str | None = None,
    task_id: str | None = None,
    event_type: str | None = None,
    limit: int = 100,
):
    return {
        "success": True,
        "events": event_store.list(
            action_id=action_id,
            session_id=session_id,
            mission_id=mission_id,
            task_id=task_id,
            event_type=event_type,
            limit=limit,
        ),
    }


registry.register(
    name="execution_events",
    description="Retrieve durable SAGE execution history correlated to an action, task, mission, or session.",
    capability="execution.history",
    risk="low",
    permission="task.read",
    handler=_execution_events,
    parameters={
        "properties": {
            "action_id": {"type": "string"},
            "session_id": {"type": "string"},
            "mission_id": {"type": "string"},
            "task_id": {"type": "string"},
            "event_type": {"type": "string"},
            "limit": {"type": "integer", "minimum": 1, "maximum": 500, "default": 100},
        },
    },
)


from automation.service import automation as durable_automation


def _automation_list(owner_key: str, enabled_only: bool = False, limit: int = 100):
    return {
        "success": True,
        "automations": durable_automation.list(
            owner_key=owner_key,
            enabled_only=enabled_only,
            limit=limit,
        ),
    }


def _automation_create(
    owner_key: str,
    name: str,
    goal: str,
    schedule_type: str = "once",
    run_at: str | None = None,
    interval_seconds: int | None = None,
    session_id: str | None = None,
    agent: str = "general",
    max_runs: int | None = None,
):
    from datetime import datetime

    parsed_run_at = (
        datetime.fromisoformat(run_at)
        if run_at
        else None
    )
    return {
        "success": True,
        "automation": durable_automation.create(
            owner_key=owner_key,
            name=name,
            goal=goal,
            schedule_type=schedule_type,
            run_at=parsed_run_at,
            interval_seconds=interval_seconds,
            session_id=session_id,
            agent=agent,
            max_runs=max_runs,
        ),
    }


def _automation_disable(owner_key: str, automation_id: str):
    result = durable_automation.disable(
        owner_key=owner_key,
        automation_id=automation_id,
    )
    return {
        "success": result is not None,
        "automation": result,
    }


registry.register(
    name="automation_list",
    description="List durable scheduled automations belonging to the owner.",
    capability="automation.read",
    risk="low",
    permission="automation.read",
    handler=_automation_list,
    parameters={
        "required": ["owner_key"],
        "properties": {
            "owner_key": {"type": "string"},
            "enabled_only": {"type": "boolean", "default": False},
            "limit": {"type": "integer", "minimum": 1, "maximum": 500, "default": 100},
        },
    },
)


registry.register(
    name="automation_create",
    description="Create a durable scheduled goal that will be dispatched into the normal task queue.",
    capability="automation.create",
    risk="medium",
    permission="automation.create",
    handler=_automation_create,
    parameters={
        "required": ["owner_key", "name", "goal"],
        "properties": {
            "owner_key": {"type": "string"},
            "name": {"type": "string"},
            "goal": {"type": "string"},
            "schedule_type": {"type": "string"},
            "run_at": {"type": "string"},
            "interval_seconds": {"type": "integer", "minimum": 60},
            "session_id": {"type": "string"},
            "agent": {"type": "string"},
            "max_runs": {"type": "integer", "minimum": 1},
        },
    },
)


registry.register(
    name="automation_disable",
    description="Disable one owner-owned durable automation.",
    capability="automation.create",
    risk="medium",
    permission="automation.create",
    handler=_automation_disable,
    parameters={
        "required": ["owner_key", "automation_id"],
        "properties": {
            "owner_key": {"type": "string"},
            "automation_id": {"type": "string"},
        },
    },
)
