from pathlib import Path

ROOT = Path(__file__).parents[1]
SYSTEM_SCREEN = ROOT / "website" / "js" / "screens-system.js"
APP_CONTROLLER = ROOT / "website" / "js" / "app.js"
BACKEND_BRIDGE = ROOT / "website" / "js" / "backend.js"


def test_earnings_screen_does_not_claim_a_mock_payment_was_received():
    source = SYSTEM_SCREEN.read_text(encoding="utf-8")
    assert "Real cash earnings are not connected" in source
    assert "No payment has been received or credited by this screen." in source
    assert "Payment Received — Play the 7-Stage Animation" not in source
    assert "Lifetime journey income" not in source


def test_reward_animation_is_labeled_as_preview_not_a_transaction():
    source = SYSTEM_SCREEN.read_text(encoding="utf-8")
    assert "Preview the 7-Stage Animation" in source
    assert "Visual preview only. This does not create a payment, grant Spark, or confirm an earning." in source
    assert "Verified Spark movements appear in the authenticated Spark Wallet ledger." in source


def test_earnings_screen_links_to_backend_backed_spark_wallet():
    source = SYSTEM_SCREEN.read_text(encoding="utf-8")
    assert 'data-act="nav" data-arg="spark">Open live Spark Wallet</button>' in source
    assert "Buy Spark · unavailable" in source
    assert "Send Spark · unavailable" in source
    assert "Withdraw to Bank" not in source


def test_provider_dependent_actions_are_blocked_by_the_backend_bridge():
    source = BACKEND_BRIDGE.read_text(encoding="utf-8")
    assert "const DEMO_ONLY = new Set([" in source
    for action in (
        "kyc-start", "kyc-done", "premium-upgrade", "premium-confirm",
        "buy-spark", "send-spark", "withdraw", "buy-listing", "buy-confirm",
        "gen-image", "gen-video", "apply-job", "enroll", "course-complete",
        "sell-submit", "wf-run", "ai-provider",
    ):
        assert "'" + action + "'" in source
    assert "No transaction was made." in source


def test_unconnected_actions_never_claim_success_or_mutate_local_economy():
    source = APP_CONTROLLER.read_text(encoding="utf-8")
    for misleading_claim in (
        "Purchase complete ✓", "Listing published!", "Application sent ✓",
        "Enrolled ✓", "Module ' + (+parts[1] + 1) + ' complete ✓",
        "KYC verified ✓", "Signed in with Google ✓", "Account created · OTP verified ✓",
        "SAGE Premium active ✓",
    ):
        assert misleading_claim not in source
    assert "No purchase or Spark movement occurred." in source
    assert "No listing was published and no earnings were credited." in source
    assert "No application was sent." in source
    assert "No progress reward was granted." in source
    assert "st.earnings.marketplace +=" not in source
    assert "st.lifetimeEarned +=" not in source
    assert "S.addSpark(-5, 'Image generated')" not in source


def test_files_filter_control_is_connected_to_its_action_handler():
    source = APP_CONTROLLER.read_text(encoding="utf-8")
    assert "case 'files-tab': S.setFilesTab(arg); break;" in source
