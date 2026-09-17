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

    parameters: dict = field(
        default_factory=dict
    )


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
        parameters: dict | None = None
    ):

        if name in self._tools:

            raise ValueError(
                f"Tool already registered: {name}"
            )

        self._tools[name] = ToolDefinition(

            name=name,

            description=description,

            capability=capability,

            risk=risk,

            permission=permission,

            handler=handler,

            parameters=parameters or {}
        )

    def get(
        self,
        name: str
    ) -> ToolDefinition | None:

        return self._tools.get(
            name
        )

    def exists(
        self,
        name: str
    ) -> bool:

        return name in self._tools

    def list(self):

        return [

            {
                "name":
                    tool.name,

                "description":
                    tool.description,

                "capability":
                    tool.capability,

                "risk":
                    tool.risk,

                "permission":
                    tool.permission,

                "parameters":
                    tool.parameters
            }

            for tool in
            self._tools.values()
        ]

    def schemas(self):

        schemas = []

        for tool in self._tools.values():

            schemas.append(

                {
                    "type":
                        "function",

                    "function":
                        {
                            "name":
                                tool.name,

                            "description":
                                tool.description,

                            "parameters":
                                {
                                    "type":
                                        "object",

                                    **tool.parameters
                                }
                        }
                }
            )

        return schemas

    def execute(
        self,
        name: str,
        arguments: dict
    ):

        tool = self.get(
            name
        )

        if not tool:

            raise ValueError(
                f"Unknown tool: {name}"
            )

        return tool.handler(
            **arguments
        )


registry = ToolRegistry()