from pathlib import Path


ROOT = Path(__file__).parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"


def test_python_setup_action_uses_node24_compatible_major():
    ci = (WORKFLOWS / "ci.yml").read_text(encoding="utf-8")
    assert "actions/setup-python@v6" in ci
    assert "actions/setup-python@v5" not in ci


def test_workflow_actions_use_current_compatible_majors():
    android = (WORKFLOWS / "sage-one-android-apk.yml").read_text(encoding="utf-8")
    pages = (WORKFLOWS / "sage-one-god-mode-pages.yml").read_text(encoding="utf-8")

    assert "actions/checkout@v6" in android
    assert "actions/upload-artifact@v7" in android
    assert "actions/upload-artifact@v5" not in android
    assert "actions/checkout@v6" in pages
    assert "actions/upload-artifact@v7" in pages
    assert "retention-days: 7" in pages

    # Publishing is paused during the product rebuild. CI may validate and
    # upload a QA artifact, but it must not package or deploy GitHub Pages.
    assert "package-marketing-site:" not in pages
    assert "deploy-marketing-site:" not in pages
    assert "actions/upload-pages-artifact@" not in pages
    assert "actions/deploy-pages@" not in pages
    assert "Upload workspace source for private QA" in pages
    assert "retention-days: 7" in pages
    assert "deploy-website:" not in pages

def test_web_qa_build_targets_live_https_backend_and_smoke_checks_main():
    pages = (WORKFLOWS / "sage-one-god-mode-pages.yml").read_text(encoding="utf-8")

    assert "SAGE_API_URL: ${{ vars.SAGE_API_URL || 'https://sage-one-api.onrender.com' }}" in pages
    assert '--dart-define="SAGE_API_URL=$SAGE_API_URL"' in pages
    assert "flutter build web --release --base-href / --dart-define=" in pages
    assert "backend-smoke:" in pages
    assert "if: github.event_name != 'pull_request'" in pages
    assert 'get_json("/health")' in pages
    assert 'get_json("/identity/config")' in pages
    assert 'identity.get("google_client_id", "")' in pages
    assert "SAGE_API_URL must use HTTPS" in pages


def test_github_workflows_pin_runner_image_to_ubuntu_24_04():
    for path in WORKFLOWS.glob("*.yml"):
        content = path.read_text(encoding="utf-8")
        if "runs-on:" in content:
            assert "runs-on: ubuntu-latest" not in content, path.name
            assert "runs-on: ubuntu-24.04" in content, path.name
