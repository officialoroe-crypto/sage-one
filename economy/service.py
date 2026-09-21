from __future__ import annotations

import json
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from economy.models import EvolutionProfile, SparkLedgerEntry, SparkWallet

EVOLUTION_TIERS = (
    (0, "Bronze"),
    (1_000, "Silver"),
    (5_000, "Gold"),
    (25_000, "Platinum"),
    (100_000, "Jade"),
    (250_000, "Ruby"),
    (500_000, "Sapphire"),
    (1_000_000, "Emerald"),
    (2_500_000, "Diamond Sovereign"),
    (5_000_000, "Black Opal Realm"),
    (10_000_000, "Painite Core"),
    (25_000_000, "Void Matter"),
    (100_000_000, "Californium Overlord"),
)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _tier_for(achievement: int) -> tuple[str, str]:
    for index, (threshold, tier) in enumerate(reversed(EVOLUTION_TIERS)):
        if achievement >= threshold:
            stage = "HIGH" if index == 0 else "MID" if index == 1 else "LOW"
            return tier, stage
    return "Bronze", "LOW"


def evolution_progress(achievement: int) -> dict:
    current_threshold, _ = EVOLUTION_TIERS[0]
    next_tier: str | None = None
    next_threshold: int | None = None
    for index, (threshold, tier) in enumerate(EVOLUTION_TIERS):
        if achievement >= threshold:
            current_threshold = threshold
            if index + 1 < len(EVOLUTION_TIERS):
                next_threshold, next_tier = EVOLUTION_TIERS[index + 1]
        else:
            break
    if next_threshold is None:
        return {
            "current_threshold": current_threshold,
            "next_threshold": None,
            "next_tier": None,
            "ratio": 1.0,
        }
    span = next_threshold - current_threshold
    ratio = (achievement - current_threshold) / span if span else 1.0
    return {
        "current_threshold": current_threshold,
        "next_threshold": next_threshold,
        "next_tier": next_tier,
        "ratio": max(0.0, min(1.0, ratio)),
    }


def get_wallet(db: Session, owner_key: str) -> SparkWallet:
    wallet = db.get(SparkWallet, owner_key)
    if wallet is None:
        wallet = SparkWallet(owner_key=owner_key)
        db.add(wallet)
        db.flush()
    return wallet


def get_evolution(db: Session, owner_key: str) -> EvolutionProfile:
    profile = db.get(EvolutionProfile, owner_key)
    if profile is None:
        profile = EvolutionProfile(owner_key=owner_key)
        db.add(profile)
        db.flush()
    return profile


def grant_sparks(
    db: Session,
    owner_key: str,
    amount: int,
    reason: str,
    reference: str | None = None,
    metadata: dict | None = None,
) -> SparkLedgerEntry:
    if amount <= 0:
        raise ValueError("Spark grant amount must be positive")
    wallet = get_wallet(db, owner_key)
    wallet.balance += amount
    wallet.lifetime_earned += amount
    wallet.updated_at = _now()
    entry = SparkLedgerEntry(
        owner_key=owner_key,
        delta=amount,
        balance_after=wallet.balance,
        reason=reason,
        reference=reference,
        metadata_json=json.dumps(metadata or {}, sort_keys=True),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def spend_sparks(
    db: Session,
    owner_key: str,
    amount: int,
    reason: str,
    reference: str | None = None,
    metadata: dict | None = None,
) -> SparkLedgerEntry:
    if amount <= 0:
        raise ValueError("Spark spend amount must be positive")
    wallet = get_wallet(db, owner_key)
    if wallet.balance < amount:
        raise ValueError("Insufficient SAGE Spark balance")
    wallet.balance -= amount
    wallet.lifetime_spent += amount
    wallet.updated_at = _now()
    entry = SparkLedgerEntry(
        owner_key=owner_key,
        delta=-amount,
        balance_after=wallet.balance,
        reason=reason,
        reference=reference,
        metadata_json=json.dumps(metadata or {}, sort_keys=True),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def record_achievement(db: Session, owner_key: str, amount: int, reason: str) -> EvolutionProfile:
    if amount <= 0:
        raise ValueError("Achievement amount must be positive")
    profile = get_evolution(db, owner_key)
    profile.lifetime_achievement += amount
    profile.tier, profile.stage = _tier_for(profile.lifetime_achievement)
    profile.updated_at = _now()
    db.commit()
    db.refresh(profile)
    return profile


def snapshot(db: Session, owner_key: str) -> dict:
    wallet = get_wallet(db, owner_key)
    evolution = get_evolution(db, owner_key)
    entries = db.scalars(
        select(SparkLedgerEntry)
        .where(SparkLedgerEntry.owner_key == owner_key)
        .order_by(SparkLedgerEntry.created_at.desc())
        .limit(50)
    ).all()
    return {
        "spark": {
            "name": "SAGE Spark",
            "balance": wallet.balance,
            "lifetime_earned": wallet.lifetime_earned,
            "lifetime_spent": wallet.lifetime_spent,
        },
        "evolution": {
            "lifetime_achievement": evolution.lifetime_achievement,
            "tier": evolution.tier,
            "stage": evolution.stage,
            "progress": evolution_progress(evolution.lifetime_achievement),
        },
        "ledger": [
            {
                "id": entry.id,
                "delta": entry.delta,
                "balance_after": entry.balance_after,
                "reason": entry.reason,
                "reference": entry.reference,
                "created_at": entry.created_at.isoformat(),
            }
            for entry in entries
        ],
    }


def evolution_simulation(db: Session, owner_key: str, target_achievement: int, duration_ms: int = 3000) -> dict:
    """Build a non-mutating Evolution animation plan for Owner/God Mode.

    The real Evolution rules remain authoritative: tier and stage are derived
    from achievement thresholds. This endpoint only describes what the UI
    should animate; it never changes the persisted profile.
    """
    if target_achievement < 0:
        raise ValueError("Simulation achievement cannot be negative")
    duration_ms = max(500, min(int(duration_ms), 30_000))
    profile = get_evolution(db, owner_key)
    start = profile.lifetime_achievement
    target_tier, target_stage = _tier_for(target_achievement)
    start_tier, start_stage = _tier_for(start)
    low, high = sorted((start, target_achievement))
    milestones = [
        {"achievement": threshold, "tier": tier}
        for threshold, tier in EVOLUTION_TIERS
        if low < threshold <= high
    ]
    if target_achievement < start:
        milestones = list(reversed(milestones))

    return {
        "simulation": True,
        "mutated": False,
        "duration_ms": duration_ms,
        "direction": "up" if target_achievement >= start else "down",
        "from": {
            "lifetime_achievement": start,
            "tier": start_tier,
            "stage": start_stage,
            "progress": evolution_progress(start),
        },
        "to": {
            "lifetime_achievement": target_achievement,
            "tier": target_tier,
            "stage": target_stage,
            "progress": evolution_progress(target_achievement),
        },
        "milestones": milestones,
    }
