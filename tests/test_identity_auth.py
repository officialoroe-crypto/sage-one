import time

from identity.otp import OTPManager


def test_otp_challenge_is_bound_to_owner_and_expires():
    manager = OTPManager(ttl_seconds=60, max_attempts=2)
    challenge = manager.create_challenge("google:user-1", "+9779800000000")

    assert challenge.owner_key == "google:user-1"
    assert challenge.phone == "+9779800000000"
    assert manager.challenge_phone("google:user-2", challenge.challenge_id) is None
    assert manager.verify("google:user-2", challenge.challenge_id, "000000") is False
    assert manager.challenge_phone("google:user-1", challenge.challenge_id) == "+9779800000000"


def test_otp_wrong_codes_are_limited():
    manager = OTPManager(ttl_seconds=60, max_attempts=2)
    challenge = manager.create_challenge("google:user-1", "+9779800000000")

    assert manager.verify("google:user-1", challenge.challenge_id, "000000") is False
    assert manager.verify("google:user-1", challenge.challenge_id, "111111") is False
    assert manager.verify("google:user-1", challenge.challenge_id, "222222") is False


def test_otp_expiry_rejects_challenge():
    manager = OTPManager(ttl_seconds=1, max_attempts=2)
    challenge = manager.create_challenge("google:user-1", "+9779800000000")
    manager._challenges[challenge.challenge_id] = challenge.__class__(
        challenge_id=challenge.challenge_id,
        owner_key=challenge.owner_key,
        phone=challenge.phone,
        code_hash=challenge.code_hash,
        expires_at=time.time() - 1,
        attempts_remaining=challenge.attempts_remaining,
    )

    assert manager.challenge_phone("google:user-1", challenge.challenge_id) is None
    assert manager.verify("google:user-1", challenge.challenge_id, "000000") is False
