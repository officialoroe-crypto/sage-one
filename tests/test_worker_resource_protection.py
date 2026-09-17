from app.worker import SageWorker
from execution.resource import ResourceSnapshot


def test_worker_defers_pending_work_when_local_cpu_is_too_high(monkeypatch):
    worker = SageWorker(worker_id='test-worker')

    monkeypatch.setattr(
        worker.resource_guard,
        'snapshot',
        lambda: ResourceSnapshot(75.0, 60.0, 4, 0.0),
    )
    monkeypatch.setattr(
        'app.worker.tasks.list',
        lambda status=None: [
            {'id': 'task-1', 'description': 'deep research on a topic'}
        ],
    )
    monkeypatch.setattr(
        'app.worker.tasks.claim_next',
        lambda **kwargs: (_ for _ in ()).throw(AssertionError('task should not be claimed')),
    )

    result = worker.claim()

    assert result['status'] == 'deferred'
    assert result['reason'] == 'local_resource_protection'
    assert result['task_class'] == 'heavy'
    assert result['cpu_percent'] == 75.0
