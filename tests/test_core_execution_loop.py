from database.connection import Base, SessionLocal, engine
from database.repository import repository
from identity.profile import UserProfile
from workflows.repository import repository as workflow_repository
from workflows.models import Workspace
from app.main import CommandRequest, command
from app.worker import SageWorker


def fresh_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def test_command_creates_owned_durable_task_with_project_context():
    fresh_db()
    claims = {
        "auth_provider": "developer",
        "auth_subject": "owner-test",
        "owner_mode": True,
        "developer_mode": True,
    }

    profile = None
    with SessionLocal() as db:
        profile = UserProfile(
            id="profile-owner-test",
            auth_provider="developer",
            auth_subject="owner-test",
            memory_consent=1,
            onboarding_completed=1,
        )
        db.add(profile)
        db.commit()

        workspace = workflow_repository.create_workspace(
            db,
            profile.id,
            "SAGE ONE",
            "sage-one",
            "personal",
            {},
        )
        project = workflow_repository.create_project(
            db,
            workspace,
            "Execution Loop",
            "general",
            "Core execution-loop validation project.",
            {},
        )

    response = command(
        CommandRequest(
            message="Build the execution loop",
            project_id=project.id,
            priority=2,
        ),
        claims,
    )

    assert response["success"] is True
    task = response["task"]
    assert task["project_id"] == project.id
    assert task["status"] == "pending"

    with SessionLocal() as db:
        stored = repository.get_task(db, task["id"])
        assert stored is not None
        assert stored.profile_id == profile.id
        assert stored.project_id == project.id


def test_completed_task_indexes_project_result_and_learns_with_consent():
    fresh_db()

    with SessionLocal() as db:
        profile = UserProfile(
            id="profile-memory-test",
            auth_provider="developer",
            auth_subject="memory-owner",
            memory_consent=1,
            onboarding_completed=1,
        )
        db.add(profile)
        db.commit()

        workspace = workflow_repository.create_workspace(
            db,
            profile.id,
            "SAGE ONE",
            "sage-one-memory",
            "personal",
            {},
        )
        project = workflow_repository.create_project(
            db,
            workspace,
            "Memory Loop",
            "general",
            None,
            {},
        )
        task = repository.create_task(
            db=db,
            title="Persistent result",
            description="Produce a durable project result",
            profile_id=profile.id,
            project_id=project.id,
        )

    worker = SageWorker(worker_id="outcome-test")
    worker._persist_task_outcome(task.__dict__, {"success": True, "answer": "done"})

    with SessionLocal() as db:
        assets = workflow_repository.list_assets(db, profile.id, project.id)
        assert len(assets) == 1
        assert assets[0].asset_type == "text"
        assert assets[0].status == "completed"

    memories = __import__("identity.memory", fromlist=["list_memory"]).list_memory(profile.id)
    assert any("Persistent result" in item["content"] for item in memories)


def test_task_migration_contains_project_context_columns():
    from database import migrate as migration_module
    from sqlalchemy import inspect

    fresh_db()
    migration_module.migrate()

    columns = {item["name"] for item in inspect(engine).get_columns("tasks")}
    assert "profile_id" in columns
    assert "project_id" in columns
