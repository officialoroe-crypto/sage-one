import os
from typing import cast

from openai import OpenAI
from openai.types.chat import ChatCompletionMessageParam

from brain.providers import (
    BaseProvider,
    ProviderResult
)


class OllamaProvider(BaseProvider):

    name = "ollama"

    def __init__(self):

        self.base_url = os.getenv(
            "OLLAMA_BASE_URL",
            "http://127.0.0.1:11434/v1"
        )

        self.model = os.getenv(
            "SAGE_OLLAMA_MODEL",
            "llama3.2:3b"
        )

        self.client = OpenAI(
            base_url=self.base_url,
            api_key="ollama"
        )

    def available(self) -> bool:

        try:

            models = self.client.models.list()

            for model in models.data:

                if model.id == self.model:
                    return True

            return False

        except Exception:

            return False

    def think(
        self,
        system_instruction: str,
        user_message: str,
        conversation: list[dict] | None = None
    ) -> ProviderResult:

        raw_messages = [
            {
                "role": "system",
                "content": system_instruction
            }
        ]

        if conversation:
            raw_messages.extend(
                conversation
            )

        raw_messages.append(
            {
                "role": "user",
                "content": user_message
            }
        )

        messages = cast(
            list[ChatCompletionMessageParam],
            raw_messages
        )

        completion = (
            self.client
            .chat
            .completions
            .create(
                model=self.model,
                messages=messages
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
                "Ollama returned an empty response."
            )

        return ProviderResult(
            provider=self.name,
            model=self.model,
            response=response,
            interaction_id=completion.id
        )


ollama = OllamaProvider()