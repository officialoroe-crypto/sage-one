import os

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


def resolve_database_url(
    environment: str | None,
    sage_database_url: str | None,
    database_url: str | None,
) -> str:
    """Resolve the configured database, failing closed for production.

    SQLite remains convenient for local development and tests, but Render Free's
    ephemeral filesystem must never silently become the production history store.
    """
    configured = (sage_database_url or database_url or "").strip()
    if not configured:
        if (environment or "development").strip().lower() == "production":
            raise RuntimeError(
                "Production requires SAGE_DATABASE_URL or DATABASE_URL. "
                "SQLite fallback is disabled because it cannot guarantee durable history."
            )
        return "sqlite:///./sage_one.db"

    # Render and several Postgres providers still supply the legacy postgres://
    # scheme. Use psycopg 3 explicitly so the supported driver is deterministic.
    if configured.startswith("postgres://"):
        configured = "postgresql+psycopg://" + configured[len("postgres://"):]
    elif configured.startswith("postgresql://"):
        configured = "postgresql+psycopg://" + configured[len("postgresql://"):]
    elif configured.startswith("postgresql+psycopg2://"):
        configured = "postgresql+psycopg://" + configured[len("postgresql+psycopg2://"):]
    return configured


DATABASE_URL = resolve_database_url(
    os.getenv("SAGE_ENV", "development"),
    os.getenv("SAGE_DATABASE_URL"),
    os.getenv("DATABASE_URL"),
)


class Base(DeclarativeBase):
    pass


engine = create_engine(
    DATABASE_URL,
    connect_args={
        "check_same_thread": False
    }
    if DATABASE_URL.startswith("sqlite")
    else {}
)


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()
