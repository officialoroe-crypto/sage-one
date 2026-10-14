import hashlib

import pytest
from pathlib import Path

from dev_agent import proposals
from dev_agent.policy import AgentPolicy


def test_preview_runs_in_sandbox_and_returns_exact_patch_without_touching_workspace(monkeypatch, tmp_path):
    target = tmp_path / "website" / "index.html"
    target.parent.mkdir()
    target.write_text("<button>Old</button>", encoding="utf-8")

    class FakeAgent:
        def __init__(self, workspace, apply_changes=False):
            self.workspace = workspace
            assert apply_changes is True

        def apply(self, task):
            assert task == "Improve the button"
            candidate = Path(self.workspace) / "website" / "index.html"
            candidate.write_text("<button>New</button>", encoding="utf-8")
            return {"success": True, "response": "One file changed", "provider": "test", "model": "fake"}

    monkeypatch.setattr(proposals, "DevelopmentAgent", FakeAgent)
    result = proposals.prepare_developer_preview(str(tmp_path), "Improve the button")

    assert result["success"] is True
    assert result["change_count"] == 1
    assert result["changes"][0]["path"] == "website/index.html"
    assert result["changes"][0]["before_sha256"] == hashlib.sha256(b"<button>Old</button>").hexdigest()
    assert result["changes"][0]["content"] == "<button>New</button>"
    assert target.read_text(encoding="utf-8") == "<button>Old</button>"


def test_exact_patch_applies_only_if_source_hash_is_unchanged(tmp_path):
    target = tmp_path / "website" / "index.html"
    target.parent.mkdir()
    target.write_text("before", encoding="utf-8")
    before = hashlib.sha256(b"before").hexdigest()
    after = hashlib.sha256(b"after").hexdigest()
    preview = {"changes": [{
        "path": "website/index.html",
        "before_sha256": before,
        "after_sha256": after,
        "content": "after",
    }]}

    result = proposals.apply_developer_preview(str(tmp_path), preview)
    assert result["success"] is True
    assert result["changed_paths"] == ["website/index.html"]
    assert target.read_text(encoding="utf-8") == "after"

    target.write_text("newer change", encoding="utf-8")
    with pytest.raises(proposals.StaleDeveloperProposal):
        proposals.apply_developer_preview(str(tmp_path), preview)
    assert target.read_text(encoding="utf-8") == "newer change"


def test_developer_policy_allows_product_ui_but_never_secrets_or_escape_paths(tmp_path):
    policy = AgentPolicy(tmp_path)
    assert policy.can_write("website/js/app.js")
    assert policy.can_write("frontend/lib/main.dart")
    assert policy.can_write("qa/e2e/test_workspace_browser.py")
    assert not policy.can_write(".env")
    assert not policy.can_write("website/../../outside.py")
    assert not policy.can_write("website/credentials.json")
