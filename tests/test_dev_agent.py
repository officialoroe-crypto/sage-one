from pathlib import Path

import pytest

from dev_agent.policy import AgentPolicy


def test_policy_allows_source_and_tests(tmp_path: Path):
    policy = AgentPolicy(tmp_path)
    assert policy.can_write("dev_agent/example.py")
    assert policy.can_write("tests/test_example.py")


def test_policy_blocks_secrets_and_git(tmp_path: Path):
    policy = AgentPolicy(tmp_path)
    assert not policy.can_write(".env")
    assert not policy.can_write("config/.env")
    assert not policy.can_write(".git/config")
    with pytest.raises(PermissionError):
        policy.assert_write_allowed(".env")


def test_policy_blocks_remote_and_destructive_commands(tmp_path: Path):
    policy = AgentPolicy(tmp_path)
    with pytest.raises(PermissionError):
        policy.validate_check_command("git push origin main")
    with pytest.raises(PermissionError):
        policy.validate_check_command("git reset --hard HEAD")


def test_policy_allows_read_only_git_checks(tmp_path: Path):
    policy = AgentPolicy(tmp_path)
    assert policy.validate_check_command("git status --short")
    assert policy.validate_check_command("python -m py_compile dev_agent/policy.py")
