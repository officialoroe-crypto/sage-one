from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import or_
from sqlalchemy.orm import Session as DBSession

from jobs.models import JobApplication, JobPosting


class JobsRepository:
    @staticmethod
    def _now() -> datetime:
        return datetime.now(timezone.utc)

    @staticmethod
    def _skills(value: str | None) -> list[str]:
        if not value:
            return []
        try:
            items = json.loads(value)
        except (TypeError, json.JSONDecodeError):
            return []
        return [str(item) for item in items] if isinstance(items, list) else []

    @classmethod
    def serialize_job(
        cls,
        job: JobPosting,
        viewer_owner_key: str | None = None,
        application_count: int | None = None,
    ) -> dict[str, Any]:
        return {
            "id": job.id,
            "title": job.title,
            "company_name": job.company_name,
            "description": job.description,
            "location": job.location,
            "employment_type": job.employment_type,
            "work_mode": job.work_mode,
            "salary_min": job.salary_min,
            "salary_max": job.salary_max,
            "salary_currency": job.salary_currency,
            "skills": cls._skills(job.skills_json),
            "status": job.status,
            "is_owner": viewer_owner_key is not None and job.owner_key == viewer_owner_key,
            "application_count": application_count,
            "created_at": job.created_at.isoformat() if job.created_at else None,
            "updated_at": job.updated_at.isoformat() if job.updated_at else None,
        }

    @staticmethod
    def serialize_application(
        application: JobApplication,
        job: JobPosting | None = None,
        include_candidate_details: bool = False,
    ) -> dict[str, Any]:
        result: dict[str, Any] = {
            "id": application.id,
            "job_id": application.job_id,
            "status": application.status,
            "cover_note": application.cover_note,
            "created_at": application.created_at.isoformat() if application.created_at else None,
            "updated_at": application.updated_at.isoformat() if application.updated_at else None,
        }
        if include_candidate_details:
            result["applicant_name"] = application.applicant_name
            result["applicant_profile_id"] = application.applicant_profile_id
        if job is not None:
            result["job"] = JobsRepository.serialize_job(job)
        return result

    def create_job(
        self,
        db: DBSession,
        *,
        owner_key: str,
        profile_id: str,
        company_name: str,
        title: str,
        description: str,
        location: str,
        employment_type: str,
        work_mode: str,
        salary_min: int | None,
        salary_max: int | None,
        skills: list[str],
        status: str = "published",
    ) -> JobPosting:
        job = JobPosting(
            id=str(uuid.uuid4()),
            owner_key=owner_key,
            profile_id=profile_id,
            company_name=company_name.strip(),
            title=title.strip(),
            description=description.strip(),
            location=location.strip(),
            employment_type=employment_type,
            work_mode=work_mode,
            salary_min=salary_min,
            salary_max=salary_max,
            salary_currency="NPR",
            skills_json=json.dumps(skills, ensure_ascii=False),
            status=status,
            created_at=self._now(),
            updated_at=self._now(),
        )
        db.add(job)
        db.commit()
        db.refresh(job)
        return job

    def get_job(self, db: DBSession, job_id: str) -> JobPosting | None:
        return db.query(JobPosting).filter(JobPosting.id == job_id).first()

    def list_jobs(
        self,
        db: DBSession,
        *,
        viewer_owner_key: str,
        q: str | None = None,
        location: str | None = None,
        employment_type: str | None = None,
        mine: bool = False,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[JobPosting], int]:
        query = db.query(JobPosting)
        if mine:
            query = query.filter(JobPosting.owner_key == viewer_owner_key)
        else:
            query = query.filter(JobPosting.status == "published")
        if q and q.strip():
            pattern = f"%{q.strip()}%"
            query = query.filter(or_(
                JobPosting.title.ilike(pattern),
                JobPosting.company_name.ilike(pattern),
                JobPosting.description.ilike(pattern),
                JobPosting.location.ilike(pattern),
                JobPosting.skills_json.ilike(pattern),
            ))
        if location and location.strip():
            query = query.filter(JobPosting.location.ilike(f"%{location.strip()}%"))
        if employment_type:
            query = query.filter(JobPosting.employment_type == employment_type)
        total = query.count()
        items = (
            query.order_by(JobPosting.created_at.desc(), JobPosting.id.desc())
            .offset(offset)
            .limit(limit)
            .all()
        )
        return items, total

    def apply(
        self,
        db: DBSession,
        *,
        job: JobPosting,
        applicant_owner_key: str,
        applicant_profile_id: str,
        applicant_name: str,
        cover_note: str | None,
    ) -> JobApplication:
        if job.owner_key == applicant_owner_key:
            raise ValueError("You cannot apply to your own job posting.")
        existing = (
            db.query(JobApplication)
            .filter(
                JobApplication.job_id == job.id,
                JobApplication.applicant_owner_key == applicant_owner_key,
            )
            .first()
        )
        if existing is not None:
            raise ValueError("You have already applied to this job.")
        application = JobApplication(
            id=str(uuid.uuid4()),
            job_id=job.id,
            applicant_owner_key=applicant_owner_key,
            applicant_profile_id=applicant_profile_id,
            applicant_name=(applicant_name.strip() or "SAGE User")[:160],
            cover_note=cover_note.strip() if cover_note and cover_note.strip() else None,
            status="submitted",
            created_at=self._now(),
            updated_at=self._now(),
        )
        db.add(application)
        db.commit()
        db.refresh(application)
        return application

    def list_my_applications(
        self, db: DBSession, applicant_owner_key: str
    ) -> list[tuple[JobApplication, JobPosting | None]]:
        items = (
            db.query(JobApplication)
            .filter(JobApplication.applicant_owner_key == applicant_owner_key)
            .order_by(JobApplication.created_at.desc())
            .all()
        )
        return [(application, self.get_job(db, application.job_id)) for application in items]

    def list_job_applications(
        self, db: DBSession, job_id: str
    ) -> list[JobApplication]:
        return (
            db.query(JobApplication)
            .filter(JobApplication.job_id == job_id)
            .order_by(JobApplication.created_at.desc())
            .all()
        )

    def get_application(self, db: DBSession, job_id: str, application_id: str) -> JobApplication | None:
        return (
            db.query(JobApplication)
            .filter(
                JobApplication.id == application_id,
                JobApplication.job_id == job_id,
            )
            .first()
        )

    def update_application_status(
        self,
        db: DBSession,
        application: JobApplication,
        status: str,
    ) -> JobApplication:
        application.status = status
        application.updated_at = self._now()
        db.add(application)
        db.commit()
        db.refresh(application)
        return application


repository = JobsRepository()
