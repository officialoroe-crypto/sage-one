from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from database.models import EvolutionProfile, SparkLedger


TIER_THRESHOLDS = (
    (0, "Bronze", 1),
    (100, "Silver", 1),
    (500, "Gold", 1),
    (1_500, "Platinum", 1),
    (5_000, "Jade", 1),
    (15_000, "Ruby", 1),
    (50_000, "Sapphire", 1),
    (150_000, "Emerald", 1),
    (500_000, "Diamond Sovereign", 1),
    (1_500_000, "Black Opal Realm", 1),
    (5_000_000, "Painite Core", 1),
    (15_000_000, "Void Matter", 1),
    (50_000_000, "Californium Overlord", 1),
)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _tier_for(amount: int) -> tuple[str, int]:
    tier = TIER_THRESHOLDS[0][1]
    for threshold, candidate, _stage in TIER_THRESHOLDS:
        if amount >= threshold:
            tier = candidate
        else:
            break
    return tier, 1


def get_evolution(db: Session, owner_key: str) -> EvolutionProfile:
    profile = db.query(EvolutionProfile).filter(EvolutionProfile.owner_key == owner_key).first()
    if profile is None:
        profile = EvolutionProfile(
            owner_key=owner_key,
            lifetime_achievement=0,
            tier="Bronze",
            stage=1,
            updated_at=_now(),
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


def get_wallet(db: Session, owner_key: str) -> SparkLedger:
    wallet = db.query(SparkLedger).filter(SparkLedger.owner_key == owner_key).first()
    if wallet is None:
        wallet = SparkLedger(owner_key=owner_key, balance=0, updated_at=_now())
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
    return wallet


def grant_sparks(
    db: Session,
    owner_key: str,
    amount: int,
    reason: str,
    reference: str | None = None,
    metadata: dict | None = None,
) -> SparkLedger:
    if amount <= 0:
        raise ValueError("Spark amount must be positive")
    wallet = get_wallet(db, owner_key)
    wallet.balance += amount
    wallet.updated_at = _now()
    entry = SparkLedger(
        owner_key=owner_key,
        balance=wallet.balance,
        delta=amount,
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
) -> SparkLedger:
    if amount <= 0:
        raise ValueError("Spark amount must be positive")
    wallet = get_wallet(db, owner_key)
    if wallet.balance < amount:
        raise ValueError("Insufficient Spark balance")
    wallet.balance -= amount
    wallet.updated_at = _now()
    entry = SparkLedger(
        owner_key=owner_key,
        balance=wallet.balance,
        delta=-amount,
        reason=reason,
        reference=reference,
        metadata_json=json.dumps(metadata or {}, sort_keys=True),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def record_achievement(
    db: Session,
    owner_key: str,
    amount: int,
    reason: str,
    *,
    commit: bool = True,
) -> EvolutionProfile:
    if amount <= 0:
        raise ValueError("Achievement amount must be positive")
    profile = get_evolution(db, owner_key)
    profile.lifetime_achievement += amount
    profile.tier, profile.stage = _tier_for(profile.lifetime_achievement)
    profile.updated_at = _now()
    if commit:
        db.commit()
        db.refresh(profile)
    return profile


def snapshot(db: Session, owner_key: str) -> dict:
    wallet = get_wallet(db, owner_key)
    evolution = get_evolution(db, owner_key)
    return {
        "spark": {"balance": wallet.balance},
        "evolution": {
            "lifetime_achievement": evolution.lifetime_achievement,
            "tier": evolution.tier,
            "stage": evolution.stage,
        },
    }
