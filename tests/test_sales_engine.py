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
