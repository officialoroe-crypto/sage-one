import socket
import threading
import time
import uuid

from app.orchestrator import orchestrator
from tasks.engine import tasks


class SageWorker:
    def __init__(self, worker_id=None, lease_seconds=120, heartbeat_interval=30, retry_base_seconds=10):
        self.name = 'SAGE WORKER'
        self.worker_id = worker_id or self._default_worker_id()
        self.lease_seconds = max(30, int(lease_seconds))
        self.heartbeat_interval = max(5, int(heartbeat_interval))
        self.retry_base_seconds = max(1, int(retry_base_seconds))

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
            return {
                'success': True,
                'result': result,
            }
        except Exception as error:
            return {
                'success': False,
                'error': str(error),
            }

    def recover_expired_tasks(self):
        return tasks.recover_expired()

    def claim(self):
        return tasks.claim_next(
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

    def execute_task(self, task):
        description = task['description']
        session_id = task.get('session_id')
        priority = task.get('priority', 3)
        task_id = task['id']

        stop_event, heartbeat_thread, heartbeat_state = self._start_heartbeat(task_id)

        try:
            if heartbeat_state['lost']:
                raise RuntimeError('Worker lost task ownership before execution started.')

            result = orchestrator.execute_goal(
                goal=description,
                session_id=session_id,
                priority=priority,
            )

            if heartbeat_state['lost']:
                raise RuntimeError('Worker lost task ownership during execution.')

            return result

        finally:
            stop_event.set()
            heartbeat_thread.join(timeout=max(1, self.heartbeat_interval + 1))

    def run_once(self):
        self.recover_expired_tasks()
        task = self.claim()
        if not task:
            return None

        task_id = task['id']

        try:
            result = self.execute_task(task)

            completed = tasks.complete_claim(
                task_id=task_id,
                worker_id=self.worker_id,
                result=str(result),
            )

            if completed is None:
                return {
                    'success': False,
                    'task': None,
                    'error': 'Worker lost task ownership before completion.',
                }

            return {
                'success': True,
                'task': completed,
            }

        except Exception as error:
            delay = self.retry_base_seconds * (2 ** max(0, task.get('retries', 0)))
            failed = tasks.fail_claim(
                task_id=task_id,
                worker_id=self.worker_id,
                error=str(error),
                retry_delay_seconds=delay,
            )
            return {
                'success': False,
                'task': failed,
                'error': str(error),
            }

    def run_forever(self, poll_interval=2.0):
        while True:
            result = self.run_once()
            if result is None:
                time.sleep(max(0.1, poll_interval))


worker = SageWorker()
