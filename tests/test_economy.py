from economy.service import _tier_for, grant_sparks, record_achievement, spend_sparks, snapshot
from economy.models import SparkLedgerEntry


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
    try:
        spend_sparks(db_session, owner, 11, "premium task")
    except ValueError as exc:
        assert "Insufficient" in str(exc)
    else:
        raise AssertionError("Expected insufficient Spark balance")


def test_evolution_is_independent_of_spark_balance(db_session):
    owner = "google:evolution-user"
    grant_sparks(db_session, owner, 100, "welcome")
    spend_sparks(db_session, owner, 100, "premium task")
    profile = record_achievement(db_session, owner, 1_000, "verified milestone")
    assert profile.lifetime_achievement == 1_000
    assert profile.tier == "Silver"
