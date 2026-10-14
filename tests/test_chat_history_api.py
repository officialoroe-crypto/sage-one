from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from app import main as main_module
from app.main import _require_owner, app
from database import repository
from database.connection import Base
from database.models import ArchivedSession, Message, Session as ChatSession, Task
from identity.auth import authenticate_request


client = TestClient(app)


def _test_database(monkeypatch):
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(
        engine,
        tables=[
            ChatSession.__table__,
            Message.__table__,
            ArchivedSession.__table__,
            Task.__table__,
        ],
    )
    session_factory = sessionmaker(bind=engine, expire_on_commit=False)
    monkeypatch.setattr(main_module, "SessionLocal", session_factory)
    return engine, session_factory


def test_owner_chat_history_archive_restore_and_isolation(monkeypatch):
    engine, session_factory = _test_database(monkeypatch)
    owner_key = "google:qa-owner"
    other_owner_key = "google:other-owner"
    claims = {
        "auth_provider": "google",
        "auth_subject": "qa-owner",
        "owner_mode": True,
    }
    app.dependency_overrides.pop(_require_owner, None)
    monkeypatch.setitem(app.dependency_overrides, _require_owner, lambda: claims)

    try:
        with session_factory() as db:
            active_id = repository.create_session(db, profile_id="profile-owner", owner_key=owner_key)
            repository.add_message(db, active_id, "user", "How do I test SAGE chat?")
            repository.add_message(db, active_id, "assistant", "Send a short test message and check the result.")
            foreign_id = repository.create_session(db, profile_id="profile-other", owner_key=other_owner_key)
            repository.add_message(db, foreign_id, "user", "Private conversation from another owner")

        response = client.get("/sessions")
        assert response.status_code == 200
        body = response.json()
        assert body["success"] is True
        assert [item["id"] for item in body["sessions"]] == [active_id]
        assert body["sessions"][0]["preview"] == "Send a short test message and check the result."
        assert body["sessions"][0]["message_count"] == 2

        archive = client.post(f"/session/{active_id}/archive")
        assert archive.status_code == 200
        assert archive.json()["archived"] is True
        assert client.get("/sessions").json()["sessions"] == []
        archived = client.get("/sessions?archived=true").json()["sessions"]
        assert [item["id"] for item in archived] == [active_id]

        restore = client.post(f"/session/{active_id}/restore")
        assert restore.status_code == 200
        assert restore.json()["archived"] is False
        assert [item["id"] for item in client.get("/sessions").json()["sessions"]] == [active_id]
        assert client.post(f"/session/{foreign_id}/archive").status_code == 404
    finally:
        engine.dispose()


def test_task_list_passes_authenticated_owner_scope(monkeypatch):
    claims = {
        "auth_provider": "google",
        "auth_subject": "qa-owner",
        "owner_mode": True,
    }
    observed = {}
    def list_tasks(status=None, owner_key=None):
        observed["status"] = status
        observed["owner_key"] = owner_key
        return [{"id": "owner-task", "owner_key": owner_key}]

    monkeypatch.setitem(app.dependency_overrides, _require_owner, lambda: claims)
    monkeypatch.setattr(main_module.tasks, "list", list_tasks)
    try:
        response = client.get("/tasks")
        assert response.status_code == 200
        assert observed["owner_key"] == "google:qa-owner"
        assert response.json()["tasks"][0]["owner_key"] == "google:qa-owner"
    finally:
        app.dependency_overrides.pop(_require_owner, None)

def test_chat_history_routes_require_owner_authentication():
    had_owner_override = _require_owner in app.dependency_overrides
    had_auth_override = authenticate_request in app.dependency_overrides
    previous_owner_override = app.dependency_overrides.pop(_require_owner, None)
    previous_auth_override = app.dependency_overrides.pop(authenticate_request, None)
    try:
        response = client.get("/sessions")
        assert response.status_code in (401, 403)
    finally:
        if had_owner_override:
            app.dependency_overrides[_require_owner] = previous_owner_override
        if had_auth_override:
            app.dependency_overrides[authenticate_request] = previous_auth_override

def test_chat_endpoint_returns_core_reply_and_reuses_owner_session(monkeypatch):
    engine, session_factory = _test_database(monkeypatch)
    owner_key = "google:qa-owner"
    claims = {
        "auth_provider": "google",
        "auth_subject": "qa-owner",
        "owner_mode": True,
    }
    app.dependency_overrides.pop(_require_owner, None)
    monkeypatch.setitem(app.dependency_overrides, _require_owner, lambda: claims)
    monkeypatch.setattr(main_module, "get_or_create_authenticated_profile", lambda _claims: {"id": "qa-profile"})
    calls = []

    def fake_handle(**kwargs):
        calls.append(kwargs)
        return {"text": "SAGE Core route test reply"}

    monkeypatch.setattr(main_module.sage, "handle", fake_handle)
    try:
        first = client.post("/chat", json={"message": "Please reply with a test result."})
        assert first.status_code == 200
        first_body = first.json()
        assert first_body["success"] is True
        assert first_body["response"]["text"] == "SAGE Core route test reply"
        session_id = first_body["session_id"]
        assert session_id
        assert calls[0]["user_message"] == "Please reply with a test result."
        assert calls[0]["owner_authorized"] is True

        second = client.post("/chat", json={"message": "Continue the same conversation.", "session_id": session_id})
        assert second.status_code == 200
        assert second.json()["session_id"] == session_id
        assert calls[1]["session_id"] == session_id

        with session_factory() as db:
            saved = repository.get_session(db, session_id, owner_key=owner_key)
            assert saved is not None
    finally:
        engine.dispose()
