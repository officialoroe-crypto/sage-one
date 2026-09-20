import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.connection import Base
from economy.models import EvolutionProfile, SparkLedgerEntry, SparkWallet
from economy.service import _tier_for, grant_sparks, record_achievement, spend_sparks, snapshot


@pytest.fixture
def db_session(tmp_path):
    engine = create_engine(f"sqlite:///{tmp_path / 'economy.db'}")
    Base.metadata.create_all(
        engine,
        tables=[SparkWallet.__table__, SparkLedgerEntry.__table__, EvolutionProfile.__table__],
    )
    Session = sessionmaker(bind=engine)
    with Session() as session:
        yield session
    engine.dispose()


def test_evolution_thresholds_are_deterministic():
    assert _tier_for(0) == ("Bronze", "LOW")
    assert _tier_for(1_000) == ("Silver", "LOW")
    assert _tier_for(100_000_000) == ("Californium Overlord", "HIGH")


def test_spark_ledger_preserves_balance_and_lifetime(db_session):
    owner = "google:test-user"
    grant_sparks(db_session, owner, 100, "welcome")
    spend_sparks(db_session, owner, 30, "premium task")
    data = snapshot(db_session, owner)
    assert data["spark"]["balance"] == 70
    assert data["spark"]["lifetime_earned"] == 100
    assert data["spark"]["lifetime_spent"] == 30
    assert [entry["delta"] for entry in data["ledger"]] == [-30, 100]


def test_spark_spend_cannot_overdraw(db_session):
    owner = "google:test-user"
    grant_sparks(db_session, owner, 10, "welcome")
    with pytest.raises(ValueError, match="Insufficient"):
        spend_sparks(db_session, owner, 11, "premium task")


def test_evolution_is_independent_of_spark_balance(db_session):
    owner = "google:evolution-user"
    grant_sparks(db_session, owner, 100, "welcome")
    spend_sparks(db_session, owner, 100, "premium task")
    profile = record_achievement(db_session, owner, 1_000, "verified milestone")
    assert profile.lifetime_achievement == 1_000
    assert profile.tier == "Silver"
