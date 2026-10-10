from __future__ import annotations

from collections.abc import Generator
from typing import Any

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from database.connection import Base
from identity.auth import authenticate_request
import jobs.api as jobs_api
from jobs.models import JobApplication, JobPosting


@pytest.fixture
def jobs_client(monkeypatch: pytest.MonkeyPatch) -> Generator[tuple[TestClient, dict[str, Any]], None, None]:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(
        bind=engine,
        tables=[JobPosting.__table__, JobApplication.__table__],
    )
    session_factory = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    monkeypatch.setattr(jobs_api, "SessionLocal", session_factory)

    claims: dict[str, Any] = {
        "auth_provider": "test",
        "auth_subject": "employer-a",
        "name": "Employer A",
        "owner_mode": False,
    }
    monkeypatch.setattr(
        jobs_api,
        "get_or_create_authenticated_profile",
        lambda current: {
            "id": f"profile-{current['auth_subject']}",
            "name": current.get("name"),
        },
    )
    prior_auth_override = app.dependency_overrides.get(authenticate_request)
    app.dependency_overrides[authenticate_request] = lambda: claims
    client = TestClient(app)
    try:
        yield client, claims
    finally:
        if prior_auth_override is None:
            app.dependency_overrides.pop(authenticate_request, None)
        else:
            app.dependency_overrides[authenticate_request] = prior_auth_override
        client.close()
        engine.dispose()


def _job_payload(**overrides: Any) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "title": "Junior Flutter Developer",
        "company_name": "SAGE Demo Labs",
        "description": "Build reliable mobile workflows with a small product team.",
        "location": "Kathmandu, Nepal",
        "employment_type": "full-time",
        "work_mode": "hybrid",
        "salary_min": 25000,
        "salary_max": 45000,
        "skills": ["Flutter", "Dart", "Flutter"],
    }
    payload.update(overrides)
    return payload


def test_job_posting_search_and_owner_scoping(jobs_client):
    client, claims = jobs_client
    created = client.post("/jobs", json=_job_payload())
    assert created.status_code == 200, created.text
    job = created.json()["job"]
    job_id = job["id"]

    assert job["title"] == "Junior Flutter Developer"
    assert job["salary_currency"] == "NPR"
    assert job["skills"] == ["Flutter", "Dart"]
    assert job["is_owner"] is True
    assert "owner_key" not in job
    assert "profile_id" not in job

    found = client.get(
        "/jobs",
        params={"q": "flutter", "location": "Kathmandu", "employment_type": "full-time"},
    )
    assert found.status_code == 200
    assert found.json()["total"] == 1
    assert found.json()["jobs"][0]["id"] == job_id

    mine = client.get("/jobs", params={"mine": True})
    assert mine.json()["total"] == 1

    # Another authenticated account can discover a published opening but cannot
    # see the employer's private "mine" list or be treated as its owner.
    claims.update({"auth_subject": "employer-b", "name": "Employer B"})
    other_mine = client.get("/jobs", params={"mine": True})
    assert other_mine.status_code == 200
    assert other_mine.json()["jobs"] == []

    detail = client.get(f"/jobs/{job_id}")
    assert detail.status_code == 200
    assert detail.json()["job"]["is_owner"] is False
    assert detail.json()["job"]["application_count"] is None


def test_applications_are_unique_and_only_the_job_owner_can_manage_them(jobs_client):
    client, claims = jobs_client
    created = client.post("/jobs", json=_job_payload())
    assert created.status_code == 200, created.text
    job_id = created.json()["job"]["id"]

    own_application = client.post(f"/jobs/{job_id}/applications", json={})
    assert own_application.status_code == 409
    assert "own job posting" in own_application.json()["detail"]

    claims.update({"auth_subject": "candidate-b", "name": "Candidate B"})
    applied = client.post(
        f"/jobs/{job_id}/applications",
        json={"cover_note": "I have shipped Flutter apps and can start this month."},
    )
    assert applied.status_code == 200, applied.text
    application = applied.json()["application"]
    application_id = application["id"]
    assert application["status"] == "submitted"
    assert application["job_id"] == job_id
    assert "applicant_owner_key" not in application
    assert "applicant_profile_id" not in application

    duplicate = client.post(f"/jobs/{job_id}/applications", json={"cover_note": "Duplicate"})
    assert duplicate.status_code == 409
    assert "already applied" in duplicate.json()["detail"]

    mine = client.get("/jobs/my-applications")
    assert mine.status_code == 200
    assert mine.json()["applications"][0]["job"]["id"] == job_id
    assert mine.json()["applications"][0]["status"] == "submitted"

    # A different account may not read applicants or change their status.
    claims.update({"auth_subject": "employer-c", "name": "Employer C"})
    forbidden_list = client.get(f"/jobs/{job_id}/applications")
    assert forbidden_list.status_code == 404
    forbidden_update = client.patch(
        f"/jobs/{job_id}/applications/{application_id}",
        json={"status": "shortlisted"},
    )
    assert forbidden_update.status_code == 404

    # The employer that owns the post can review the candidate.
    claims.update({"auth_subject": "employer-a", "name": "Employer A"})
    applicants = client.get(f"/jobs/{job_id}/applications")
    assert applicants.status_code == 200
    assert len(applicants.json()["applications"]) == 1
    applicant = applicants.json()["applications"][0]
    assert applicant["applicant_name"] == "Candidate B"
    assert applicant["cover_note"] == "I have shipped Flutter apps and can start this month."
    assert "applicant_profile_id" not in applicant

    updated = client.patch(
        f"/jobs/{job_id}/applications/{application_id}",
        json={"status": "shortlisted"},
    )
    assert updated.status_code == 200
    assert updated.json()["application"]["status"] == "shortlisted"


def test_job_validation_rejects_invalid_salary_and_unknown_employment_type(jobs_client):
    client, _claims = jobs_client

    invalid_salary = client.post("/jobs", json=_job_payload(salary_min=50000, salary_max=20000))
    assert invalid_salary.status_code == 422
    assert "salary_max" in invalid_salary.json()["detail"]

    invalid_type = client.post("/jobs", json=_job_payload(employment_type="volunteer"))
    assert invalid_type.status_code == 422

    invalid_title = client.post("/jobs", json=_job_payload(title="Hi"))
    assert invalid_title.status_code == 422


def test_jobs_api_requires_an_authenticated_identity(jobs_client):
    client, _claims = jobs_client
    app.dependency_overrides.pop(authenticate_request, None)
    try:
        response = client.get("/jobs")
    finally:
        app.dependency_overrides[authenticate_request] = lambda: _claims
    assert response.status_code == 401
