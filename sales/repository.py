from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any
from sqlalchemy.orm import Session
from sales.models import SalesActivity, SalesLead


def _now() -> datetime: return datetime.now(timezone.utc)

def _json(v: Any) -> str | None: return None if v is None else json.dumps(v, ensure_ascii=False, default=str)
def _load(v: str | None, fallback: Any) -> Any:
    try: return json.loads(v) if v else fallback
    except Exception: return fallback


def serialize(item: Any) -> dict[str, Any]:
    data={k:v for k,v in item.__dict__.items() if k != "_sa_instance_state"}
    for key in ("social_urls_json","contact_json","audit_json","sales_intelligence_json","outreach_json","details_json"):
        if key in data:
            data[key.removesuffix("_json")]=_load(data.pop(key), {} if key != "audit_json" else {})
    for k,v in list(data.items()):
        if isinstance(v, datetime): data[k]=v.isoformat()
    return data


def create_lead(db: Session, profile_id: str, data: dict[str, Any]) -> SalesLead:
    lead=SalesLead(id=str(uuid.uuid4()), profile_id=profile_id, business_name=data["business_name"].strip(), location=data.get("location"), website_url=data.get("website_url"), social_urls_json=_json(data.get("social_urls")), contact_json=_json(data.get("contact")), source=data.get("source","provider"), status=data.get("status","discovered"), score=float(data.get("score",0)), audit_json=_json(data.get("audit")), sales_intelligence_json=_json(data.get("sales_intelligence")), outreach_json=_json(data.get("outreach")), created_at=_now(), updated_at=_now(), last_audited_at=_now() if data.get("audit") else None)
    db.add(lead); db.commit(); db.refresh(lead); return lead


def get_lead(db: Session, profile_id: str, lead_id: str) -> SalesLead | None:
    return db.query(SalesLead).filter(SalesLead.id==lead_id, SalesLead.profile_id==profile_id).first()


def list_leads(db: Session, profile_id: str, status: str | None=None, limit: int=50) -> list[SalesLead]:
    q=db.query(SalesLead).filter(SalesLead.profile_id==profile_id)
    if status: q=q.filter(SalesLead.status==status)
    return q.order_by(SalesLead.score.desc(), SalesLead.created_at.desc()).limit(limit).all()


def update_lead(db: Session, lead: SalesLead, **values: Any) -> SalesLead:
    for key,value in values.items():
        if key in {"social_urls","contact","audit","sales_intelligence","outreach"}: value=_json(value); key=key+"_json"
        setattr(lead,key,value)
    lead.updated_at=_now(); db.commit(); db.refresh(lead); return lead


def add_activity(db: Session, lead_id: str, activity_type: str, details: dict[str,Any] | None=None, status: str="completed") -> SalesActivity:
    item=SalesActivity(id=str(uuid.uuid4()), lead_id=lead_id, activity_type=activity_type, status=status, details_json=_json(details), created_at=_now())
    db.add(item); db.commit(); db.refresh(item); return item


def list_activities(db: Session, lead_id: str, limit: int=100) -> list[SalesActivity]:
    return db.query(SalesActivity).filter(SalesActivity.lead_id==lead_id).order_by(SalesActivity.created_at.desc()).limit(limit).all()
