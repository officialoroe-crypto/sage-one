from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class ExecutionMode(str, Enum):
    ONLINE = "online"
    OFFLINE = "offline"


@dataclass(frozen=True)
class ConnectivityState:
    online: bool
    reason: str = ""


class ExecutionModeRouter:
    """Select execution mode without making provider-specific decisions."""

    def select(self, connectivity: ConnectivityState) -> ExecutionMode:
        return (
            ExecutionMode.ONLINE
            if connectivity.online
            else ExecutionMode.OFFLINE
        )


mode_router = ExecutionModeRouter()
