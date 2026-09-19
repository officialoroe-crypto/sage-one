import time

import pytest

from database.connection import Base, SessionLocal, engine
from database.repository import repository
from app.worker import SageWorker
import app.worker as worker_module


def fresh_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def make_worker_task(worker_id):
    db = SessionLocal()
    try:
        task = repository.create_task(
            db=db,
            title='Heartbeat test',
            description='Heartbeat test task',
            priority=1,
            max_retries=3,
        )
        task_id = task.id
    finally:
        db.close()

    worker = SageWorker(
        worker_id=worker_id,
        lease_seconds=30,
        heartbeat_interval=5,
    )
    worker.heartbeat_interval = 0.05

    claimed = worker.claim()
    assert claimed is not None
    assert claimed['id'] == task_id
    return worker, claimed


def patch_mission_execution(monkeypatch, delay=0.20):
    def plan(**kwargs):
        return {'mission': {'id': 'mission-heartbeat'}}

    def execute_mission(**kwargs):
        time.sleep(delay)
        return {'success': True, 'status': 'completed'}

    monkeypatch.setattr(worker_module.planner, 'plan', plan)
    monkeypatch.setattr(worker_module.execution_engine, 'execute_mission', execute_mission)


def test_heartbeat_runs_during_long_execution(monkeypatch):
    fresh_db()
    worker, task = make_worker_task('worker-heartbeat')

    heartbeat_calls = []
    original_heartbeat = worker_module.tasks.heartbeat

    def heartbeat(*args, **kwargs):
        heartbeat_calls.append(kwargs)
        return original_heartbeat(*args, **kwargs)

    monkeypatch.setattr(worker_module.tasks, 'heartbeat', heartbeat)
    patch_mission_execution(monkeypatch)

    result = worker.execute_task(task)

    assert result['success'] is True
    assert result['mission_id'] == 'mission-heartbeat'
    assert len(heartbeat_calls) >= 2


def test_worker_detects_lost_ownership_during_execution(monkeypatch):
    fresh_db()
    worker, task = make_worker_task('worker-lost')

    heartbeat_calls = 0

    def lost_heartbeat(*args, **kwargs):
        nonlocal heartbeat_calls
        heartbeat_calls += 1
        return None

    monkeypatch.setattr(worker_module.tasks, 'heartbeat', lost_heartbeat)
    patch_mission_execution(monkeypatch, delay=0.12)

    with pytest.raises(RuntimeError, match='lost task ownership'):
        worker.execute_task(task)

    assert heartbeat_calls >= 1
