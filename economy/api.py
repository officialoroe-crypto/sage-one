"""Authenticated SAGE Spark and Evolution API."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from database.connection import SessionLocal
from economy.achievements import record_verified_achievement
from economy.costs import cost_catalog
from economy.service import get_evolution, grant_sparks, record_achievement, snapshot, spend_sparks
from identity.auth import authenticate_request

router = APIRouter(prefix="/economy", tags=["economy"])


class SparkAmountRequest(BaseModel):
    amount: int = Field(gt=0, le=1_000_000_000)
    reason: str = Field(min_length=1, max_length=200)
    reference: str | None = Field(default=None, max_length=200)


class AchievementRequest(BaseModel):
    amount: int = Field(gt=0, le=1_000_000_000)
    reason: str = Field(min_length=1, max_length=200)


class VerifiedAchievementRequest(BaseModel):
    amount: int = Field(gt=0, le=1_000_000_000)
    reason: str = Field(min_length=1, max_length=200)
    source_type: str = Field(min_length=1, max_length=100)
    source_id: str = Field(min_length=1, max_length=200)
    evidence: dict = Field(min_length=1)


def _owner(claims: dict) -> str:
    return f"{claims['auth_provider']}:{claims['auth_subject']}"


@router.get("/me")
def economy_me(claims: dict = Depends(authenticate_request)):
    with SessionLocal() as db:
        return {"success": True, **snapshot(db, _owner(claims))}


@router.get("/costs")
def economy_costs(claims: dict = Depends(authenticate_request)):
    # Authentication keeps the catalog consistent with the user-scoped economy surface.
    _owner(claims)
    return {"success": True, "costs": cost_catalog()}


@router.post("/spark/grant")
def spark_grant(request: SparkAmountRequest, claims: dict = Depends(authenticate_request)):
    with SessionLocal() as db:
        entry = grant_sparks(db, _owner(claims), request.amount, request.reason, request.reference)
        return {"success": True, "entry": {"id": entry.id, "delta": entry.delta, "balance_after": entry.balance_after}}


@router.post("/spark/spend")
def spark_spend(request: SparkAmountRequest, claims: dict = Depends(authenticate_request)):
    try:
        with SessionLocal() as db:
            entry = spend_sparks(db, _owner(claims), request.amount, request.reason, request.reference)
            return {"success": True, "entry": {"id": entry.id, "delta": entry.delta, "balance_after": entry.balance_after}}
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc


@router.post("/evolution/achievement")
def evolution_achievement(request: AchievementRequest, claims: dict = Depends(authenticate_request)):
    with SessionLocal() as db:
        profile = record_achievement(db, _owner(claims), request.amount, request.reason)
        return {
            "success": True,
            "evolution": {
                "lifetime_achievement": profile.lifetime_achievement,
                "tier": profile.tier,
                "stage": profile.stage,
            },
        }


@router.post("/evolution/verified-achievement")
def verified_evolution_achievement(
    request: VerifiedAchievementRequest,
    claims: dict = Depends(authenticate_request),
):
    try:
        with SessionLocal() as db:
            event, created = record_verified_achievement(
                db,
                _owner(claims),
                request.amount,
                request.reason,
                request.source_type,
                request.source_id,
                request.evidence,
            )
            profile = get_evolution(db, _owner(claims))
            return {
                "success": True,
                "created": created,
                "event": {
                    "id": event.id,
                    "source_type": event.source_type,
                    "source_id": event.source_id,
                    "amount": event.amount,
                    "verification_status": event.verification_status,
                    "created_at": event.created_at.isoformat(),
                },
                "evolution": {
                    "lifetime_achievement": profile.lifetime_achievement,
                    "tier": profile.tier,
                    "stage": profile.stage,
                },
            }
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/evolution")
def evolution_me(claims: dict = Depends(authenticate_request)):
    with SessionLocal() as db:
        profile = get_evolution(db, _owner(claims))
        return {
            "success": True,
            "lifetime_achievement": profile.lifetime_achievement,
            "tier": profile.tier,
            "stage": profile.stage,
        }
