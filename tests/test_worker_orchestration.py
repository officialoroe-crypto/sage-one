from database.connection import Base, SessionLocal, engine
from database.repository import repository
from app.worker import SageWorker
import app.worker as worker_module


def fresh_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def test_worker_passes_claimed_task_ownership_to_orchestrator(monkeypatch):
    fresh_db()

    db = SessionLocal()
    try:
        task = repository.create_task(
            db=db,
            title='Orchestration test',
            description='Execute this task',
            priority=1,
            max_retries=3,
        )
        task_id = task.id
    finally:
        db.close()

    worker = SageWorker(
        worker_id='worker-orchestration',
        lease_seconds=30,
        heartbeat_interval=30,
    )

    claimed = worker.claim()
    assert claimed is not None
    assert claimed['id'] == task_id

    captured = {}

    def fake_execute_goal(**kwargs):
        captured.update(kwargs)
        return {
            'success': True,
            'task_id': kwargs['task_id'],
            'worker_owned': True,
        }

    monkeypatch.setattr(worker_module.orchestrator, 'execute_goal', fake_execute_goal)

    result = worker.execute_task(claimed)

    assert result['task_id'] == task_id
    assert captured['task_id'] == task_id
    assert captured['worker_id'] == worker.worker_id
    assert captured['goal'] == claimed['description']
    assert captured['session_id'] == claimed.get('session_id')
    assert captured['priority'] == claimed.get('priority', 3)
