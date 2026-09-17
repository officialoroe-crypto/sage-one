from __future__ import annotations

from concurrent.futures import Future, ThreadPoolExecutor
from dataclasses import dataclass
from threading import Lock
from uuid import uuid4

from execution.resource import ResourceGuard, resource_guard


@dataclass(frozen=True)
class ScheduledTask:
    task_id: str
    priority: int


class ExecutionScheduler:
    """Small local scheduler with bounded concurrency and CPU protection.

    It deliberately does not persist work. Persistent task state remains the
    responsibility of the task/mission database layer.
    """

    def __init__(
        self,
        max_workers: int = 2,
        guard: ResourceGuard | None = None,
    ):
        if max_workers < 1:
            raise ValueError("max_workers must be at least 1")

        self.max_workers = max_workers
        self.guard = guard or resource_guard
        self._executor = ThreadPoolExecutor(max_workers=max_workers)
        self._lock = Lock()
        self._futures: dict[str, Future] = {}

    def submit(self, fn, *args, task_id: str | None = None, **kwargs) -> str:
        """Submit a callable if the local resource guard permits execution."""
        snapshot = self.guard.snapshot()
        if self.guard.should_stop(snapshot):
            raise RuntimeError(
                f"Local CPU protection active at {snapshot.cpu_percent:.1f}%"
            )

        identifier = task_id or str(uuid4())
        future = self._executor.submit(fn, *args, **kwargs)

        with self._lock:
            self._futures[identifier] = future

        return identifier

    def status(self, task_id: str) -> dict:
        with self._lock:
            future = self._futures.get(task_id)

        if future is None:
            return {"success": False, "error": "Task not found."}

        if future.cancelled():
            state = "cancelled"
        elif future.running():
            state = "running"
        elif future.done():
            state = "completed" if future.exception() is None else "failed"
        else:
            state = "pending"

        result = None
        error = None
        if future.done() and not future.cancelled():
            try:
                result = future.result()
            except Exception as exc:
                error = str(exc)

        return {
            "success": True,
            "task_id": task_id,
            "status": state,
            "result": result,
            "error": error,
        }

    def cancel(self, task_id: str) -> bool:
        with self._lock:
            future = self._futures.get(task_id)
        return bool(future and future.cancel())

    def shutdown(self, wait: bool = True) -> None:
        self._executor.shutdown(wait=wait, cancel_futures=True)


scheduler = ExecutionScheduler()
