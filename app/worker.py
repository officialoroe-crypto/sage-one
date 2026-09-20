import socket
import threading
import time
import uuid

from app.orchestrator import orchestrator
from execution.engine import execution_engine
from execution.parallel import parallel_mission_executor
from execution.policy import classify_task, local_execution_allowed
from execution.resource import resource_guard
from missions.planner import planner
from research.persistence import research_persistence
from research.synthesis import research_synthesis_engine
from tasks.engine import tasks
from world_intelligence.engine import world_intelligence
from notifications.service import create_task_notification


class SageWorker:
    def __init__(self, worker_id=None, lease_seconds=120, heartbeat_interval=30, retry_base_seconds=10):
        self.name = 'SAGE WORKER'
        self.worker_id = worker_id or self._default_worker_id()
        self.lease_seconds = max(30, int(lease_seconds))
        self.heartbeat_interval = max(5, int(heartbeat_interval))
        self.retry_base_seconds = max(1, int(retry_base_seconds))
        self.resource_guard = resource_guard

    @staticmethod
    def _default_worker_id():
        host = socket.gethostname()
        return f'{host}-{uuid.uuid4().hex[:8]}'

    def run_goal(self, goal, session_id=None, priority=3):
        try:
            result = orchestrator.execute_goal(
                goal=goal,
                session_id=session_id,
                priority=priority,
            )
            return {'success': True, 'result': result}
        except Exception as error:
            return {'success': False, 'error': str(error)}

    def recover_expired_tasks(self):
        return tasks.recover_expired()

    def _local_execution_allowed(self):
        pending = tasks.list(status='pending')
        if not pending:
            return True, None

        snapshot = self.resource_guard.snapshot()
        task_class = classify_task(pending[0].get('description', ''))

        if local_execution_allowed(task_class, snapshot.cpu_percent):
            return True, None

        return False, {
            'status': 'deferred',
            'reason': 'local_resource_protection',
            'task_class': task_class.value,
            'cpu_percent': snapshot.cpu_percent,
            'resource_band': snapshot.band.value,
        }

    def claim(self):
        allowed, protection = self._local_execution_allowed()
        if not allowed:
            return protection

        # Only top-level tasks belong to the global durable worker queue.
        # Mission child tasks are owned by their mission execution loop.
        return tasks.claim_next_root(
            worker_id=self.worker_id,
            lease_seconds=self.lease_seconds,
        )

    def _heartbeat_loop(self, task_id, stop_event, state):
        while not stop_event.wait(self.heartbeat_interval):
            heartbeat = tasks.heartbeat(
                task_id=task_id,
                worker_id=self.worker_id,
                lease_seconds=self.lease_seconds,
            )
            if heartbeat is None:
                state['lost'] = True
                stop_event.set()
                return

    def _start_heartbeat(self, task_id):
        stop_event = threading.Event()
        state = {'lost': False}
        thread = threading.Thread(
            target=self._heartbeat_loop,
            args=(task_id, stop_event, state),
            name=f'sage-heartbeat-{task_id}',
            daemon=True,
        )
        thread.start()
        return stop_event, thread, state

    def _execute_task_payload(self, task):
        description = task['description']
        agent = task.get('agent', 'general')
        session_id = task.get('session_id')
        priority = task.get('priority', 3)

        # World Intelligence refreshes are durable background work. The worker
        # owns the task lease while the bounded public-world refresh executes.
        if agent == 'world':
            prefix = 'Refresh SAGE World Intelligence:'
            requested = description.removeprefix(prefix).strip()
            topics = [item.strip() for item in requested.split('|') if item.strip()]
            return world_intelligence.refresh(topics or None)

        # Research remains a first-class durable workload because its
        # specialized pipeline persists a citation/evidence graph separately
        # from the task row.
        if agent == 'research':
            result = research_synthesis_engine.synthesize(
                question=description.removeprefix('Research:').strip(),
            )
            if result.get('success'):
                persisted = research_persistence.save(
                    result,
                    task_id=task['id'],
                    session_id=session_id,
                )
                result = {
                    **result,
                    'research_id': persisted['research_id'],
                }
            return result

        # All other durable goals use the mission planner + dependency-aware
        # execution engine. Independent child tasks may execute concurrently;
        # dependent tasks are held until the next ready-task wave.
        plan = planner.plan(
            goal=description,
            session_id=session_id,
            priority=priority,
        )

        mission = plan.get('mission', {})
        mission_id = mission.get('id') if isinstance(mission, dict) else None
        if not mission_id:
            raise RuntimeError('Mission planner returned no mission ID.')

        execution = parallel_mission_executor.execute_mission(
            mission_id=mission_id,
            max_steps=20,
        )

        return {
            'success': execution.get('success', False),
            'mission_id': mission_id,
            'plan': plan,
            'execution': execution,
        }

    def execute_task(self, task):
        task_id = task['id']
        stop_event, heartbeat_thread, heartbeat_state = self._start_heartbeat(task_id)

        try:
            if heartbeat_state['lost']:
                raise RuntimeError('Worker lost task ownership before execution started.')

            result = self._execute_task_payload(task)

            if heartbeat_state['lost']:
                raise RuntimeError('Worker lost task ownership during execution.')

            if isinstance(result, dict) and result.get('success') is False:
                raise RuntimeError(
                    result.get('error')
                    or result.get('execution', {}).get('status', 'Mission execution failed.')
                )

            return result
        finally:
            stop_event.set()
            heartbeat_thread.join(timeout=max(1, self.heartbeat_interval + 1))

    def run_once(self):
        self.recover_expired_tasks()
        task = self.claim()

        if not task:
            return None

        if task.get('status') == 'deferred':
            return {
                'success': True,
                'task': None,
                **task,
            }

        task_id = task['id']

        try:
            result = self.execute_task(task)
            completed = tasks.complete_claim(
                task_id=task_id,
                worker_id=self.worker_id,
                result=str(result),
            )

            if completed is not None:
                try:
                    create_task_notification(completed, success=True)
                except Exception:
                    # Notification delivery must never turn a completed task into a failure.
                    pass

            if completed is None:
                return {
                    'success': False,
                    'task': None,
                    'error': 'Worker lost task ownership before completion.',
                }

            return {'success': True, 'task': completed}

        except Exception as error:
            delay = self.retry_base_seconds * (2 ** max(0, task.get('retries', 0)))
            failed = tasks.fail_claim(
                task_id=task_id,
                worker_id=self.worker_id,
                error=str(error),
                retry_delay_seconds=delay,
            )
            if failed is not None and failed.get('status') == 'failed':
                try:
                    create_task_notification(
                        failed,
                        success=False,
                        body=f"{failed.get('title', 'Background task')} failed: {str(error)}",
                    )
                except Exception:
                    # Notification delivery must never mask the terminal task failure.
                    pass
            return {
                'success': False,
                'task': failed,
                'error': str(error),
            }

    def run_forever(self, poll_interval=2.0):
        while True:
            result = self.run_once()
            if result is None or result.get('status') == 'deferred':
                time.sleep(max(0.1, poll_interval))


worker = SageWorker()
