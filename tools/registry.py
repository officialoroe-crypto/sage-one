from dataclasses import dataclass, field
from typing import Any, Callable


@dataclass
class ToolDefinition:
    name: str
    description: str
    capability: str
    risk: str
    permission: str
    handler: Callable[..., Any]
    parameters: dict = field(default_factory=dict)


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
    ):
        if name in self._tools:
            raise ValueError(f"Tool already registered: {name}")
        self._tools[name] = ToolDefinition(
            name=name,
            description=description,
            capability=capability,
            risk=risk,
            permission=permission,
            handler=handler,
            parameters=parameters or {},
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
