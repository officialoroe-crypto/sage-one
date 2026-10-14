from pathlib import Path

ROOT = Path(__file__).parents[1]
WEBSITE = ROOT / "website"


def test_spark_rate_and_cash_out_limits_are_disclosed():
    landing = (WEBSITE / "index.html").read_text(encoding="utf-8")
    assert "1 Spark = NPR 1" in landing
    assert "Cash-out to rupees is not available yet" in landing
    assert "Spark is platform currency, not a cryptocurrency or an investment." in landing
    assert "Paying out real rupees needs a payment provider" in landing


def test_chat_and_phone_examples_are_not_presented_as_live_transactions():
    chat = (WEBSITE / "chat" / "index.html").read_text(encoding="utf-8")
    phone = (WEBSITE / "app-preview" / "index.html").read_text(encoding="utf-8")
    assert "sign-in is simulated on this page" in chat
    assert "Replies on this page are scripted examples." in chat
    assert "Preview with example numbers." in phone
    assert "Cash-out to rupees is not available yet." in phone


def test_calculator_is_only_a_quote_and_not_a_wallet_transaction():
    landing = (WEBSITE / "index.html").read_text(encoding="utf-8")
    app = (WEBSITE / "app.js").read_text(encoding="utf-8")
    assert "A quote does not charge a wallet." in landing
    assert "var NPR_PER_SPARK = 1;" in app
    assert "var CEILING = 200;" in app
    assert "window.sageSpendLimit = spendLimit;" in app
    assert "Purchase complete" not in app
    assert "Payment Received" not in app


def test_stale_test_counts_and_unqualified_feature_claims_are_removed():
    landing = (WEBSITE / "index.html").read_text(encoding="utf-8")
    assert "243 backend tests passing" not in landing
    assert "Implemented in code (verification varies)" in landing
    assert "Automated tests exist; the current result is shown in GitHub Actions" in landing
