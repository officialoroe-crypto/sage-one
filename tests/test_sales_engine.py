from sales.audit import BusinessAuditor
from sales.scoring import score_opportunity
from sales.discovery import BusinessCandidate, MockDiscoveryProvider, DiscoveryService

def test_sales_score_is_transparent_and_bounded():
    result = score_opportunity({
        "website": {"present": False},
        "social": {},
        "content": {"video_present": False, "consistency": "weak"},
        "branding": {"quality": "weak"},
        "contact": {"present": False},
    })
    assert result["score"] == 80
    assert result["tier"] == "hot"
    assert len(result["signals"]) >= 5

def test_discovery_provider_is_replaceable():
    provider = MockDiscoveryProvider([BusinessCandidate("Calvert Hardware Suppliers", location="Nepal")])
    results = DiscoveryService(provider).search("hardware", "Nepal")
    assert results[0]["business_name"] == "Calvert Hardware Suppliers"

def test_auditor_handles_missing_website_without_network():
    result = BusinessAuditor().audit(None)
    assert result["website"]["present"] is False
    assert result["website"]["quality"] == "missing"


def test_sales_intelligence_and_outreach_are_actionable_and_owner_gated():
    from sales.service import build_outreach, build_sales_intelligence
    audit = {
        "website": {"present": False, "quality": "missing", "cta_present": False},
        "social": {},
        "content": {"video_present": False, "consistency": "unknown"},
        "branding": {"quality": "unknown"},
        "contact": {"present": False},
    }
    score = score_opportunity(audit)
    intelligence = build_sales_intelligence("Example Business", audit, score)
    outreach = build_outreach("Example Business", intelligence)
    assert intelligence["recommended_services"]
    assert outreach["channel"] == "whatsapp"
    assert outreach["requires_owner_approval"] is True
    assert "Example Business" in outreach["message"]
