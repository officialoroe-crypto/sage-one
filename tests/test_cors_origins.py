from app.main import _cors_origins


def test_pages_origin_remains_allowed_when_custom_origins_are_configured(monkeypatch):
    monkeypatch.setenv(
        "SAGE_CORS_ORIGINS",
        "https://api.example.test, https://admin.example.test/",
    )

    origins = _cors_origins()

    assert "https://officialoroe-crypto.github.io" in origins
    assert "https://api.example.test" in origins
    assert "https://admin.example.test" in origins


def test_default_cors_origins_include_pages_when_environment_is_blank(monkeypatch):
    monkeypatch.setenv("SAGE_CORS_ORIGINS", " ")

    assert "https://officialoroe-crypto.github.io" in _cors_origins()
