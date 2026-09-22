import pytest

from app.main import _require_api_access, app


@pytest.fixture(autouse=True)
def bypass_api_auth_for_legacy_endpoint_tests():
    """Keep legacy route tests focused on endpoint behavior.

    The dedicated auth-boundary tests explicitly remove this override.
    """
    app.dependency_overrides[_require_api_access] = lambda: None
    yield
    app.dependency_overrides.pop(_require_api_access, None)
