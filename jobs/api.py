from __future__ import annotations

from typing import Any, Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from database.connection import SessionLocal
from identity.auth import authenticate_request, get_or_create_authenticated_profile
from jobs import repository
from jobs.models import JobApplication

router = APIRouter(prefix="/jobs", tags=["jobs"])

EmploymentType = Literal["full-time", "part-time", "contract", "internship", "freelance"]
WorkMode = Literal["on-site", "hybrid", "remote"]
ApplicationStatus = Literal["submitted", "reviewing", "shortlisted", "rejected", "accepted"]


class JobCreateRequest(BaseModel):
    title: str = Field(min_length=3, max_length=160)
    company_name: str = Field(min_length=1, max_length=160)
    description: str = Field(min_length=20, max_length=12000)
    location: str = Field(min_length=1, max_length=160)
    employment_type: EmploymentType = "full-time"
    work_mode: WorkMode = "on-site"
    salary_min: int | None = Field(default=None, ge=0, le=100_000_000)
    salary_max: int | None = Field(default=None, ge=0, le=100_000_000)
    skills: list[str] = Field(default_factory=list, max_length=20)


class JobApplicationCreateRequest(BaseModel):
    cover_note: str | None = Field(default=None, max_length=5000)


class JobApplicationStatusRequest(BaseModel):
    status: ApplicationStatus


def _owner_key(claims: dict[str, Any]) -> str:
    provider = str(claims.get("auth_provider") or "").strip()
    subject = str(claims.get("auth_subject") or "").strip()
    if not provider or not subject:
        raise HTTPException(status_code=401, detail="Authenticated identity is incomplete.")
    return f"{provider}:{subject}"


def _profile_id(claims: dict[str, Any]) -> str:
    profile = get_or_create_authenticated_profile(claims)
    profile_id = str(profile.get("id") or "").strip()
    if not profile_id:
        raise HTTPException(status_code=401, detail="Authenticated profile is unavailable.")
    return profile_id


def _clean_skills(skills: list[str]) -> list[str]:
    normalized: list[str] = []
    for item in skills:
        value = str(item).strip()
        if not value:
            continue
        if len(value) > 60:
            raise HTTPException(status_code=422, detail="Each skill must be 60 characters or fewer.")
        if value.casefold() not in {existing.casefold() for existing in normalized}:
            normalized.append(value)
    return normalized


def _get_visible_job(job_id: str, owner_key: str):
    with SessionLocal() as db:
        job = repository.repository.get_job(db, job_id)
        if job is None or (job.status != "published" and job.owner_key != owner_key):
            raise HTTPException(status_code=404, detail="Job not found.")
        return job


@router.get("")
def list_jobs(
    q: str | None = Query(default=None, max_length=160),
    location: str | None = Query(default=None, max_length=160),
    employment_type: EmploymentType | None = None,
    mine: bool = False,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    claims: dict[str, Any] = Depends(authenticate_request),
):
    owner_key = _owner_key(claims)
    with SessionLocal() as db:
        items, total = repository.repository.list_jobs(
            db,
            viewer_owner_key=owner_key,
            q=q,
            location=location,
            employment_type=employment_type,
            mine=mine,
            limit=limit,
            offset=offset,
        )
        jobs = [
            repository.repository.serialize_job(
                item,
                viewer_owner_key=owner_key,
                application_count=(
                    db.query(JobApplication)
                    .filter(JobApplication.job_id == item.id)
                    .count()
                    if item.owner_key == owner_key
                    else None
                ),
            )
            for item in items
        ]
    return {"success": True, "jobs": jobs, "total": total, "limit": limit, "offset": offset}


@router.post("")
def create_job(
    request: JobCreateRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    if request.salary_min is not None and request.salary_max is not None and request.salary_max < request.salary_min:
        raise HTTPException(status_code=422, detail="salary_max must be greater than or equal to salary_min.")
    owner_key = _owner_key(claims)
    profile_id = _profile_id(claims)
    skills = _clean_skills(request.skills)
    with SessionLocal() as db:
        job = repository.repository.create_job(
            db,
            owner_key=owner_key,
            profile_id=profile_id,
            company_name=request.company_name,
            title=request.title,
            description=request.description,
            location=request.location,
            employment_type=request.employment_type,
            work_mode=request.work_mode,
            salary_min=request.salary_min,
            salary_max=request.salary_max,
            skills=skills,
        )
        payload = repository.repository.serialize_job(job, viewer_owner_key=owner_key, application_count=0)
    return {"success": True, "job": payload}


@router.get("/my-applications")
def list_my_applications(claims: dict[str, Any] = Depends(authenticate_request)):
    owner_key = _owner_key(claims)
    with SessionLocal() as db:
        applications = repository.repository.list_my_applications(db, owner_key)
        result = []
        for application, job in applications:
            result.append(
                repository.repository.serialize_application(
                    application,
                    job=job,
                    include_candidate_details=False,
                )
            )
    return {"success": True, "applications": result}


@router.get("/{job_id}")
def get_job(job_id: str, claims: dict[str, Any] = Depends(authenticate_request)):
    owner_key = _owner_key(claims)
    with SessionLocal() as db:
        job = repository.repository.get_job(db, job_id)
        if job is None or (job.status != "published" and job.owner_key != owner_key):
            raise HTTPException(status_code=404, detail="Job not found.")
        application_count = (
            db.query(JobApplication).filter(JobApplication.job_id == job.id).count()
            if job.owner_key == owner_key
            else None
        )
        return {
            "success": True,
            "job": repository.repository.serialize_job(
                job,
                viewer_owner_key=owner_key,
                application_count=application_count,
            ),
        }


@router.post("/{job_id}/applications")
def apply_to_job(
    job_id: str,
    request: JobApplicationCreateRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    owner_key = _owner_key(claims)
    profile = get_or_create_authenticated_profile(claims)
    profile_id = str(profile.get("id") or "").strip()
    if not profile_id:
        raise HTTPException(status_code=401, detail="Authenticated profile is unavailable.")
    with SessionLocal() as db:
        job = repository.repository.get_job(db, job_id)
        if job is None or job.status != "published":
            raise HTTPException(status_code=404, detail="Job not found.")
        try:
            application = repository.repository.apply(
                db,
                job=job,
                applicant_owner_key=owner_key,
                applicant_profile_id=profile_id,
                applicant_name=str(profile.get("name") or claims.get("name") or "SAGE User"),
                cover_note=request.cover_note,
            )
        except ValueError as exc:
            raise HTTPException(status_code=409, detail=str(exc)) from exc
        return {"success": True, "application": repository.repository.serialize_application(application)}


@router.get("/{job_id}/applications")
def list_job_applications(
    job_id: str,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    owner_key = _owner_key(claims)
    with SessionLocal() as db:
        job = repository.repository.get_job(db, job_id)
        if job is None or job.owner_key != owner_key:
            raise HTTPException(status_code=404, detail="Job not found.")
        applications = repository.repository.list_job_applications(db, job_id)
        return {
            "success": True,
            "applications": [
                repository.repository.serialize_application(app, include_candidate_details=True)
                for app in applications
            ],
        }


@router.patch("/{job_id}/applications/{application_id}")
def update_job_application(
    job_id: str,
    application_id: str,
    request: JobApplicationStatusRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    owner_key = _owner_key(claims)
    with SessionLocal() as db:
        job = repository.repository.get_job(db, job_id)
        if job is None or job.owner_key != owner_key:
            raise HTTPException(status_code=404, detail="Job not found.")
        application = repository.repository.get_application(db, job_id, application_id)
        if application is None:
            raise HTTPException(status_code=404, detail="Application not found.")
        result = repository.repository.update_application_status(db, application, request.status)
        return {"success": True, "application": repository.repository.serialize_application(result, include_candidate_details=True)}
