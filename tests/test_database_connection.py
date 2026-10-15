import pytest

from database.connection import resolve_database_url


def test_development_can_use_local_sqlite_fallback():
    assert resolve_database_url("development", None, None) == "sqlite:///./sage_one.db"


def test_production_fails_closed_without_explicit_database_url():
    with pytest.raises(RuntimeError, match="Production requires SAGE_DATABASE_URL or DATABASE_URL"):
        resolve_database_url("production", None, None)


def test_production_rejects_explicit_sqlite_history_store():
    with pytest.raises(RuntimeError, match="SQLite is not allowed"):
        resolve_database_url("production", "sqlite:///./explicit.db", None)

def test_hosted_environment_fails_closed_even_if_sage_env_is_missing():
    with pytest.raises(RuntimeError, match="Production requires SAGE_DATABASE_URL or DATABASE_URL"):
        resolve_database_url(None, None, None, hosted=True)


def test_hosted_environment_rejects_sqlite_even_if_sage_env_is_development():
    with pytest.raises(RuntimeError, match="SQLite is not allowed"):
        resolve_database_url("development", "sqlite:///./explicit.db", None, hosted=True)


def test_database_url_fallback_is_supported_and_postgres_driver_is_normalized():
    url = resolve_database_url(
        "production",
        None,
        "postgres://qa-user:qa-password@example.invalid/sage",
    )
    assert url == "postgresql+psycopg://qa-user:qa-password@example.invalid/sage"


def test_postgresql_scheme_uses_psycopg_driver():
    url = resolve_database_url(
        "production",
        None,
        "postgresql://qa-user:qa-password@example.invalid/sage",
    )
    assert url.startswith("postgresql+psycopg://")

def test_blank_sage_database_url_falls_back_to_database_url():
    url = resolve_database_url(
        "production",
        "   ",
        "postgresql://qa-user:qa-password@example.invalid/sage",
    )
    assert url.startswith("postgresql+psycopg://")
