from __future__ import annotations

from datetime import datetime, timezone
from sqlalchemy import DateTime, Float, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from database.connection import Base


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


class SalesLead(Base):
    __tablename__ = "sales_leads"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    profile_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    business_name: Mapped[str] = mapped_column(String, nullable=False, index=True)
    location: Mapped[str | None] = mapped_column(String, nullable=True)
    website_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    social_urls_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    contact_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    source: Mapped[str] = mapped_column(String, nullable=False, default="unknown")
    status: Mapped[str] = mapped_column(String, nullable=False, default="discovered", index=True)
    score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0, index=True)
    audit_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    sales_intelligence_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    outreach_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now, nullable=False)
    last_audited_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class SalesActivity(Base):
    __tablename__ = "sales_activities"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    lead_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    activity_type: Mapped[str] = mapped_column(String, nullable=False, index=True)
    status: Mapped[str] = mapped_column(String, nullable=False, default="completed")
    details_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utc_now, nullable=False)
