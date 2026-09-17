from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any

from sqlalchemy.orm import Session as DBSession

from database.models import (
    Session,
    Message,
    Memory,
    Task,
    ActionLog,
)


class SageRepository:
    # ============================================================
    # DATETIME HELPERS
    # ============================================================

    @staticmethod
    def _utc_now() -> datetime:
        return datetime.now(timezone.utc)

    @staticmethod
    def _normalize_datetime(
        value: datetime | None,
    ) -> datetime | None:
        """
        Normalize database/application datetimes to UTC-aware
        datetimes before performing arithmetic.

        SQLite may return DateTime values without timezone information
        even when the application originally stored timezone-aware values.
        """

        if value is None:
            return None

        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)

        return value.astimezone(timezone.utc)

    @classmethod
    def _duration_ms(
        cls,
        started_at: datetime | None,
        completed_at: datetime | None,
    ) -> int | None:
        if not started_at or not completed_at:
            return None

        started = cls._normalize_datetime(started_at)
        completed = cls._normalize_datetime(completed_at)

        if started is None or completed is None:
            return None

        delta = completed - started

        return max(
            0,
            int(delta.total_seconds() * 1000),
        )

    # ============================================================
    # SESSIONS
    # ============================================================

    def create_session(
        self,
        db: DBSession,
    ) -> str:
        session_id = str(uuid.uuid4())

        session = Session(
            id=session_id,
            created_at=self._utc_now(),
        )

        db.add(session)
        db.commit()

        return session_id

    def get_session(
        self,
        db: DBSession,
        session_id: str,
    ) -> Session | None:
        return (
            db.query(Session)
            .filter(Session.id == session_id)
            .first()
        )

    # ============================================================
    # MESSAGES
    # ============================================================

    def add_message(
        self,
        db: DBSession,
        session_id: str,
        role: str,
        content: str,
    ) -> Message:
        message = Message(
            session_id=session_id,
            role=role,
            content=content,
            created_at=self._utc_now(),
        )

        db.add(message)
        db.commit()

        return message

    def get_messages(
        self,
        db: DBSession,
        session_id: str,
        limit: int = 10,
    ) -> list[Message]:
        return (
            db.query(Message)
            .filter(Message.session_id == session_id)
            .order_by(Message.created_at.desc())
            .limit(limit)
            .all()
        )

    # ============================================================
    # MEMORY
    # ============================================================

    def add_memory(
        self,
        db: DBSession,
        content: str,
        memory_type: str = "fact",
        importance: float = 0.5,
        confidence: float = 1.0,
        source: str = "conversation",
    ) -> Memory:
        existing = (
            db.query(Memory)
            .filter(Memory.content == content)
            .first()
        )

        if existing:
            return existing

        now = self._utc_now()

        memory = Memory(
            id=str(uuid.uuid4()),
            memory_type=memory_type,
            content=content,
            importance=importance,
            confidence=confidence,
            source=source,
            created_at=now,
            updated_at=now,
        )

        db.add(memory)
        db.commit()

        return memory

    def get_memories(
        self,
        db: DBSession,
        limit: int = 20,
    ) -> list[Memory]:
        return (
            db.query(Memory)
            .order_by(Memory.importance.desc())
            .limit(limit)
            .all()
        )

    # ============================================================
    # TASKS
    # ============================================================

    def create_task(
        self,
        db: DBSession,
        title: str,
        description: str,
        priority: int = 3,
        agent: str = "general",
        session_id: str | None = None,
        parent_task_id: str | None = None,
        max_retries: int = 3,
    ) -> Task:
        now = self._utc_now()

        task = Task(
            id=str(uuid.uuid4()),
            title=title,
            description=description,
            status="pending",
            priority=priority,
            agent=agent,
            session_id=session_id,
            parent_task_id=parent_task_id,
            progress=0,
            retries=0,
            max_retries=max_retries,
            created_at=now,
            updated_at=now,
        )

        db.add(task)
        db.commit()

        return task

    def get_task(
        self,
        db: DBSession,
        task_id: str,
    ) -> Task | None:
        return (
            db.query(Task)
            .filter(Task.id == task_id)
            .first()
        )

    def get_tasks(
        self,
        db: DBSession,
        status: str | None = None,
        limit: int = 100,
    ) -> list[Task]:
        query = db.query(Task)

        if status:
            query = query.filter(Task.status == status)

        return (
            query
            .order_by(
                Task.priority.asc(),
                Task.created_at.asc(),
            )
            .limit(limit)
            .all()
        )

    def update_task(
        self,
        db: DBSession,
        task_id: str,
        **updates: Any,
    ) -> Task | None:
        task = self.get_task(db, task_id)

        if not task:
            return None

        for key, value in updates.items():
            if hasattr(task, key):
                setattr(task, key, value)

        task.updated_at = self._utc_now()

        db.commit()

        return task

    # ============================================================
    # ACTION / EXECUTION LEDGER
    # ============================================================

    def create_action(
        self,
        db: DBSession,
        tool: str,
        permission: str,
        risk: str,
        capability: str | None = None,
        session_id: str | None = None,
        task_id: str | None = None,
        arguments: dict | None = None,
        permission_allowed: bool = False,
        permission_reason: str | None = None,
    ) -> ActionLog:
        action = ActionLog(
            id=str(uuid.uuid4()),
            session_id=session_id,
            task_id=task_id,
            tool=tool,
            capability=capability,
            permission=permission,
            risk=risk,
            arguments=(
                json.dumps(
                    arguments,
                    default=str,
                )
                if arguments is not None
                else None
            ),
            permission_allowed=(
                1 if permission_allowed else 0
            ),
            permission_reason=permission_reason,
            status=(
                "started"
                if permission_allowed
                else "denied"
            ),
            started_at=self._utc_now(),
        )

        db.add(action)
        db.commit()

        return action

    def complete_action(
        self,
        db: DBSession,
        action_id: str,
        result: Any = None,
    ) -> ActionLog | None:
        action = (
            db.query(ActionLog)
            .filter(ActionLog.id == action_id)
            .first()
        )

        if not action:
            return None

        now = self._utc_now()

        duration_ms = self._duration_ms(
            action.started_at,
            now,
        )

        action.status = "completed"

        action.result = json.dumps(
            result,
            default=str,
        )

        action.error = None
        action.completed_at = now
        action.duration_ms = duration_ms

        db.commit()

        return action

    def fail_action(
        self,
        db: DBSession,
        action_id: str,
        error: str,
    ) -> ActionLog | None:
        action = (
            db.query(ActionLog)
            .filter(ActionLog.id == action_id)
            .first()
        )

        if not action:
            return None

        now = self._utc_now()

        duration_ms = self._duration_ms(
            action.started_at,
            now,
        )

        action.status = "failed"
        action.error = str(error)
        action.completed_at = now
        action.duration_ms = duration_ms

        db.commit()

        return action

    def get_actions(
        self,
        db: DBSession,
        session_id: str | None = None,
        task_id: str | None = None,
        tool: str | None = None,
        status: str | None = None,
        limit: int = 100,
    ) -> list[ActionLog]:
        query = db.query(ActionLog)

        if session_id:
            query = query.filter(
                ActionLog.session_id == session_id
            )

        if task_id:
            query = query.filter(
                ActionLog.task_id == task_id
            )

        if tool:
            query = query.filter(
                ActionLog.tool == tool
            )

        if status:
            query = query.filter(
                ActionLog.status == status
            )

        return (
            query
            .order_by(ActionLog.started_at.desc())
            .limit(limit)
            .all()
        )


# ================================================================
# GLOBAL REPOSITORY INSTANCE
# ================================================================

repository = SageRepository()


# ================================================================
# MODULE-LEVEL COMPATIBILITY FUNCTIONS
#
# main.py and older modules can safely use:
#
#     repository.create_session(...)
#
# while newer code can use:
#
#     repository.repository.create_session(...)
#
# These wrappers intentionally delegate to the single repository
# instance above.
# ================================================================

def create_session(
    db: DBSession,
) -> str:
    return repository.create_session(db)


def get_session(
    db: DBSession,
    session_id: str,
) -> Session | None:
    return repository.get_session(db, session_id)


def add_message(
    db: DBSession,
    session_id: str,
    role: str,
    content: str,
) -> Message:
    return repository.add_message(
        db,
        session_id,
        role,
        content,
    )


def get_messages(
    db: DBSession,
    session_id: str,
    limit: int = 10,
) -> list[Message]:
    return repository.get_messages(
        db,
        session_id,
        limit,
    )


def add_memory(
    db: DBSession,
    content: str,
    memory_type: str = "fact",
    importance: float = 0.5,
    confidence: float = 1.0,
    source: str = "conversation",
) -> Memory:
    return repository.add_memory(
        db,
        content,
        memory_type,
        importance,
        confidence,
        source,
    )


def get_memories(
    db: DBSession,
    limit: int = 20,
) -> list[Memory]:
    return repository.get_memories(
        db,
        limit,
    )


def create_task(
    db: DBSession,
    title: str,
    description: str,
    priority: int = 3,
    agent: str = "general",
    session_id: str | None = None,
    parent_task_id: str | None = None,
    max_retries: int = 3,
) -> Task:
    return repository.create_task(
        db,
        title,
        description,
        priority,
        agent,
        session_id,
        parent_task_id,
        max_retries,
    )


def get_task(
    db: DBSession,
    task_id: str,
) -> Task | None:
    return repository.get_task(
        db,
        task_id,
    )


def get_tasks(
    db: DBSession,
    status: str | None = None,
    limit: int = 100,
) -> list[Task]:
    return repository.get_tasks(
        db,
        status,
        limit,
    )


def update_task(
    db: DBSession,
    task_id: str,
    **updates: Any,
) -> Task | None:
    return repository.update_task(
        db,
        task_id,
        **updates,
    )


def create_action(
    db: DBSession,
    tool: str,
    permission: str,
    risk: str,
    capability: str | None = None,
    session_id: str | None = None,
    task_id: str | None = None,
    arguments: dict | None = None,
    permission_allowed: bool = False,
    permission_reason: str | None = None,
) -> ActionLog:
    return repository.create_action(
        db,
        tool,
        permission,
        risk,
        capability,
        session_id,
        task_id,
        arguments,
        permission_allowed,
        permission_reason,
    )


def complete_action(
    db: DBSession,
    action_id: str,
    result: Any = None,
) -> ActionLog | None:
    return repository.complete_action(
        db,
        action_id,
        result,
    )


def fail_action(
    db: DBSession,
    action_id: str,
    error: str,
) -> ActionLog | None:
    return repository.fail_action(
        db,
        action_id,
        error,
    )


def get_actions(
    db: DBSession,
    session_id: str | None = None,
    task_id: str | None = None,
    tool: str | None = None,
    status: str | None = None,
    limit: int = 100,
) -> list[ActionLog]:
    return repository.get_actions(
        db,
        session_id,
        task_id,
        tool,
        status,
        limit,
    )