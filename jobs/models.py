from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from database.connection import Base


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


class JobPosting(Base):
    __tablename__ = "job_postings"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_key: Mapped[str] = mapped_column(String, nullable=False, index=True)
    profile_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    company_name: Mapped[str] = mapped_column(String(160), nullable=False)
    title: Mapped[str] = mapped_column(String(160), nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    location: Mapped[str] = mapped_column(String(160), nullable=False, default="Nepal", index=True)
    employment_type: Mapped[str] = mapped_column(String(30), nullable=False, default="full-time", index=True)
    work_mode: Mapped[str] = mapped_column(String(20), nullable=False, default="on-site")
    salary_min: Mapped[int | None] = mapped_column(Integer, nullable=True)
    salary_max: Mapped[int | None] = mapped_column(Integer, nullable=True)
    salary_currency: Mapped[str] = mapped_column(String(3), nullable=False, default="NPR")
    skills_json: Mapped[str] = mapped_column(Text, nullable=False, default="[]")
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="published", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now, nullable=False, index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now, nullable=False)


class JobApplication(Base):
    __tablename__ = "job_applications"
    __table_args__ = (
        UniqueConstraint("job_id", "applicant_owner_key", name="uq_job_application_per_applicant"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    job_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    applicant_owner_key: Mapped[str] = mapped_column(String, nullable=False, index=True)
    applicant_profile_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    applicant_name: Mapped[str] = mapped_column(String(160), nullable=False, default="SAGE User")
    cover_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="submitted", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now, nullable=False, index=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now, nullable=False)
