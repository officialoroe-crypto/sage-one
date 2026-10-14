from fastapi.testclient import TestClient
import pytest
from pydantic import ValidationError

from app.main import ChatRequest, app


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
