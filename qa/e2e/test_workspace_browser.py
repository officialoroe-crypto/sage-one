from __future__ import annotations

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

from playwright.sync_api import sync_playwright


ROOT = Path(__file__).resolve().parents[2] / "website"


class QuietHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, *_args):
        pass


def test_workspace_routes_and_real_controls_in_browser():
    server = ThreadingHTTPServer(("127.0.0.1", 0), QuietHandler)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    errors = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1280, "height": 900})
            page.on("pageerror", lambda error: errors.append(str(error)))
            response = page.goto(f"http://127.0.0.1:{server.server_port}/", wait_until="networkidle")
            assert response and response.status == 200
            page.wait_for_function("Boolean(window.SAGE && window.SAGE.screens && window.SAGE.go)")

            # Exercise the actual router and rendered controls in the running browser.
            page.evaluate("window.SAGE.go('earn')")
            assert page.get_by_role("heading", name="Rewards & Earnings").is_visible()
            assert page.get_by_text("Real cash earnings are not connected").is_visible()
            page.get_by_role("button", name="Open live Spark Wallet").click()
            assert page.get_by_role("heading", name="Spark Wallet").is_visible()
            assert page.get_by_role("button", name="Buy Spark · unavailable").is_disabled()
            assert page.get_by_role("button", name="Send Spark · unavailable").is_disabled()

            # Check the visible voice entry on the home workspace. A headless browser
            # cannot prove real microphone/audio behavior; physical-device QA remains needed.
            page.evaluate("window.SAGE.go('home')")
            voice_controls = page.locator('[data-act="voice-toggle"]')
            assert voice_controls.count() >= 1

            # Confirm the page remains usable after navigating to the chat workspace.
            page.evaluate("window.SAGE.go('chat')")
            assert page.locator(".view").count() == 1
            assert page.locator(".view").inner_text().strip()
            assert errors == [], "Uncaught browser errors: " + " | ".join(errors)
            browser.close()
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=2)
