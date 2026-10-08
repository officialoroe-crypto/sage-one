from pathlib import Path


WORKFLOW = Path(__file__).parents[1] / ".github" / "workflows" / "sage-one-android-apk.yml"


def test_android_release_workflow_has_device_endpoint_override_and_release_outputs():
    text = WORKFLOW.read_text(encoding="utf-8")

    assert "workflow_dispatch:" in text
    assert "api_url:" in text
    assert "SAGE_ANDROID_API_URL" in text
    assert 'dart-define=SAGE_API_URL="$SAGE_ANDROID_API_URL"' in text
    assert "http://10.0.2.2:8010" in text
    assert "flutter build apk --release" in text
    assert "flutter build appbundle --release" in text
    assert "app-release.apk" in text
    assert "app-release.aab" in text
    assert "Validated Android API endpoint" in text
