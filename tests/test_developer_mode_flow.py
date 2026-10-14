import hashlib

import pytest
from fastapi import HTTPException

from app import main
from database.connection import SessionLocal
from database.models import DeveloperProposal


def test_developer_preview_is_durable_non_mutating_and_apply_uses_exact_approved_patch(monkeypatch, tmp_path):
    target = tmp_path / "website" / "index.html"
    target.parent.mkdir()
    original = "<button>Old</button>"
    proposed = "<button>Improved</button>"
    target.write_text(original, encoding="utf-8")

    def fake_preview(workspace, task):
        assert workspace == str(tmp_path)
        assert task == "Change the button"
        return {
            "success": True,
            "response": "Prepared one file change in an isolated workspace.",
            "provider": "test",
            "model": "test",
            "changes": [{
                "path": "website/index.html",
                "before_sha256": hashlib.sha256(original.encode()).hexdigest(),
                "after_sha256": hashlib.sha256(proposed.encode()).hexdigest(),
                "before_content": original,
                "content": proposed,
            }],
            "change_count": 1,
        }

    monkeypatch.setattr(main, "prepare_developer_preview", fake_preview)
    claims = {"owner_mode": True, "auth_provider": "developer", "auth_subject": "owner"}

    preview = main.developer_preview(
        main.DeveloperPreviewRequest(task="Change the button", workspace=str(tmp_path)),
        claims,
    )
    assert preview["requires_approval"] is True
    assert target.read_text(encoding="utf-8") == original
    proposal_id = preview["proposal_id"]

    with SessionLocal() as db:
        stored = db.query(DeveloperProposal).filter(DeveloperProposal.id == proposal_id).first()
        assert stored is not None
        assert stored.owner_key == "developer:owner"
        assert stored.status == "preview"

    with pytest.raises(HTTPException) as denied:
        main.developer_apply(
            main.DeveloperApplyRequest(proposal_id=proposal_id, approved=False),
            claims,
        )
    assert denied.value.status_code == 400
    assert target.read_text(encoding="utf-8") == original

    persisted = main.developer_proposal(proposal_id, claims)
    assert persisted["requires_approval"] is True

    applied = main.developer_apply(
        main.DeveloperApplyRequest(proposal_id=proposal_id, approved=True),
        claims,
    )
    assert applied["status"] == "applied"
    assert target.read_text(encoding="utf-8") == proposed
    assert applied["result"]["response"] == "Applied the exact approved preview; the coding agent was not rerun."

    with SessionLocal() as db:
        stored = db.query(DeveloperProposal).filter(DeveloperProposal.id == proposal_id).first()
        assert stored.status == "applied"
        assert stored.result_json is not None

    with pytest.raises(HTTPException) as duplicate:
        main.developer_apply(
            main.DeveloperApplyRequest(proposal_id=proposal_id, approved=True),
            claims,
        )
    assert duplicate.value.status_code == 409


def test_developer_apply_rejects_stale_preview_without_overwriting_newer_work(monkeypatch, tmp_path):
    target = tmp_path / "website" / "index.html"
    target.parent.mkdir()
    original = "<button>Old</button>"
    proposed = "<button>Improved</button>"
    target.write_text(original, encoding="utf-8")

    monkeypatch.setattr(main, "prepare_developer_preview", lambda *_: {
        "success": True,
        "changes": [{
            "path": "website/index.html",
            "before_sha256": hashlib.sha256(original.encode()).hexdigest(),
            "after_sha256": hashlib.sha256(proposed.encode()).hexdigest(),
            "before_content": original,
            "content": proposed,
        }],
    })
    claims = {"owner_mode": True, "auth_provider": "developer", "auth_subject": "owner"}
    preview = main.developer_preview(
        main.DeveloperPreviewRequest(task="Change the button", workspace=str(tmp_path)),
        claims,
    )
    target.write_text("<button>Someone else's newer edit</button>", encoding="utf-8")

    with pytest.raises(HTTPException) as stale:
        main.developer_apply(
            main.DeveloperApplyRequest(proposal_id=preview["proposal_id"], approved=True),
            claims,
        )
    assert stale.value.status_code == 409
    assert target.read_text(encoding="utf-8") == "<button>Someone else's newer edit</button>"
    with SessionLocal() as db:
        stored = db.query(DeveloperProposal).filter(DeveloperProposal.id == preview["proposal_id"]).first()
        assert stored.status == "stale"
