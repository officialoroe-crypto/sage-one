from pathlib import Path


WORKFLOWS = Path(__file__).parents[1] / ".github" / "workflows"


def test_python_setup_action_uses_node24_compatible_major():
    ci = (WORKFLOWS / "ci.yml").read_text(encoding="utf-8")
    assert "actions/setup-python@v6" in ci
    assert "actions/setup-python@v5" not in ci


def test_workflow_actions_use_current_compatible_majors():
    android = (WORKFLOWS / "sage-one-android-apk.yml").read_text(encoding="utf-8")
    pages = (WORKFLOWS / "sage-one-god-mode-pages.yml").read_text(encoding="utf-8")

    assert "actions/checkout@v6" in android
    assert "actions/upload-artifact@v5" in android
    assert "actions/checkout@v6" in pages
