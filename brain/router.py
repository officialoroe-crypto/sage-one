import time

from brain.providers import ProviderResult

from brain.providers.groq_provider import GroqProvider
from brain.providers.ollama_provider import OllamaProvider


class BrainRouter:

    COOLDOWN_SECONDS = 30

    def __init__(self):

        self.providers = [
            GroqProvider(),
            OllamaProvider(),
        ]

        self.provider_health = {
            provider.name: {
                "successes": 0,
                "failures": 0,
                "last_error": None,
                "last_used": None,
                "cooldown_until": 0.0,
            }
            for provider in self.providers
        }

    def _is_in_cooldown(self, provider_name):

        return (
            time.time()
            < self.provider_health[
                provider_name
            ]["cooldown_until"]
        )

    def _mark_success(self, provider_name):

        health = self.provider_health[
            provider_name
        ]

        health["successes"] += 1
        health["last_used"] = time.time()
        health["last_error"] = None
        health["cooldown_until"] = 0.0

    def _mark_failure(
        self,
        provider_name,
        error
    ):

        health = self.provider_health[
            provider_name
        ]

        health["failures"] += 1
        health["last_error"] = str(error)

        health["cooldown_until"] = (
            time.time()
            + self.COOLDOWN_SECONDS
        )

    def think(
        self,
        system_instruction,
        user_message,
        conversation=None
    ):

        errors = []

        for provider in self.providers:

            if self._is_in_cooldown(
                provider.name
            ):
                continue

            if not provider.available():
                continue

            try:

                result = provider.think(
                    system_instruction=
                        system_instruction,
                    user_message=
                        user_message,
                    conversation=
                        conversation
                )

                self._mark_success(
                    provider.name
                )

                return result

            except Exception as error:

                self._mark_failure(
                    provider.name,
                    error
                )

                errors.append(
                    f"{provider.name}: {error}"
                )

        if not errors:

            raise RuntimeError(
                "No SAGE AI providers are "
                "currently available."
            )

        raise RuntimeError(
            "All available SAGE AI providers failed.\n"
            + "\n".join(errors)
        )

    def think_with_tools(
        self,
        system_instruction,
        user_message,
        tools,
        tool_executor,
        conversation=None,
        max_iterations=4
    ):

        errors = []

        for provider in self.providers:

            if self._is_in_cooldown(
                provider.name
            ):
                continue

            if not provider.available():
                continue

            # Only providers implementing
            # real tool calling are eligible.
            if not hasattr(
                provider,
                "think_with_tools"
            ):
                continue

            try:

                result = provider.think_with_tools(
                    system_instruction=
                        system_instruction,
                    user_message=
                        user_message,
                    tools=
                        tools,
                    tool_executor=
                        tool_executor,
                    conversation=
                        conversation,
                    max_iterations=
                        max_iterations
                )

                self._mark_success(
                    provider.name
                )

                return result

            except NotImplementedError as error:

                errors.append(
                    f"{provider.name}: "
                    f"tool calling not implemented"
                )

                continue

            except Exception as error:

                self._mark_failure(
                    provider.name,
                    error
                )

                errors.append(
                    f"{provider.name}: {error}"
                )

                continue

        raise RuntimeError(
            "No SAGE providers with "
            "tool-calling support are available.\n"
            + "\n".join(errors)
        )

    def health(self):

        result = {}

        for provider_name, health in (
            self.provider_health.items()
        ):

            result[provider_name] = {
                "successes":
                    health["successes"],

                "failures":
                    health["failures"],

                "last_error":
                    health["last_error"],

                "last_used":
                    health["last_used"],

                "in_cooldown":
                    self._is_in_cooldown(
                        provider_name
                    )
            }

        return result


router = BrainRouter()
