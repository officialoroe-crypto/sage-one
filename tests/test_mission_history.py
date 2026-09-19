from execution.progress import MissionProgress
from missions.history import list_events


def test_progress_events_are_persisted_and_ordered(tmp_path, monkeypatch):
    from missions import history

    database_url = f"sqlite:///{tmp_path / 'history.db'}"
    from sqlalchemy import create_engine

    test_engine = create_engine(
        database_url,
        connect_args={"check_same_thread": False},
    )
    monkeypatch.setattr(history, "engine", test_engine)

    progress = MissionProgress("mission-history-test")
    first = progress.emit(
        "mission_started",
        "executing",
        "Mission started.",
        progress_percent=0,
        metadata={"source": "test"},
    )
    second = progress.emit(
        "wave_completed",
        "executing",
        "Wave complete.",
        wave=1,
        task_ids=["b", "a"],
        progress_percent=50,
    )

    events = list_events("mission-history-test")

    assert first["sequence"] == 1
    assert second["sequence"] == 2
    assert second["task_ids"] == ["a", "b"]
    assert [event["sequence"] for event in events] == [1, 2]
    assert events[1]["metadata"] == {}
    assert events[0]["metadata"] == {"source": "test"}
    assert all(event["id"] for event in events)
