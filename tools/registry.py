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
