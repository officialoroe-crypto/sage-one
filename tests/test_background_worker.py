from __future__ import annotations

from execution.resource import ResourceSnapshot
from workers.service import BackgroundWorker, WorkerConfig


class FakeGuard:
    def __init__(self, cpu_percent: float = 10.0):
        self.value = cpu_percent

    def snapshot(self):
        return ResourceSnapshot(
            cpu_percent=self.value,
            cpu_count=4,
            memory_percent=None,
            timestamp=0.0,
        )

    def should_stop(self, snapshot):
        return snapshot.cpu_percent >= 70.0


class FakeScheduler:
    max_workers = 2

    def __init__(self):
        self.submitted = []

    def submit(self, fn, task_id, *, task_id=None):
        identifier = task_id or task_id
        self.submitted.append(identifier)
        return identifier

    def status(self, task_id):
        return {
            "success": True,
            "status": "running",
        }


class FakeTasks:
    def __init__(self, pending):
        self.pending = pending

    def list(self, status=None):
        assert status == "pending"
        return list(self.pending)


def test_worker_dispatches_pending_tasks():
    scheduler = FakeScheduler()
    worker = BackgroundWorker(
        task_engine=FakeTasks([
            {"id": "task-1"},
            {"id": "task-2"},
            {"id": "task-3"},
        ]),
        execution_scheduler=scheduler,
        guard=FakeGuard(10.0),
        config=WorkerConfig(max_dispatch=2),
        task_executor=lambda task_id: task_id,
    )

    result = worker.dispatch_once()

    assert result["success"] is True
    assert result["status"] == "dispatched"
    assert result["dispatched"] == ["task-1", "task-2"]
    assert scheduler.submitted == ["task-1", "task-2"]


def test_worker_stops_dispatch_on_hard_cpu_limit():
    scheduler = FakeScheduler()
    worker = BackgroundWorker(
        task_engine=FakeTasks([{"id": "task-1"}]),
        execution_scheduler=scheduler,
        guard=FakeGuard(85.0),
        task_executor=lambda task_id: task_id,
    )

    result = worker.dispatch_once()

    assert result["success"] is True
    assert result["status"] == "throttled"
    assert result["dispatched"] == []
    assert scheduler.submitted == []


def test_worker_status_reports_stopped_state():
    worker = BackgroundWorker(
        task_engine=FakeTasks([]),
        execution_scheduler=FakeScheduler(),
        guard=FakeGuard(),
        task_executor=lambda task_id: task_id,
    )

    result = worker.status()

    assert result["success"] is True
    assert result["running"] is False
    assert result["in_flight"] == []
