"""User-facing mission progress events.

Events are intentionally lightweight and execution-scoped. Durable task and
mission tables remain the source of truth; callers can surface these events in
mobile/desktop clients or bridge them to a persistent event store later.
"""

from datetime import datetime, timezone


class MissionProgress:
    """Collect deterministic progress events for one mission execution."""

    def __init__(self, mission_id: str):
        self.mission_id = mission_id
        self._events: list[dict] = []

    @staticmethod
    def _now():
        return datetime.now(timezone.utc).isoformat()

    def emit(
        self,
        event_type: str,
        status: str,
        message: str,
        *,
        wave: int = 0,
        task_ids: list[str] | None = None,
        progress_percent: float = 0,
    ) -> dict:
        event = {
            "sequence": len(self._events) + 1,
            "mission_id": self.mission_id,
            "event_type": event_type,
            "status": status,
            "message": message,
            "wave": wave,
            "task_ids": sorted(task_ids or []),
            "progress_percent": round(float(progress_percent), 2),
            "created_at": self._now(),
        }
        self._events.append(event)
        return event

    def snapshot(self) -> list[dict]:
        return list(self._events)
