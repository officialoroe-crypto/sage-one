from __future__ import annotations

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from world_intelligence.engine import world_intelligence


router = APIRouter(prefix="/world", tags=["world-intelligence"])


class WorldRefreshRequest(BaseModel):
    topics: list[str] = Field(default_factory=list, max_length=6)


class UpgradeProposalRequest(BaseModel):
    title: str = Field(min_length=1, max_length=500)
    reason: str = Field(min_length=1, max_length=10000)
    benefit: str = Field(min_length=1, max_length=10000)
    evidence: list[str] = Field(default_factory=list, max_length=50)


@router.get("/status")
def world_status():
    return world_intelligence.status()


@router.get("/knowledge")
def world_knowledge(limit: int = 20):
    return {"success": True, "knowledge": world_intelligence.list_knowledge(limit)}


@router.get("/due")
def world_due():
    return {"success": True, "topics": world_intelligence.due()}


@router.post("/refresh")
def world_refresh(request: WorldRefreshRequest):
    try:
        topics = request.topics or None
        return world_intelligence.refresh(topics)
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.post("/upgrade-proposals")
def create_upgrade_proposal(request: UpgradeProposalRequest):
    try:
        return world_intelligence.propose_upgrade(
            title=request.title,
            reason=request.reason,
            benefit=request.benefit,
            evidence=request.evidence,
        )
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.get("/upgrade-proposals")
def list_upgrade_proposals(limit: int = 20):
    return {
        "success": True,
        "proposals": world_intelligence.list_upgrade_proposals(limit),
    }
