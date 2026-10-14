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

    # The public Pages workflow is intentionally manual-dispatch only.
    # Its public artifact must contain the marketing site, never the Flutter app.
    assert "actions/upload-pages-artifact@v5" in pages
    assert "actions/deploy-pages@v5" in pages
    package = pages.split("  package-marketing-site:", maxsplit=1)[1].split(
        "  deploy-marketing-site:", maxsplit=1
    )[0]
    deploy = pages.split("  deploy-marketing-site:", maxsplit=1)[1]

    assert "if: github.event_name == 'workflow_dispatch'" in package
    assert "if: github.event_name == 'workflow_dispatch'" in deploy
    assert "cp website/index.html website/styles.css website/app.js website/favicon.svg public_site/" in package
    assert "frontend/build/web" not in package
    assert "needs:\n      - validate\n      - package-marketing-site" in deploy
    assert "deploy-website:" not in pages


def test_github_workflows_pin_runner_image_to_ubuntu_24_04():
    for path in WORKFLOWS.glob("*.yml"):
        content = path.read_text(encoding="utf-8")
        if "runs-on:" in content:
            assert "runs-on: ubuntu-latest" not in content, path.name
            assert "runs-on: ubuntu-24.04" in content, path.name
