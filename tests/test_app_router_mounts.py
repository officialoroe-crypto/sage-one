from app.main import app


def _paths() -> set[str]:
    return {
        route.path
        for route in app.routes
        if hasattr(route, "path")
    }


def test_identity_and_world_routers_are_mounted_at_top_level():
    paths = _paths()

    assert "/identity/google" in paths
    assert "/identity/me" in paths
    assert "/identity/onboarding" in paths
    assert "/identity/phone/send" in paths
    assert "/identity/phone/verify" in paths
    assert "/world/status" in paths
    assert "/world/knowledge" in paths
    assert "/world/due" in paths
    assert "/world/refresh" in paths


def test_identity_and_world_routes_are_not_nested_under_missions():
    paths = _paths()

    assert "/missions/identity/google" not in paths
    assert "/missions/world/status" not in paths
