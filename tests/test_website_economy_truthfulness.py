from pathlib import Path

ROOT = Path(__file__).parents[1]
SYSTEM_SCREEN = ROOT / "website" / "js" / "screens-system.js"


def test_earnings_screen_does_not_claim_a_mock_payment_was_received():
    source = SYSTEM_SCREEN.read_text(encoding="utf-8")
    assert "Real cash earnings are not connected" in source
    assert "No payment has been received or credited by this screen." in source
    assert "Payment Received — Play the 7-Stage Animation" not in source
    assert "Lifetime journey income" not in source


def test_reward_animation_is_labeled_as_preview_not_a_transaction():
    source = SYSTEM_SCREEN.read_text(encoding="utf-8")
    assert "Preview the 7-Stage Animation" in source
    assert "Visual preview only. This does not create a payment, grant Spark, or confirm an earning." in source
    assert "Verified Spark movements appear in the authenticated Spark Wallet ledger." in source


def test_earnings_screen_links_to_backend_backed_spark_wallet():
    source = SYSTEM_SCREEN.read_text(encoding="utf-8")
    assert 'data-act="nav" data-arg="spark">Open live Spark Wallet</button>' in source
    assert "Buy Spark · unavailable" in source
    assert "Withdraw to Bank" not in source
