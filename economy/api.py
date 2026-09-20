"""Authenticated SAGE Spark and Evolution API."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from database.connection import SessionLocal
from economy.service import get_evolution, record_achievement, snapshot, spend_sparks, grant_sparks
from identity.auth import authenticate_request

router = APIRouter(prefix="/economy", tags=["economy"])


class SparkAmountRequest(BaseModel):
    amount: int = Field(gt=0, le=1_000_000_000)
    reason: str = Field(min_length=1, max_length=200)
    reference: str | None = Field(default=None, max_length=200)


class AchievementRequest(BaseModel):
    amount: int = Field(gt=0, le=1_000_000_000)
    reason: str = Field(min_length=1, max_length=200)


def _owner(claims: dict) -> str:
    return f"{claims['auth_provider']}:{claims['auth_subject']}"


@router.get("/me")
def economy_me(claims: dict = Depends(authenticate_request)):
    with SessionLocal() as db:
        return {"success": True, **snapshot(db, _owner(claims))}


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
