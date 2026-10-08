from pathlib import Path


WORKFLOW = Path(__file__).parents[1] / ".github" / "workflows" / "sage-one-android-apk.yml"


def test_android_workflow_accepts_device_reachable_api_url():
    text = WORKFLOW.read_text(encoding="utf-8")

    assert "workflow_dispatch:" in text
    assert "api_url:" in text
    assert "SAGE_ANDROID_API_URL" in text
    assert 'dart-define=SAGE_API_URL="$SAGE_ANDROID_API_URL"' in text
    assert "http://10.0.2.2:8010" in text  # Android emulator host-loopback default
