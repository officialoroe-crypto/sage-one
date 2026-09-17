from brain.router import router

from memory.manager import memory

from app.state import state

from tools.registry import registry
from tools.builtins import register_builtin_tools

from permissions.engine import permissions

from database.connection import SessionLocal
from database.repository import repository


SAGE_SYSTEM = """
You are SAGE ONE.

You are the user's personal AI mentor,
execution partner, planner, researcher,
creator, and autonomous assistant.

Your philosophy:

TELL THE TRUTH.
UNDERSTAND THE PERSON.
FIND THE NEXT MOVE.
TAKE ACTION.

Be direct, practical, intelligent,
honest, and action-oriented.

Do not blindly agree with the user.

Challenge weak ideas when necessary.

Call out procrastination when you
recognize it.

Reduce overwhelming problems into
clear next actions.

You have access to tools.

IMPORTANT TOOL RULES:

1. Use tools when they are actually
   useful for completing the user's request.

2. Do not use a tool unnecessarily.

3. Never claim a tool was used if it
   was not actually used.

4. Never claim an action happened unless
   the tool result proves it happened.

5. Capability does not equal permission.

6. Permissions are enforced outside
   the model.

7. Never attempt to bypass permissions.

8. If a requested action is denied,
   explain that it requires permission.

9. Use tool results as factual evidence.

10. If a tool fails, acknowledge the failure.

11. If additional tools are needed,
    continue the tool-calling process.

12. Stop when the user's objective has
    been adequately addressed.

Never invent facts, actions, permissions,
results, capabilities, or experiences.

Never invent your model, provider,
capabilities, actions, or experiences.

If asked which model or provider you
are using, only state information
supplied by the system.

Use relevant memories and conversation
context when provided.

Do not pretend to remember information
that is not provided.

The owner remains the final authority.
"""


class SageCore:

    def __init__(self):

        self.router = router

        self.memory = memory

        self.state = state

        register_builtin_tools()

    # ============================================================
    # TOOL EXECUTION
    # ============================================================

    def _execute_tool(
        self,
        tool_name: str,
        arguments: dict
    ):

        tool = registry.get(
            tool_name
        )

        if not tool:

            return {
                "success": False,
                "error":
                    f"Unknown tool: {tool_name}"
            }

        # --------------------------------------------------------
        # PERMISSION CHECK
        # --------------------------------------------------------

        decision = permissions.check(
            permission=tool.permission,
            risk=tool.risk
        )

        # Keep the existing in-memory audit system.
        permissions.record(
            tool_name=tool.name,
            permission=tool.permission,
            risk=tool.risk,
            allowed=decision.allowed,
            reason=decision.reason
        )

        # --------------------------------------------------------
        # CREATE PERSISTENT ACTION LOG
        # --------------------------------------------------------

        action_id = None

        try:

            with SessionLocal() as db:

                action = repository.create_action(

                    db=db,

                    tool=tool.name,

                    permission=tool.permission,

                    risk=tool.risk,

                    capability=tool.capability,

                    arguments=arguments,

                    permission_allowed=
                        decision.allowed,

                    permission_reason=
                        decision.reason
                )

                action_id = action.id

        except Exception:
            # The action ledger must NEVER prevent
            # the actual permission system from working.
            #
            # If database logging fails, SAGE continues
            # according to the actual permission decision.
            action_id = None

        # --------------------------------------------------------
        # PERMISSION DENIED
        # --------------------------------------------------------

        if not decision.allowed:

            return {
                "success": False,
                "error":
                    "Permission denied.",

                "permission":
                    decision.permission,

                "risk":
                    decision.risk,

                "reason":
                    decision.reason,

                "action_id":
                    action_id
            }

        # --------------------------------------------------------
        # EXECUTE TOOL
        # --------------------------------------------------------

        try:

            result = registry.execute(
                name=tool_name,
                arguments=arguments
            )

            # ----------------------------------------------------
            # MARK ACTION COMPLETED
            # ----------------------------------------------------

            if action_id:

                try:

                    with SessionLocal() as db:

                        repository.complete_action(
                            db=db,
                            action_id=action_id,
                            result=result
                        )

                except Exception:
                    pass

            return {
                "success": True,

                "tool":
                    tool_name,

                "result":
                    result,

                "action_id":
                    action_id
            }

        except Exception as error:

            # ----------------------------------------------------
            # MARK ACTION FAILED
            # ----------------------------------------------------

            if action_id:

                try:

                    with SessionLocal() as db:

                        repository.fail_action(
                            db=db,
                            action_id=action_id,
                            error=str(error)
                        )

                except Exception:
                    pass

            return {
                "success": False,

                "tool":
                    tool_name,

                "error":
                    str(error),

                "action_id":
                    action_id
            }

    # ============================================================
    # CHAT / CORE
    # ============================================================

    def handle(
        self,
        user_message,
        session_id,
        context=""
    ):

        session = self.state.get_session(
            session_id
        )

        if not session:

            raise ValueError(
                "Session not found"
            )

        memories = self.memory.relevant(
            user_message
        )

        memory_text = ""

        if memories:

            memory_text = "\n".join(
                f"- {item['content']}"
                for item in memories
            )

        conversation = []

        recent_messages = (
            session["messages"][-10:]
        )

        for item in recent_messages:

            conversation.append(
                {
                    "role":
                        item["role"],

                    "content":
                        item["content"]
                }
            )

        prompt_parts = []

        if memory_text:

            prompt_parts.append(
                "RELEVANT MEMORY:\n"
                +
                memory_text
            )

        if session["current_goal"]:

            prompt_parts.append(
                "CURRENT GOAL:\n"
                +
                session["current_goal"]
            )

        if session["current_task"]:

            prompt_parts.append(
                "CURRENT TASK:\n"
                +
                session["current_task"]
            )

        if session["active_project"]:

            prompt_parts.append(
                "ACTIVE PROJECT:\n"
                +
                session["active_project"]
            )

        if context:

            prompt_parts.append(
                "ADDITIONAL CONTEXT:\n"
                +
                context
            )

        prompt_parts.append(
            "USER:\n"
            +
            user_message
        )

        prompt = "\n\n".join(
            prompt_parts
        )

        self.state.add_message(
            session_id,
            "user",
            user_message
        )

        tools = registry.schemas()

        result = self.router.think_with_tools(

            system_instruction=
                SAGE_SYSTEM,

            user_message=
                prompt,

            tools=
                tools,

            tool_executor=
                self._execute_tool,

            conversation=
                conversation,

            max_iterations=
                8
        )

        self.state.add_message(
            session_id,
            "assistant",
            result.response
        )

        return result


sage = SageCore()