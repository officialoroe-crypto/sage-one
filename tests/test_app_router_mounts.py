from app.main import app
from identity.api import router as identity_router
from world_intelligence.api import router as world_router
from economy.api import router as economy_router


def _paths() -> set[str]:
    return {route.path for route in app.routes if hasattr(route, "path")}


def test_identity_and_world_router_definitions_exist():
    identity_paths = {route.path for route in identity_router.routes}
    world_paths = {route.path for route in world_router.routes}

    assert "/identity/google" in identity_paths
    assert "/identity/me" in identity_paths
    assert "/identity/onboarding" in identity_paths
    assert "/identity/phone/send" in identity_paths
    assert "/identity/phone/verify" in identity_paths
    assert "/economy/owner/status" in {route.path for route in economy_router.routes}
    assert "/world/status" in world_paths
    assert "/world/knowledge" in world_paths
    assert "/world/due" in world_paths
    assert "/world/refresh" in world_paths


def test_identity_and_world_routers_are_mounted_on_app():
    paths = _paths()
    print("DEBUG_APP_PATHS", sorted(paths))
    print("DEBUG_IDENTITY_PATHS", sorted(route.path for route in identity_router.routes))
    before = len(app.routes)
    app.include_router(identity_router)
    after = len(app.routes)
    print("DEBUG_REINCLUDE", before, after, sorted(route.path for route in app.routes if route.path.startswith("/identity")))

    assert "/identity/google" in paths
    assert "/identity/me" in paths
    assert "/identity/onboarding" in paths
    assert "/identity/phone/send" in paths
    assert "/identity/phone/verify" in paths
    assert "/economy/owner/status" in paths
    assert "/world/status" in paths
    assert "/world/knowledge" in paths
    assert "/world/due" in paths
    assert "/world/refresh" in paths


def test_app_keeps_mission_routes_separate_from_identity_and_world():
    paths = _paths()
    assert "/missions/identity/google" not in paths
    assert "/missions/world/status" not in paths
