from database.connection import Base, SessionLocal, engine
from economy.achievements import record_verified_achievement
from economy.service import get_evolution


def _reset_database() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def test_verified_achievement_updates_evolution_atomically():
    _reset_database()

    with SessionLocal() as db:
        event, created = record_verified_achievement(
            db,
            "test-owner",
            250,
            "Verified mission result",
            "mission",
            "mission-1",
            {"status": "verified", "result": "done"},
        )
        assert created is True
        assert event.amount == 250
        assert get_evolution(db, "test-owner").lifetime_achievement == 250

        duplicate, created_again = record_verified_achievement(
            db,
            "test-owner",
            250,
            "Verified mission result",
            "mission",
            "mission-1",
            {"status": "verified", "result": "done"},
        )
        assert created_again is False
        assert duplicate.id == event.id
        assert get_evolution(db, "test-owner").lifetime_achievement == 250
