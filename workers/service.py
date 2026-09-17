from __future__ import annotations

from dataclasses import dataclass
from threading import Event, Lock, Thread
import time
from typing import Any, Callable

from execution.resource import ResourceGuard, resource_guard
from execution.scheduler import ExecutionScheduler, scheduler
from tasks.engine import TaskEngine, tasks


@dataclass(frozen=True)
class WorkerConfig:
    poll_interval: float = 2.0
    max_dispatch: int = 2

    def __post_init__(self) -> None:
        if self.poll_interval <= 0:
            raise ValueError("poll_interval must be greater than zero")
        if self.max_dispatch < 1:
            raise ValueError("max_dispatch must be at least 1")


class BackgroundWorker:
    """Persistent task worker backed by SAGE's database task state.

    The worker only dispatches persisted pending tasks. Execution itself is
    bounded by the local scheduler/resource guard, and task state survives
    process restarts because the authoritative status lives in the database.
    """

    def __init__(
        self,
        task_engine: TaskEngine | None = None,
        execution_scheduler: ExecutionScheduler | None = None,
        guard: ResourceGuard | None = None,
        config: WorkerConfig | None = None,
        task_executor: Callable[[str], Any] | None = None,
    ) -> None:
        self.tasks = task_engine or tasks
        self.scheduler = execution_scheduler or scheduler
        self.guard = guard or resource_guard
        self.config = config or WorkerConfig()
        self.task_executor = task_executor or self._execute_task
        self._stop_event = Event()
        self._thread: Thread | None = None
        self._lock = Lock()
        self._in_flight: set[str] = set()

    def _execute_task(self, task_id: str) -> Any:
        # Import lazily so worker infrastructure can be unit-tested without
        # constructing the full execution stack at import time.
        from execution.engine import execution_engine

        return execution_engine.execute_task(task_id)

    def _cleanup_finished(self) -> None:
        finished: list[str] = []

        with self._lock:
            for task_id in self._in_flight:
                state = self.scheduler.status(task_id)
                if not state.get("success") or state.get("status") in {
                    "completed",
                    "failed",
                    "cancelled",
                }:
                    finished.append(task_id)

            for task_id in finished:
                self._in_flight.discard(task_id)

    def dispatch_once(self) -> dict[str, Any]:
        """Dispatch available pending tasks once and return a truthful summary."""
        self._cleanup_finished()

        snapshot = self.guard.snapshot()
        if self.guard.should_stop(snapshot):
            return {
                "success": True,
                "status": "throttled",
                "dispatched": [],
                "cpu_percent": snapshot.cpu_percent,
                "reason": "Local CPU hard limit reached.",
            }

        capacity = max(
            0,
            min(
                self.config.max_dispatch,
                self.scheduler.max_workers,
            )
            - len(self._in_flight),
        )

        if capacity == 0:
            return {
                "success": True,
                "status": "at_capacity",
                "dispatched": [],
                "cpu_percent": snapshot.cpu_percent,
            }

        pending = self.tasks.list(status="pending")
        dispatched: list[str] = []

        for task in pending:
            task_id = str(task.get("id", ""))
            if not task_id:
                continue

            with self._lock:
                if task_id in self._in_flight:
                    continue

            try:
                scheduler_id = self.scheduler.submit(
                    self.task_executor,
                    task_id,
                    task_id=task_id,
                )
            except RuntimeError:
                break

            with self._lock:
                self._in_flight.add(scheduler_id)
            dispatched.append(scheduler_id)

            if len(dispatched) >= capacity:
                break

        return {
            "success": True,
            "status": "dispatched" if dispatched else "idle",
            "dispatched": dispatched,
            "in_flight": len(self._in_flight),
            "cpu_percent": snapshot.cpu_percent,
        }

    def run_once(self) -> dict[str, Any]:
        return self.dispatch_once()

    def run_forever(self) -> None:
        self._stop_event.clear()
        while not self._stop_event.is_set():
            self.dispatch_once()
            self._stop_event.wait(self.config.poll_interval)

    def start(self) -> bool:
        with self._lock:
            if self._thread and self._thread.is_alive():
                return False
            self._stop_event.clear()
            self._thread = Thread(
                target=self.run_forever,
                name="sage-background-worker",
                daemon=True,
            )
            self._thread.start()
            return True

    def stop(self, wait: bool = True) -> bool:
        self._stop_event.set()
        thread = self._thread
        if thread and wait and thread.is_alive():
            thread.join(timeout=max(1.0, self.config.poll_interval + 1.0))
        return True

    def status(self) -> dict[str, Any]:
        self._cleanup_finished()
        thread = self._thread
        return {
            "success": True,
            "running": bool(thread and thread.is_alive()),
            "in_flight": sorted(self._in_flight),
            "poll_interval": self.config.poll_interval,
            "max_dispatch": self.config.max_dispatch,
        }


worker = BackgroundWorker()
