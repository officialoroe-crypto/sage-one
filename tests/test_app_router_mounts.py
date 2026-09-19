from app.main import app
from identity.api import router as identity_router
from world_intelligence.api import router as world_router


def _paths() -> set[str]:
    return {route.path for route in app.routes if hasattr(route, "path")}


def test_identity_and_world_router_definitions_exist():
    identity_paths = {route.path for route in identity_router.routes}
    world_paths = {route.path for route in world_router.routes}

    assert "/identity/google" in {f"/identity{path}" for path in identity_paths}
    assert "/identity/me" in {f"/identity{path}" for path in identity_paths}
    assert "/identity/onboarding" in {f"/identity{path}" for path in identity_paths}
    assert "/identity/phone/send" in {f"/identity{path}" for path in identity_paths}
    assert "/identity/phone/verify" in {f"/identity{path}" for path in identity_paths}
    assert "/world/status" in {f"/world{path}" for path in world_paths}
    assert "/world/knowledge" in {f"/world{path}" for path in world_paths}
    assert "/world/due" in {f"/world{path}" for path in world_paths}
    assert "/world/refresh" in {f"/world{path}" for path in world_paths}


def test_app_keeps_mission_routes_separate_from_identity_and_world():
    paths = _paths()
    assert "/missions/identity/google" not in paths
    assert "/missions/world/status" not in paths
