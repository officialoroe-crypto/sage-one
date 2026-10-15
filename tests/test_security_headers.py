from fastapi.testclient import TestClient
import pytest
from pydantic import ValidationError
from fastapi.middleware.cors import CORSMiddleware

from app.main import ChatRequest, _cors_origins, app
from config.settings import settings


def test_health_response_includes_baseline_security_headers():
    client = TestClient(app)
    response = client.get("/health")

    assert response.status_code == 200
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["referrer-policy"] == "strict-origin-when-cross-origin"
    assert "microphone=(self)" in response.headers["permissions-policy"]


def test_https_response_includes_hsts():
    client = TestClient(app, base_url="https://testserver")
    response = client.get("/health")

    assert response.status_code == 200
    assert response.headers["strict-transport-security"].startswith("max-age=31536000")


def test_chat_request_rejects_empty_or_oversized_message():
    with pytest.raises(ValidationError):
        ChatRequest(message="")

    with pytest.raises(ValidationError):
        ChatRequest(message="x" * 20001)


def test_chat_request_rejects_oversized_context_labels():
    with pytest.raises(ValidationError):
        ChatRequest(message="hello", goal="x" * 2001)


def test_production_cors_does_not_include_local_development_origins(monkeypatch):
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    monkeypatch.delenv("SAGE_CORS_ORIGINS", raising=False)

    origins = _cors_origins()

    assert "https://officialoroe-crypto.github.io" in origins
    assert not any("localhost" in origin or "127.0.0.1" in origin for origin in origins)


def test_development_cors_includes_local_workspace_origins(monkeypatch):
    monkeypatch.setattr(settings, "ENVIRONMENT", "development")
    monkeypatch.delenv("SAGE_CORS_ORIGINS", raising=False)

    assert "http://localhost:8099" in _cors_origins()


def test_cors_policy_uses_explicit_methods_headers_and_no_cookie_credentials():
    cors = next(middleware for middleware in app.user_middleware if middleware.cls is CORSMiddleware)

    assert cors.kwargs["allow_credentials"] is False
    assert cors.kwargs["allow_methods"] == ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    assert cors.kwargs["allow_headers"] == ["Accept", "Authorization", "Content-Type", "X-Request-ID"]
