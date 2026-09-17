from datetime import datetime, timezone

from app.orchestrator import orchestrator


class SageWorker:

    def __init__(self):
        self.name = "SAGE WORKER"

    def run_goal(
        self,
        goal: str,
        session_id: str | None = None,
        priority: int = 3
    ):

        try:

            result = orchestrator.execute_goal(
                goal=goal,
                session_id=session_id,
                priority=priority
            )

            return {
                "success": True,
                "result": result,
                "completed_at": datetime.now(
                    timezone.utc
                ).isoformat()
            }

        except Exception as error:

            return {
                "success": False,
                "error": str(error),
                "completed_at": datetime.now(
                    timezone.utc
                ).isoformat()
            }


worker = SageWorker()
