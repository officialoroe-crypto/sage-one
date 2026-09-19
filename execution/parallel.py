"""Dependency-aware parallel mission execution.

Mission child tasks are not placed on the global durable worker queue.  This
executor owns a mission's ready-task waves and runs independent tasks in
parallel while asking the mission engine for a fresh dependency-aware ready
set after every wave.
"""

from concurrent.futures import ThreadPoolExecutor, as_completed

from execution.engine import ExecutionEngine
from missions.engine import mission_engine


class ParallelMissionExecutor:
    """Execute independent mission tasks concurrently in dependency waves."""

    def __init__(self, max_parallel: int = 2, engine_factory=ExecutionEngine):
        self.max_parallel = max(1, int(max_parallel))
        self.engine_factory = engine_factory

    def _execute_task(self, task_id: str):
        # ExecutionEngine keeps per-run evidence on the instance.  A separate
        # engine per child task prevents concurrent tasks from sharing that
        # mutable evidence buffer.
        engine = self.engine_factory()
        return engine.execute_task(task_id)

    @staticmethod
    def _summary(mission_id: str, history: list[dict]) -> dict:
        tasks = mission_engine.get_tasks(mission_id)
        total = len(tasks)
        verified = sum(
            1
            for task in tasks
            if task.get("status") == "completed"
            and task.get("verification_status") == "verified"
        )
        running = sum(1 for task in tasks if task.get("status") == "running")
        failed = sum(1 for task in tasks if task.get("status") == "failed")
        pending = sum(1 for task in tasks if task.get("status") == "pending")

        return {
            "total_tasks": total,
            "verified_tasks": verified,
            "running_tasks": running,
            "failed_tasks": failed,
            "pending_tasks": pending,
            "progress_percent": round((verified / total) * 100, 2) if total else 0,
            "completed_task_ids": [
                task["id"]
                for task in tasks
                if task.get("status") == "completed"
                and task.get("verification_status") == "verified"
            ],
            "failed_task_ids": [
                task["id"] for task in tasks if task.get("status") == "failed"
            ],
            "history_count": len(history),
        }

    def execute_mission(self, mission_id: str, max_steps: int = 20) -> dict:
        history: list[dict] = []
        waves = 0

        while len(history) < max_steps:
            mission = mission_engine.refresh_mission_status(mission_id)

            if mission["status"] == "completed":
                return {
                    "success": True,
                    "status": "completed",
                    "mission": mission,
                    "summary": self._summary(mission_id, history),
                    "history": history,
                    "waves": waves,
                }

            if mission["status"] == "failed":
                return {
                    "success": False,
                    "status": "failed",
                    "mission": mission,
                    "summary": self._summary(mission_id, history),
                    "history": history,
                    "waves": waves,
                }

            ready = mission_engine.get_ready_tasks(mission_id)
            if not ready:
                mission = mission_engine.refresh_mission_status(mission_id)
                return {
                    "success": False,
                    "status": "blocked",
                    "mission": mission,
                    "summary": self._summary(mission_id, history),
                    "history": history,
                    "waves": waves,
                }

            remaining = max_steps - len(history)
            batch = ready[: min(self.max_parallel, remaining)]
            waves += 1

            with ThreadPoolExecutor(
                max_workers=len(batch),
                thread_name_prefix="sage-mission",
            ) as executor:
                futures = {
                    executor.submit(self._execute_task, task["id"]): task["id"]
                    for task in batch
                }

                wave_results = []
                for future in as_completed(futures):
                    task_result = future.result()
                    wave_results.append(task_result)

            # Keep output deterministic for callers even though execution is
            # concurrent.
            wave_results.sort(key=lambda item: item.get("task_id", ""))
            history.extend(wave_results)

            if any(not result.get("success", False) for result in wave_results):
                mission = mission_engine.refresh_mission_status(mission_id)
                return {
                    "success": False,
                    "status": "task_failed",
                    "mission": mission,
                    "summary": self._summary(mission_id, history),
                    "history": history,
                    "waves": waves,
                }

        mission = mission_engine.refresh_mission_status(mission_id)
        return {
            "success": False,
            "status": "max_steps_reached",
            "mission": mission,
            "summary": self._summary(mission_id, history),
            "history": history,
            "waves": waves,
        }


parallel_mission_executor = ParallelMissionExecutor()
