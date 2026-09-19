from app.worker import SageWorker


def test_research_agent_uses_research_pipeline(monkeypatch):
    captured = {}

    def synthesize(**kwargs):
        captured.update(kwargs)
        return {
            'success': True,
            'question': kwargs['question'],
            'claim_count': 2,
        }

    def fail_orchestrator(*args, **kwargs):
        raise AssertionError('research tasks must not use the generic orchestrator path')

    monkeypatch.setattr(
        'app.worker.research_synthesis_engine.synthesize',
        synthesize,
    )
    monkeypatch.setattr(
        'app.worker.orchestrator.execute_goal',
        fail_orchestrator,
    )

    worker = SageWorker(worker_id='test-worker')
    result = worker._execute_task_payload({
        'id': 'research-task-1',
        'description': 'Research: latest battery technology',
        'agent': 'research',
        'session_id': 'session-1',
        'priority': 3,
    })

    assert result['success'] is True
    assert result['claim_count'] == 2
    assert captured == {
        'question': 'latest battery technology',
    }


def test_non_research_agent_keeps_orchestrator_path(monkeypatch):
    captured = {}

    def execute_goal(**kwargs):
        captured.update(kwargs)
        return {'success': True, 'final': 'done'}

    monkeypatch.setattr(
        'app.worker.orchestrator.execute_goal',
        execute_goal,
    )

    worker = SageWorker(worker_id='test-worker')
    result = worker._execute_task_payload({
        'id': 'general-task-1',
        'description': 'Plan my next action',
        'agent': 'general',
        'session_id': 'session-1',
        'priority': 4,
    })

    assert result['success'] is True
    assert captured == {
        'goal': 'Plan my next action',
        'session_id': 'session-1',
        'priority': 4,
        'task_id': 'general-task-1',
        'worker_id': 'test-worker',
    }
