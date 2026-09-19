from world_intelligence.engine import DEFAULT_TOPICS, world_intelligence
from permissions.engine import permissions


def test_world_intelligence_permissions_are_bounded():
    assert permissions.get_permissions()["world.read"] is True
    assert permissions.get_permissions()["world.observe"] is True
    assert permissions.get_permissions()["world.learn"] is True
    assert permissions.get_permissions()["world.propose_upgrade"] is True
    assert permissions.get_permissions().get("security.modify") is False


def test_world_intelligence_status_is_not_self_modifying():
    status = world_intelligence.status()

    assert status["success"] is True
    assert status["public_sources_only"] is True
    assert status["self_modification"] is False
    assert status["upgrade_proposals_require_human_review"] is True
    assert status["default_topics"] == list(DEFAULT_TOPICS)


def test_world_upgrade_proposal_requires_review():
    result = world_intelligence.propose_upgrade(
        title="Test capability",
        reason="A repeated public-world pattern suggests a missing capability.",
        benefit="Could improve user execution if validated and approved.",
        evidence=["source:test"],
    )

    assert result["success"] is True
    assert result["proposal"]["status"] == "proposed"
    assert result["proposal"]["evidence"] == ["source:test"]

    proposals = world_intelligence.list_upgrade_proposals(limit=10)
    assert any(item["id"] == result["proposal"]["id"] for item in proposals)
