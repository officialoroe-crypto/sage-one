from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import inspect
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session
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
        db: Session | None = None,
        commit: bool = True,
    ) -> str:
        event_id = str(uuid4())
        owns_session = db is None
        session = db or SessionLocal()
        try:
            bind = getattr(session, "bind", None)
            if bind is not None and not inspect(bind).has_table("execution_events"):
                return None

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
            session.add(row)
            if commit:
                session.commit()
            return event_id
        except OperationalError as error:
            session.rollback()
            if "no such table: execution_events" in str(error).lower():
                return None
            raise
        except Exception:
            session.rollback()
            raise
        finally:
            if owns_session:
                session.close()


event_store = SQLAlchemyEventStore()
