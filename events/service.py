from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4

from database.connection import SessionLocal
from database.models import ExecutionEvent


class SQLAlchemyEventStore:
    """Persist lifecycle events without owning business state."""

    def emit(
        self,
        *,
        event_type: str,
        action_id: str | None = None,
        session_id: str | None = None,
        mission_id: str | None = None,
        task_id: str | None = None,
        parent_action_id: str | None = None,
        status: str | None = None,
        source: str = "sage",
        payload: Any = None,
    ) -> str:
        event_id = str(uuid4())
        db = SessionLocal()
        try:
            row = ExecutionEvent(
                id=event_id,
                event_type=event_type,
                action_id=action_id,
                session_id=session_id,
                mission_id=mission_id,
                task_id=task_id,
                parent_action_id=parent_action_id,
                status=status,
                source=source,
                payload=(
                    json.dumps(payload, ensure_ascii=False, default=str)
                    if payload is not None
                    else None
                ),
                created_at=datetime.now(timezone.utc),
            )
            db.add(row)
            db.commit()
            return event_id
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()


event_store = SQLAlchemyEventStore()
