from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from database.connection import SessionLocal
from identity.auth import authenticate_request, get_or_create_authenticated_profile
from sales.audit import auditor
from sales.discovery import discovery_service
from sales.repository import add_activity, create_lead, get_lead, list_activities, list_leads, serialize, update_lead
from sales.scoring import score_opportunity
from sales.service import build_outreach, build_sales_intelligence

router = APIRouter(prefix="/sales", tags=["sales"])

class DiscoveryRequest(BaseModel):
    query: str = Field(min_length=2, max_length=300)
    location: str | None = Field(default=None, max_length=200)
    limit: int = Field(default=10, ge=1, le=25)
class LeadCreateRequest(BaseModel):
    business_name: str = Field(min_length=1, max_length=200)
    location: str | None = None
    website_url: str | None = None
    social_urls: dict[str, str] = Field(default_factory=dict)
    contact: dict[str, Any] = Field(default_factory=dict)
    source: str = "manual"
class OutreachApprovalRequest(BaseModel):
    approved: bool
class StatusRequest(BaseModel):
    status: str = Field(min_length=2, max_length=40)

def _profile_id(claims: dict[str, Any]) -> str:
    return get_or_create_authenticated_profile(claims)["id"]

def _json_load(value: str | None) -> dict[str, Any]:
    import json
    try: return json.loads(value) if value else {}
    except Exception: return {}

@router.post("/discover")
def discover(request: DiscoveryRequest, claims: dict[str, Any] = Depends(authenticate_request)):
    return {"success": True, "query": request.query, "results": discovery_service.search(request.query, request.location, request.limit)}

@router.post("/leads")
def create_lead_endpoint(request: LeadCreateRequest, claims: dict[str, Any] = Depends(authenticate_request)):
    with SessionLocal() as db:
        return {"success": True, "lead": serialize(create_lead(db, _profile_id(claims), request.model_dump()))}

@router.post("/leads/{lead_id}/audit")
def audit_lead(lead_id: str, claims: dict[str, Any] = Depends(authenticate_request)):
    with SessionLocal() as db:
        lead = get_lead(db, _profile_id(claims), lead_id)
        if not lead: raise HTTPException(status_code=404, detail="Lead not found")
        result = auditor.audit(lead.website_url, _json_load(lead.social_urls_json))
        score = score_opportunity(result)
        intelligence = build_sales_intelligence(lead.business_name, result, score)
        outreach = build_outreach(lead.business_name, intelligence)
        lead = update_lead(db, lead, audit=result, score=score["score"], sales_intelligence=intelligence, outreach=outreach, status="qualified", last_audited_at=datetime.now(timezone.utc))
        add_activity(db, lead.id, "audit_completed", {"score": score})
        return {"success": True, "lead": serialize(lead)}

@router.get("/leads")
def list_leads_endpoint(status: str | None = None, limit: int = 50, claims: dict[str, Any] = Depends(authenticate_request)):
    with SessionLocal() as db:
        return {"success": True, "leads": [serialize(x) for x in list_leads(db, _profile_id(claims), status, min(limit, 100))]}

@router.get("/leads/{lead_id}")
def get_lead_endpoint(lead_id: str, claims: dict[str, Any] = Depends(authenticate_request)):
    with SessionLocal() as db:
        lead = get_lead(db, _profile_id(claims), lead_id)
        if not lead: raise HTTPException(status_code=404, detail="Lead not found")
        return {"success": True, "lead": serialize(lead)}

@router.patch("/leads/{lead_id}/status")
def change_status(lead_id: str, request: StatusRequest, claims: dict[str, Any] = Depends(authenticate_request)):
    allowed = {"discovered", "audited", "qualified", "outreach_ready", "contacted", "replied", "customer", "closed"}
    if request.status not in allowed: raise HTTPException(status_code=400, detail="Invalid sales status")
    with SessionLocal() as db:
        lead = get_lead(db, _profile_id(claims), lead_id)
        if not lead: raise HTTPException(status_code=404, detail="Lead not found")
        lead = update_lead(db, lead, status=request.status)
        add_activity(db, lead.id, "status_changed", {"status": request.status})
        return {"success": True, "lead": serialize(lead)}

@router.get("/leads/{lead_id}/activities")
def get_activities(lead_id: str, claims: dict[str, Any] = Depends(authenticate_request)):
    with SessionLocal() as db:
        lead = get_lead(db, _profile_id(claims), lead_id)
        if not lead: raise HTTPException(status_code=404, detail="Lead not found")
        return {"success": True, "activities": [serialize(x) for x in list_activities(db, lead_id)]}

@router.post("/leads/{lead_id}/outreach/approve")
def approve_outreach(lead_id: str, request: OutreachApprovalRequest, claims: dict[str, Any] = Depends(authenticate_request)):
    with SessionLocal() as db:
        lead = get_lead(db, _profile_id(claims), lead_id)
        if not lead: raise HTTPException(status_code=404, detail="Lead not found")
        outreach = _json_load(lead.outreach_json)
        outreach["approved"] = request.approved
        lead = update_lead(db, lead, outreach=outreach, status="outreach_ready" if request.approved else "qualified")
        add_activity(db, lead.id, "outreach_approval", {"approved": request.approved})
        return {"success": True, "lead": serialize(lead)}
