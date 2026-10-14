from pathlib import Path

ROOT = Path(__file__).parents[1]
SYSTEM_SCREEN = ROOT / "website" / "js" / "screens-system.js"
APP_CONTROLLER = ROOT / "website" / "js" / "app.js"


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


def test_purchase_transfer_and_withdrawal_actions_never_mutate_local_balance():
    source = APP_CONTROLLER.read_text(encoding="utf-8")
    guarded_actions = source[source.index("/* --- Spark and cash:"):source.index("/* --- evolution --- */")]
    assert "Purchases are not connected yet" in guarded_actions
    assert "Spark transfers are not available yet" in guarded_actions
    assert "Cash payouts are not connected yet" in guarded_actions
    assert "S.addSpark(" not in guarded_actions
    assert "Withdrawal of " not in guarded_actions



def test_every_reward_animation_entry_is_preview_only():
    source = APP_CONTROLLER.read_text(encoding="utf-8")
    assert "case 'sim-earn': S.closeSheet(); S.playEarning(5000, { source: 'Animation Preview', preview: true, noCredit: true }); break;" in source
    assert "case 'earn-tier': S.closeSheet(); S.playEarning(+arg, { source: 'Reward Animation Preview', preview: true, noCredit: true }); break;" in source



def test_unconnected_marketplace_jobs_and_generation_never_claim_success():
    source = APP_CONTROLLER.read_text(encoding="utf-8")
    assert "Marketplace checkout is not connected" in source
    assert "Marketplace publishing is not connected" in source
    assert "Job application was not sent" in source
    assert "AI generation provider is not connected" in source
    assert "Purchase complete ✓" not in source
    assert "Listing published!" not in source
    assert "Application sent ✓" not in source
    assert "Video rendered ✓" not in source
    assert "S.addSpark(-5, 'Image generated')" not in source
    assert "st.earnings.content += 15" not in source


def test_files_filter_control_is_connected_to_its_action_handler():
    source = APP_CONTROLLER.read_text(encoding="utf-8")
    assert "case 'files-tab': S.setFilesTab(arg); break;" in source
