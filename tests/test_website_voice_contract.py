from pathlib import Path

ROOT = Path(__file__).parents[1]
WEBSITE = ROOT / "website"


def test_workspace_entry_point_loads_the_voice_enabled_app():
    html = (WEBSITE / "index.html").read_text(encoding="utf-8")
    assert 'src="js/screens-home.js' in html
    assert 'src="js/backend.js' in html
    assert 'id="screen"' in html
    assert 'id="tabbar"' in html


def test_home_has_a_visible_voice_command_entry():
    home = (WEBSITE / "js" / "screens-home.js").read_text(encoding="utf-8")
    assert 'data-act="voice-toggle"' in home
    assert 'aria-label="Start voice command"' in home
    assert "<span>VOICE</span>" in home


def test_voice_uses_selected_language_and_waits_for_user_to_send():
    backend = (WEBSITE / "js" / "backend.js").read_text(encoding="utf-8")
    assert "recognition.lang = S.state().lang === 'ne' ? 'ne-NP' : 'en-US';" in backend
    assert "VOICE CAPTURED · REVIEW BEFORE SENDING" in backend
    start = backend.index("  function startVoice(selector) {")
    end = backend.index("\n  function loadGoogleScript()", start)
    voice_handler = backend[start:end]
    assert "tap Send when ready" in voice_handler
    assert "S.sendChat(" not in voice_handler
    assert "queueLastRequest(" not in voice_handler



def test_web_voice_speaks_only_voice_triggered_answers_and_has_stop_control():
    backend = (WEBSITE / "js" / "backend.js").read_text(encoding="utf-8")

    assert "window.speechSynthesis.speak(utterance);" in backend
    assert "if (speakThisResponse) speak(answer);" in backend
    assert "if (name === 'voice-stop') { stopSpeaking(); return; }" in backend
    assert "button.textContent = 'Stop SAGE speaking';" in backend
    assert "S.state().lang === 'ne' ? 'ne-NP' : 'en-US'" in backend
