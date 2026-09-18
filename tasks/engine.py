from datetime import datetime, timezone

from database.connection import SessionLocal
from database.repository import repository


class TaskEngine:

    VALID_STATUSES = {
        "pending",
        "running",
        "paused",
        "completed",
        "failed",
        "cancelled",
    }

    def create(
        self,
        title: str,
        description: str,
        priority: int = 3,
        agent: str = "general",
        session_id: str | None = None,
        parent_task_id: str | None = None,
    ):
        priority = max(1, min(priority, 5))
        db = SessionLocal()

        try:
            task = repository.create_task(
                db=db,
                title=title,
                description=description,
                priority=priority,
                agent=agent,
                session_id=session_id,
                parent_task_id=parent_task_id,
            )
            return self.serialize(task)
        finally:
            db.close()

    def get(self, task_id: str):
        db = SessionLocal()
        try:
            task = repository.get_task(db, task_id)
            return self.serialize(task) if task else None
        finally:
            db.close()

    def list(self, status: str | None = None):
        db = SessionLocal()
        try:
            tasks = repository.get_tasks(db, status=status)
            return [self.serialize(task) for task in tasks]
        finally:
            db.close()

    def claim_next(
        self,
        worker_id: str,
        lease_seconds: int = 120,
    ):
        db = SessionLocal()
        try:
            task = repository.claim_next_task(
                db,
                worker_id,
                lease_seconds,
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def heartbeat(
        self,
        task_id: str,
        worker_id: str,
        lease_seconds: int = 120,
    ):
        db = SessionLocal()
        try:
            task = repository.heartbeat_task(
                db,
                task_id,
                worker_id,
                lease_seconds,
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def start(self, task_id: str):
        db = SessionLocal()
        try:
            task = repository.update_task(
                db,
                task_id,
                status="running",
                progress=0,
                started_at=datetime.now(timezone.utc),
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def progress(self, task_id: str, progress: int):
        progress = max(0, min(progress, 100))
        db = SessionLocal()
        try:
            task = repository.update_task(
                db,
                task_id,
                progress=progress,
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def complete(self, task_id: str, result: str):
        db = SessionLocal()
        try:
            task = repository.update_task(
                db,
                task_id,
                status="completed",
                progress=100,
                result=result,
                error=None,
                completed_at=datetime.now(timezone.utc),
                worker_id=None,
                lease_expires_at=None,
                heartbeat_at=datetime.now(timezone.utc),
                next_retry_at=None,
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def complete_claim(
        self,
        task_id: str,
        worker_id: str,
        result: str,
    ):
        db = SessionLocal()
        try:
            task = repository.complete_task_claim(
                db,
                task_id,
                worker_id,
                result,
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def fail(self, task_id: str, error: str):
        db = SessionLocal()
        try:
            task = repository.get_task(db, task_id)
            if not task:
                return None

            new_retries = task.retries + 1
            status = (
                "pending"
                if new_retries < task.max_retries
                else "failed"
            )

            task = repository.update_task(
                db,
                task_id,
                status=status,
                retries=new_retries,
                error=error,
            )
            return self.serialize(task)
        finally:
            db.close()

    def fail_claim(
        self,
        task_id: str,
        worker_id: str,
        error: str,
        retry_delay_seconds: int,
    ):
        db = SessionLocal()
        try:
            task = repository.fail_task_claim(
                db,
                task_id,
                worker_id,
                error,
                retry_delay_seconds,
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def recover_expired(self):
        db = SessionLocal()
        try:
            return repository.recover_expired_tasks(db)
        finally:
            db.close()

    def cancel(self, task_id: str):
        db = SessionLocal()
        try:
            task = repository.update_task(
                db,
                task_id,
                status="cancelled",
                worker_id=None,
                lease_expires_at=None,
            )
            return self.serialize(task) if task else None
        finally:
            db.close()

    def serialize(self, task):
        return {
            "id": task.id,
            "title": task.title,
            "description": task.description,
            "status": task.status,
            "priority": task.priority,
            "agent": task.agent,
            "session_id": task.session_id,
            "parent_task_id": task.parent_task_id,
            "mission_id": task.mission_id,
            "depends_on": task.depends_on,
            "progress": task.progress,
            "result": task.result,
            "error": task.error,
            "retries": task.retries,
            "max_retries": task.max_retries,
            "verification_status": task.verification_status,
            "worker_id": task.worker_id,
            "lease_expires_at": task.lease_expires_at.isoformat() if task.lease_expires_at else None,
            "heartbeat_at": task.heartbeat_at.isoformat() if task.heartbeat_at else None,
            "next_retry_at": task.next_retry_at.isoformat() if task.next_retry_at else None,
            "created_at": task.created_at.isoformat() if task.created_at else None,
            "updated_at": task.updated_at.isoformat() if task.updated_at else None,
            "started_at": task.started_at.isoformat() if task.started_at else None,
            "completed_at": task.completed_at.isoformat() if task.completed_at else None,
        }


tasks = TaskEngine()
