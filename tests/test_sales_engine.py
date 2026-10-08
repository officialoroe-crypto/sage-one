import json

from sales.service import SalesEngine


def test_sales_engine_scores_missing_website_as_low_confidence():
    result = SalesEngine().audit_business(
        business_name="Example Hardware",
        website=None,
        instagram=None,
        notes="Needs better reels and branding.",
    )
    assert result["success"] is True
    assert result["lead"]["business_name"] == "Example Hardware"
    assert result["lead"]["score"] < 80
    assert result["outreach"]["requires_approval"] is True


def test_sales_engine_task_payload_round_trip():
    payload = {"business_name": "Calvert Hardware Suppliers", "website": "https://example.com"}
    result = SalesEngine().run_from_task(
        description=json.dumps(payload),
        task_id="task-1",
        owner_key="owner:test",
        project_id=None,
        profile_id=None,
    )
    assert result["success"] is True
    assert result["lead"]["business_name"] == payload["business_name"]
