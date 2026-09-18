from datetime import datetime, timezone

from app.core import sage
from agents.manager import agents
from permissions.engine import permissions
from tasks.engine import tasks
from tools.registry import registry


class SageOrchestrator:

    def __init__(self):
        self.name = "SAGE ORCHESTRATOR"
        self.max_steps = 10

    # ==========================================
    # PUBLIC ENTRY POINT
    # ==========================================

    def execute_goal(
        self,
        goal: str,
        session_id: str | None = None,
        priority: int = 3,
        task_id: str | None = None,
        worker_id: str | None = None,
    ):
        if not goal or not goal.strip():
            raise ValueError(
                "Goal cannot be empty."
            )

        goal = goal.strip()

        # --------------------------------------
        # 1. CHOOSE AGENT
        # --------------------------------------

        agent_name = agents.choose(
            goal
        )

        if not agents.exists(
            agent_name
        ):
            agent_name = "general"

        # --------------------------------------
        # 2. RESOLVE TASK
        # --------------------------------------
        #
        # Direct mode:
        #   Create and own the task through the
        #   legacy task lifecycle.
        #
        # Worker mode:
        #   Use the task already atomically claimed
        #   by the durable worker.
        #
        # The worker-owned path NEVER creates a
        # second root task.
        # --------------------------------------

        worker_owned = (
            task_id is not None
            and worker_id is not None
        )

        if worker_owned:
            resolved_task_id = task_id
        else:
            root_task = tasks.create(
                title=goal[:120],
                description=goal,
                priority=priority,
                agent=agent_name,
                session_id=session_id
            )

            resolved_task_id = root_task["id"]

            tasks.start(
                resolved_task_id
            )

        # --------------------------------------
        # 3. BUILD EXECUTION PLAN
        # --------------------------------------

        plan = self.plan(
            goal=goal,
            agent_name=agent_name
        )

        # --------------------------------------
        # 4. EXECUTE PLAN
        # --------------------------------------

        results = []

        total_steps = len(
            plan
        )

        if total_steps == 0:
            total_steps = 1

        for index, step in enumerate(
            plan,
            start=1
        ):

            progress = int(
                ((index - 1)
                / total_steps)
                * 100
            )

            if worker_owned:
                progress_result = tasks.progress(
                    resolved_task_id,
                    progress
                )

                if progress_result is None:
                    raise RuntimeError(
                        "Worker lost task ownership during progress update."
                    )
            else:
                tasks.progress(
                    resolved_task_id,
                    progress
                )

            result = self.execute_step(
                step=step,
                goal=goal,
                session_id=session_id
            )

            results.append(
                result
            )

            if not result["success"]:

                if worker_owned:
                    return {
                        "success": False,
                        "task_id": resolved_task_id,
                        "agent": agent_name,
                        "goal": goal,
                        "plan": plan,
                        "results": results,
                        "error": result["error"],
                        "worker_owned": True,
                    }

                tasks.fail(
                    resolved_task_id,
                    result["error"]
                )

                return {
                    "success": False,
                    "task_id": resolved_task_id,
                    "agent": agent_name,
                    "goal": goal,
                    "plan": plan,
                    "results": results,
                    "error": result["error"]
                }

        # --------------------------------------
        # 5. VERIFY
        # --------------------------------------

        verification = self.verify(
            goal=goal,
            results=results
        )

        # --------------------------------------
        # 6. FINAL SYNTHESIS
        # --------------------------------------

        final_result = self.summarize(
            goal=goal,
            results=results,
            verification=verification
        )

        # --------------------------------------
        # 7. COMPLETE / FAIL TASK
        # --------------------------------------

        if worker_owned:
            #
            # IMPORTANT:
            #
            # The durable worker owns the database
            # state transition. The orchestrator only
            # returns the execution result.
            #
            return {
                "success":
                    verification["success"],

                "task_id":
                    resolved_task_id,

                "agent":
                    agent_name,

                "goal":
                    goal,

                "plan":
                    plan,

                "results":
                    results,

                "verification":
                    verification,

                "final":
                    final_result,

                "worker_owned":
                    True,
            }

        if verification["success"]:

            tasks.complete(
                resolved_task_id,
                final_result
            )

        else:

            tasks.fail(
                resolved_task_id,
                verification["reason"]
            )

        return {
            "success":
                verification["success"],

            "task_id":
                resolved_task_id,

            "agent":
                agent_name,

            "goal":
                goal,

            "plan":
                plan,

            "results":
                results,

            "verification":
                verification,

            "final":
                final_result
        }

    # ==========================================
    # PLANNER
    # ==========================================

    def plan(
        self,
        goal: str,
        agent_name: str
    ):

        agent = agents.get(
            agent_name
        )

        if not agent:
            agent_name = "general"

        text = goal.lower()

        steps = []

        # --------------------------------------
        # RESEARCH
        # --------------------------------------

        if agent_name == "research":

            steps = [
                {
                    "type": "think",
                    "description":
                        "Understand the research objective."
                },
                {
                    "type": "research",
                    "description":
                        "Identify the information required."
                },
                {
                    "type": "synthesize",
                    "description":
                        "Synthesize findings into a useful answer."
                }
            ]

        # --------------------------------------
        # BUSINESS
        # --------------------------------------

        elif agent_name == "business":

            steps = [
                {
                    "type": "think",
                    "description":
                        "Understand the business objective."
                },
                {
                    "type": "strategy",
                    "description":
                        "Develop the highest-value strategy."
                },
                {
                    "type": "action",
                    "description":
                        "Define concrete execution steps."
                }
            ]

        # --------------------------------------
        # CREATIVE
        # --------------------------------------

        elif agent_name == "creative":

            steps = [
                {
                    "type": "think",
                    "description":
                        "Understand the creative objective."
                },
                {
                    "type": "create",
                    "description":
                        "Develop the creative solution."
                },
                {
                    "type": "refine",
                    "description":
                        "Refine the result for quality and impact."
                }
            ]

        # --------------------------------------
        # GENERAL
        # --------------------------------------

        else:

            steps = [
                {
                    "type": "think",
                    "description":
                        "Understand the user's objective."
                },
                {
                    "type": "action",
                    "description":
                        "Determine and execute the best next action."
                },
                {
                    "type": "verify",
                    "description":
                        "Verify that the objective was addressed."
                }
            ]

        return steps

    # ==========================================
    # STEP EXECUTOR
    # ==========================================

    def execute_step(
        self,
        step: dict,
        goal: str,
        session_id: str | None = None
    ):

        step_type = step.get(
            "type",
            "think"
        )

        description = step.get(
            "description",
            ""
        )

        try:

            # ----------------------------------
            # THINK
            # ----------------------------------

            if step_type == "think":

                result = sage.router.think(
                    system_instruction=(
                        "You are the planning "
                        "component of SAGE ONE. "
                        "Analyze the goal and "
                        "determine the most useful "
                        "course of action."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"STEP:\n{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            # ----------------------------------
            # ACTION
            # ----------------------------------

            if step_type == "action":

                result = sage.router.think(
                    system_instruction=(
                        "You are SAGE ONE's "
                        "execution planner. "
                        "Give concrete, practical "
                        "actions for the user's goal. "
                        "Do not claim actions were "
                        "actually performed unless "
                        "a real tool performed them."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"TASK:\n{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            # ----------------------------------
            # RESEARCH
            # ----------------------------------

            if step_type == "research":

                result = sage.router.think(
                    system_instruction=(
                        "You are the research "
                        "planning component of SAGE ONE. "
                        "Identify what information "
                        "must be researched and "
                        "what evidence would be useful. "
                        "Do not fabricate research."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"RESEARCH STEP:\n"
                        f"{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            # ----------------------------------
            # SYNTHESIZE
            # ----------------------------------

            if step_type == "synthesize":

                result = sage.router.think(
                    system_instruction=(
                        "You are SAGE ONE's "
                        "synthesis component. "
                        "Turn available reasoning "
                        "into a clear useful result."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"TASK:\n{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            # ----------------------------------
            # STRATEGY
            # ----------------------------------

            if step_type == "strategy":

                result = sage.router.think(
                    system_instruction=(
                        "You are SAGE ONE's "
                        "business strategy engine. "
                        "Think practically about "
                        "value, revenue, risk, "
                        "resources and execution."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"STRATEGY:\n{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            # ----------------------------------
            # CREATE
            # ----------------------------------

            if step_type == "create":

                result = sage.router.think(
                    system_instruction=(
                        "You are SAGE ONE's "
                        "creative engine. "
                        "Create the strongest "
                        "practical solution for "
                        "the user's objective."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"CREATIVE TASK:\n"
                        f"{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            # ----------------------------------
            # REFINE
            # ----------------------------------

            if step_type == "refine":

                result = sage.router.think(
                    system_instruction=(
                        "You are SAGE ONE's "
                        "quality-control engine. "
                        "Look for weaknesses and "
                        "improve the proposed result."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"REFINEMENT:\n{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            # ----------------------------------
            # VERIFY
            # ----------------------------------

            if step_type == "verify":

                result = sage.router.think(
                    system_instruction=(
                        "You are SAGE ONE's "
                        "verification engine. "
                        "Determine whether the "
                        "objective has actually "
                        "been addressed."
                    ),
                    user_message=(
                        f"GOAL:\n{goal}\n\n"
                        f"VERIFY:\n{description}"
                    )
                )

                return {
                    "success": True,
                    "type": step_type,
                    "response": result.response,
                    "provider": result.provider,
                    "model": result.model
                }

            return {
                "success": False,
                "type": step_type,
                "error":
                    f"Unknown execution step: "
                    f"{step_type}"
            }

        except Exception as error:

            return {
                "success": False,
                "type": step_type,
                "error": str(error)
            }

    # ==========================================
    # VERIFICATION
    # ==========================================

    def verify(
        self,
        goal: str,
        results: list
    ):

        if not results:

            return {
                "success": False,
                "reason":
                    "No execution results were produced."
            }

        failed = [
            result
            for result in results
            if not result.get("success")
        ]

        if failed:

            return {
                "success": False,
                "reason":
                    "One or more execution steps failed."
            }

        return {
            "success": True,
            "reason":
                "All planned execution steps completed."
        }

    # ==========================================
    # FINAL SYNTHESIS
    # ==========================================

    def summarize(
        self,
        goal: str,
        results: list,
        verification: dict
    ):

        if not verification["success"]:

            return (
                "SAGE could not complete the goal. "
                + verification["reason"]
            )

        responses = []

        for result in results:

            response = result.get(
                "response"
            )

            if response:
                responses.append(
                    response
                )

        if not responses:

            return (
                "The execution cycle completed, "
                "but no textual result was produced."
            )

        combined = "\n\n".join(
            responses
        )

        try:

            final = sage.router.think(
                system_instruction=(
                    "You are SAGE ONE. "
                    "Produce the final answer "
                    "from the execution results. "
                    "Be direct and practical. "
                    "Do not claim actions occurred "
                    "unless the results prove they did."
                ),
                user_message=(
                    f"ORIGINAL GOAL:\n{goal}\n\n"
                    f"EXECUTION RESULTS:\n"
                    f"{combined}"
                )
            )

            return final.response

        except Exception:

            return combined

    # ==========================================
    # STATUS
    # ==========================================

    def status(self):

        return {
            "name": self.name,
            "status": "operational",
            "max_steps": self.max_steps,
            "timestamp":
                datetime.now(
                    timezone.utc
                ).isoformat()
        }


orchestrator = SageOrchestrator()
