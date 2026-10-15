import pytest

from app.core import SageCore


class _FakeState:
    def __init__(self):
        self.messages = []

    def get_session(self, _session_id):
        return {
            "id": "session-1",
            "messages": [],
            "current_goal": None,
            "current_task": None,
            "active_project": None,
        }

    def add_message(self, session_id, role, content):
        self.messages.append((session_id, role, content))


class _FakeMemory:
    @staticmethod
    def relevant(_message):
        return []


class _FailingRouter:
    @staticmethod
    def think_with_tools(**_kwargs):
        raise RuntimeError("provider unavailable")


def test_failed_provider_call_clears_request_scoped_owner_context():
    core = SageCore()
    core.state = _FakeState()
    core.memory = _FakeMemory()
    core.router = _FailingRouter()

    with pytest.raises(RuntimeError, match="provider unavailable"):
        core.handle(
            user_message="A message that triggers a provider failure",
            session_id="session-1",
            owner_authorized=True,
        )

    assert core._active_session_id is None
    assert core._active_owner_authorized is False
    assert core.state.messages == [
        ("session-1", "user", "A message that triggers a provider failure")
    ]
