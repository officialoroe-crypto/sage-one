from pathlib import Path

ROOT = Path(__file__).parents[1]
WEBSITE = ROOT / "website"


def test_chat_and_phone_previews_have_visible_voice_controls():
    chat = (WEBSITE / "chat" / "index.html").read_text(encoding="utf-8")
    phone = (WEBSITE / "app-preview" / "index.html").read_text(encoding="utf-8")
    assert 'id="micBtn"' in chat
    assert 'aria-label="Speak to SAGE"' in chat
    assert 'id="mic"' in phone
    assert 'aria-label="Speak to SAGE"' in phone


def test_preview_voice_has_browser_support_fallbacks_and_truthful_scope():
    chat_html = (WEBSITE / "chat" / "index.html").read_text(encoding="utf-8")
    chat_js = (WEBSITE / "chat" / "chat.js").read_text(encoding="utf-8")
    phone_js = (WEBSITE / "app-preview" / "app.js").read_text(encoding="utf-8")
    assert "sign-in is simulated on this page" in chat_html
    assert "window.SpeechRecognition || window.webkitSpeechRecognition" in chat_js
    assert "Voice input is not available in this browser or preview." in chat_js
    assert "window.SpeechRecognition || window.webkitSpeechRecognition" in phone_js
    assert "Voice is not available here. Type your message." in phone_js
    assert "function speak(text)" in phone_js
    assert "window.speechSynthesis.speak(new window.SpeechSynthesisUtterance(text));" in phone_js


def test_preview_voice_and_chat_do_not_claim_a_live_backend_connection():
    chat_js = (WEBSITE / "chat" / "chat.js").read_text(encoding="utf-8")
    phone_js = (WEBSITE / "app-preview" / "app.js").read_text(encoding="utf-8")
    assert "there is no backend call on this page" in chat_js
    assert "nothing is sent anywhere" in phone_js
    assert "fetch(" not in chat_js
    assert "fetch(" not in phone_js
