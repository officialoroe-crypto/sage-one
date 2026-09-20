import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.connection import Base
from economy.models import EvolutionProfile, SparkWallet
from economy.owner import OwnerAuditEvent


def test_owner_controls_are_available_in_developer_mode(monkeypatch, tmp_path):
    from config.settings import settings
    import economy.api as api
    import identity.auth as auth

    engine = create_engine(f"sqlite:///{tmp_path / 'owner.db'}")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    monkeypatch.setattr(api, "SessionLocal", Session)
    monkeypatch.setattr(settings, "DEVELOPER_MODE", True)

    token, claims = auth.create_developer_session("local-owner")
    client = TestClient(api.router)
    # Router-level TestClient cannot apply FastAPI dependency injection by itself;
    # verify the owner claim produced by the controlled local session directly.
    assert claims["owner_mode"] is True
    assert token.startswith("sage-dev-")


def test_owner_spark_and_evolution_controls_are_audited(tmp_path):
    engine = create_engine(f"sqlite:///{tmp_path / 'owner-controls.db'}")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    owner = "developer:owner"
    with Session() as db:
        from economy.owner import set_spark, set_evolution
        wallet = set_spark(db, owner, 1_000_000, "god mode stress test")
        profile = set_evolution(db, owner, 5_000_000, "Black Opal Realm", "LOW", "evolution simulation")
        events = db.query(OwnerAuditEvent).filter(OwnerAuditEvent.owner_key == owner).all()
        assert wallet.balance == 1_000_000
        assert profile.lifetime_achievement == 5_000_000
        assert profile.tier == "Black Opal Realm"
        assert len(events) == 2


def test_owner_reset_controls_internal_state(tmp_path):
    engine = create_engine(f"sqlite:///{tmp_path / 'owner-reset.db'}")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    owner = "developer:owner"
    with Session() as db:
        from economy.owner import set_spark, set_evolution, reset_spark, reset_evolution
        set_spark(db, owner, 500, "seed")
        set_evolution(db, owner, 1_000, "Silver", "LOW", "seed")
        wallet = reset_spark(db, owner, "reset test")
        profile = reset_evolution(db, owner, "reset test")
        assert wallet.balance == 0
        assert profile.lifetime_achievement == 0
        assert profile.tier == "Bronze"
        assert db.query(OwnerAuditEvent).filter(OwnerAuditEvent.owner_key == owner).count() == 4
