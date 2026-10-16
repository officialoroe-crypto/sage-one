from pathlib import Path

ROOT = Path(__file__).parents[1]
WEBSITE = ROOT / "website"


def test_sp_and_ss_are_separate_and_no_live_money_rate_is_claimed():
    landing = (WEBSITE / "index.html").read_text(encoding="utf-8")
    app = (WEBSITE / "app.js").read_text(encoding="utf-8")
    phone = (WEBSITE / "app-preview" / "index.html").read_text(encoding="utf-8")
    chat = (WEBSITE / "chat" / "index.html").read_text(encoding="utf-8")
    assert "internal, non-cash points" in landing
    assert "SS" in landing and "payments, exchange rates and cash-out are not enabled" in landing
    assert "1 Spark = NPR 1" not in landing
    assert "NPR_PER_SPARK" not in app
    assert "sparkIn" not in landing and "nprIn" not in landing
    assert "SP are internal non-cash points" in app
    assert "SS balance (example preview)" in phone
    assert 'id="balance">0</div>' in phone
    assert "No live wallet, exchange rate, payment or cash-out is active." in phone
    assert 'title="Preview only; no live wallet"' in chat
    assert 'id="railBalance">0</b>' in chat


def test_chat_and_phone_previews_are_disclosed_as_simulations():
    chat = (WEBSITE / "chat" / "index.html").read_text(encoding="utf-8")
    phone = (WEBSITE / "app-preview" / "index.html").read_text(encoding="utf-8")
    chat_js = (WEBSITE / "chat" / "chat.js").read_text(encoding="utf-8")
    phone_js = (WEBSITE / "app-preview" / "app.js").read_text(encoding="utf-8")
    assert "sign-in is simulated on this page" in chat
    assert "Replies on this page are scripted examples." in chat
    assert "Preview with example numbers." in phone
    assert "there is no backend call on this page" in chat_js
    assert "nothing is sent anywhere" in phone_js
    assert "Purchase complete" not in phone_js + chat_js
    assert "Payment Received" not in phone_js + chat_js
