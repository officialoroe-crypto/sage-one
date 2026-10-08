from app import main


def test_developer_preview_is_non_mutating_and_requires_explicit_apply(monkeypatch, tmp_path):
    class FakeAgent:
        def __init__(self, workspace, apply_changes=False):
            self.workspace = workspace
            self.apply_changes = apply_changes

        def plan(self, task):
            assert self.apply_changes is False
            return {"success": True, "response": "Plan: change button", "provider": "test", "model": "test"}

        def apply(self, task):
            assert self.apply_changes is True
            return {"success": True, "response": "Applied safely", "provider": "test", "model": "test"}

    monkeypatch.setattr(main, "DevelopmentAgent", FakeAgent)
    claims = {"owner_mode": True, "auth_provider": "developer", "auth_subject": "owner"}

    preview = main.developer_preview(
        main.DeveloperPreviewRequest(task="Change the button", workspace=str(tmp_path)),
        claims,
    )
    assert preview["requires_approval"] is True
    proposal_id = preview["proposal_id"]
    assert main._DEVELOPER_PROPOSALS[proposal_id]["approved"] is False

    try:
        main.developer_apply(main.DeveloperApplyRequest(proposal_id=proposal_id, approved=False), claims)
        assert False, "apply without approval must fail"
    except Exception as exc:
        assert getattr(exc, "status_code", None) == 400

    applied = main.developer_apply(
        main.DeveloperApplyRequest(proposal_id=proposal_id, approved=True),
        claims,
    )
    assert applied["status"] == "applied"
