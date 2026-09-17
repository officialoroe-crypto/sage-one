import json
import os
from typing import cast

from groq import Groq
from groq.types.chat import ChatCompletionMessageParam

from config.settings import settings

from brain.providers import (
    BaseProvider,
    ProviderResult
)


class GroqProvider(BaseProvider):

    name = "groq"

    def __init__(self):

        self.api_key = (
            settings.GROQ_API_KEY
            or os.getenv("GROQ_API_KEY")
        )

        self.model = (
            settings.GROQ_MODEL
            or os.getenv(
                "SAGE_GROQ_MODEL",
                "openai/gpt-oss-20b"
            )
        )

        self.client = None

        if self.api_key:

            self.client = Groq(
                api_key=self.api_key,
                timeout=30.0
            )

    def available(self) -> bool:

        return self.client is not None

    def think(
        self,
        system_instruction: str,
        user_message: str,
        conversation: list[dict] | None = None
    ) -> ProviderResult:

        if not self.client:

            raise RuntimeError(
                "GROQ_API_KEY is not configured."
            )

        messages = [
            {
                "role": "system",
                "content": system_instruction
            }
        ]

        if conversation:

            messages.extend(
                conversation
            )

        messages.append(
            {
                "role": "user",
                "content": user_message
            }
        )

        typed_messages = cast(
            list[ChatCompletionMessageParam],
            messages
        )

        completion = (
            self.client
            .chat
            .completions
            .create(
                model=self.model,
                messages=typed_messages
            )
        )

        response = (
            completion
            .choices[0]
            .message
            .content
        )

        if not response:

            raise RuntimeError(
                "Groq returned an empty response."
            )

        return ProviderResult(
            provider=self.name,
            model=self.model,
            response=response,
            interaction_id=completion.id
        )

    def think_with_tools(
        self,
        system_instruction: str,
        user_message: str,
        tools: list[dict],
        tool_executor,
        conversation: list[dict] | None = None,
        max_iterations: int = 4
    ) -> ProviderResult:

        if not self.client:

            raise RuntimeError(
                "GROQ_API_KEY is not configured."
            )

        messages = [
            {
                "role": "system",
                "content": system_instruction
            }
        ]

        if conversation:

            messages.extend(
                conversation
            )

        messages.append(
            {
                "role": "user",
                "content": user_message
            }
        )

        for iteration in range(
            max_iterations
        ):

            typed_messages = cast(
                list[ChatCompletionMessageParam],
                messages
            )

            completion = (
                self.client
                .chat
                .completions
                .create(
                    model=self.model,
                    messages=typed_messages,
                    tools=tools,
                    tool_choice="auto",
                    max_completion_tokens=2048
                )
            )

            message = (
                completion
                .choices[0]
                .message
            )

            tool_calls = (
                message.tool_calls
                or []
            )

            # -----------------------------
            # FINAL ANSWER
            # -----------------------------

            if not tool_calls:

                response = (
                    message.content
                    or ""
                )

                if not response:

                    raise RuntimeError(
                        "Groq returned an empty response."
                    )

                return ProviderResult(
                    provider=self.name,
                    model=self.model,
                    response=response,
                    interaction_id=completion.id
                )

            # -----------------------------
            # TOOL LOOP LIMIT
            # -----------------------------

            if iteration >= (
                max_iterations - 1
            ):

                return ProviderResult(
                    provider=self.name,
                    model=self.model,
                    response=(
                        "I reached the maximum "
                        "number of tool operations "
                        "allowed for this request."
                    ),
                    interaction_id=completion.id
                )

            # -----------------------------
            # PRESERVE ASSISTANT TOOL CALL
            # -----------------------------

            assistant_message = {
                "role": "assistant",
                "content": message.content,
                "tool_calls": []
            }

            for tool_call in tool_calls:

                assistant_message[
                    "tool_calls"
                ].append(
                    {
                        "id":
                            tool_call.id,

                        "type":
                            "function",

                        "function":
                            {
                                "name":
                                    tool_call
                                    .function
                                    .name,

                                "arguments":
                                    tool_call
                                    .function
                                    .arguments
                            }
                    }
                )

            messages.append(
                assistant_message
            )

            # -----------------------------
            # EXECUTE TOOL CALLS
            # -----------------------------

            for tool_call in tool_calls:

                tool_name = (
                    tool_call
                    .function
                    .name
                )

                raw_arguments = (
                    tool_call
                    .function
                    .arguments
                )

                try:

                    arguments = json.loads(
                        raw_arguments
                    )

                except json.JSONDecodeError as error:

                    tool_result = {
                        "success": False,
                        "error":
                            "Invalid JSON arguments: "
                            + str(error)
                    }

                else:

                    try:

                        tool_result = tool_executor(
                            tool_name,
                            arguments
                        )

                    except Exception as error:

                        tool_result = {
                            "success": False,
                            "error": str(error)
                        }

                messages.append(
                    {
                        "role": "tool",

                        "tool_call_id":
                            tool_call.id,

                        "name":
                            tool_name,

                        "content":
                            json.dumps(
                                tool_result,
                                default=str
                            )
                    }
                )

        raise RuntimeError(
            "SAGE tool execution loop ended "
            "without producing a final response."
        )


groq = GroqProvider()
