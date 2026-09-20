"""Authenticated identity and onboarding API."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

from config.settings import settings
from identity.auth import authenticate_request, create_developer_session, get_or_create_authenticated_profile
from identity.memory import add_memory, delete_memory, list_memory, update_memory
from identity.onboarding import capability_catalog, validate_capabilities
from identity.otp import otp_manager
from identity.profile import SessionLocal, UserProfile, mark_phone_verified, upsert_profile

router = APIRouter(prefix="/identity", tags=["identity"])


class DeveloperLoginRequest(BaseModel):
    phone: str = Field(min_length=5, max_length=30)


class GoogleLoginRequest(BaseModel):
    id_token: str = Field(min_length=1, max_length=10000)


class PhoneRequest(BaseModel):
    phone: str = Field(min_length=5, max_length=30)


class OTPVerifyRequest(BaseModel):
    challenge_id: str = Field(min_length=1, max_length=200)
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class OnboardingRequest(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    phone: str = Field(min_length=5, max_length=30)
    address: str = Field(min_length=1, max_length=1000)
    age: int = Field(ge=1, le=120)
    basic_info: dict[str, Any] = Field(default_factory=dict)
    help_intent: str = Field(min_length=1, max_length=2000)
    capabilities: list[str] = Field(default_factory=list, max_length=20)
    memory_consent: bool = False


class MemoryCreateRequest(BaseModel):
    memory_type: str
    content: str = Field(min_length=1, max_length=5000)
    importance: float = Field(default=0.5, ge=0.0, le=1.0)
    confidence: float = Field(default=1.0, ge=0.0, le=1.0)
    source: str = Field(default="user", min_length=1, max_length=100)
    confirmed: bool = False


class MemoryUpdateRequest(BaseModel):
    memory_type: str | None = None
    content: str | None = Field(default=None, min_length=1, max_length=5000)
    importance: float | None = Field(default=None, ge=0.0, le=1.0)
    confidence: float | None = Field(default=None, ge=0.0, le=1.0)
    source: str | None = Field(default=None, min_length=1, max_length=100)
    confirmed: bool | None = None


def _profile_from_claims(claims: dict[str, Any]) -> dict[str, Any]:
    return get_or_create_authenticated_profile(claims)


@router.post("/dev-login")
def developer_login(request: Request, payload: DeveloperLoginRequest):
    if not settings.DEVELOPER_MODE:
        raise HTTPException(status_code=404, detail="Developer mode is disabled.")
    if not request.client or request.client.host not in {"127.0.0.1", "::1", "localhost"}:
        raise HTTPException(status_code=403, detail="Developer login is localhost-only.")
    token, claims = create_developer_session(payload.phone)
    profile = get_or_create_authenticated_profile(claims)
    return {"success": True, "developer_mode": True, "token": token, "profile": profile}


@router.get("/config")
def identity_config():
    """Return non-secret client configuration needed by web authentication."""
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=503, detail="Google authentication is not configured.")
    return {"success": True, "google_client_id": settings.GOOGLE_CLIENT_ID}


@router.post("/google")
def google_login(request: GoogleLoginRequest):
    """Verify a Google ID token server-side and create/update its SAGE profile."""
    from identity.auth import verify_google_id_token

    claims = verify_google_id_token(request.id_token)
    profile = _profile_from_claims(claims)
    return {
        "success": True,
        "identity": {
            "provider": "google",
            "subject": claims["auth_subject"],
            "email": claims.get("email"),
            "email_verified": claims.get("email_verified", False),
        },
        "profile": profile,
        "onboarding_required": not profile["onboarding_completed"],
    }


@router.get("/me")
def get_me(claims: dict[str, Any] = Depends(authenticate_request)):
    return {"success": True, "profile": _profile_from_claims(claims)}


@router.get("/onboarding/options")
def onboarding_options():
    return {"success": True, **capability_catalog()}


@router.post("/onboarding")
def complete_onboarding(
    request: OnboardingRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    profile = _profile_from_claims(claims)
    capabilities = validate_capabilities(request.capabilities)

    if not profile["phone_verified"]:
        raise HTTPException(status_code=409, detail="Phone verification is required before onboarding can be completed.")
    if profile["phone"] != request.phone:
        raise HTTPException(status_code=409, detail="The verified phone number must match onboarding.")

    updated = upsert_profile(
        auth_provider=claims["auth_provider"],
        auth_subject=claims["auth_subject"],
        email=claims.get("email"),
        name=request.name,
        phone=request.phone,
        address=request.address,
        age=request.age,
        basic_info=request.basic_info,
        help_intent=request.help_intent,
        capabilities=capabilities,
        memory_consent=request.memory_consent,
    )

    if request.memory_consent:
        add_memory(
            profile_id=updated["id"],
            memory_type="preference",
            content=f"SAGE onboarding capabilities: {', '.join(capabilities) if capabilities else 'none selected'}",
            importance=0.7,
            confidence=1.0,
            source="onboarding",
            confirmed=True,
        )

    with SessionLocal() as db:
        row = (
            db.query(UserProfile)
            .filter(
                UserProfile.auth_provider == claims["auth_provider"],
                UserProfile.auth_subject == claims["auth_subject"],
            )
            .first()
        )
        if row is None:
            raise HTTPException(status_code=500, detail="Authenticated profile disappeared during onboarding.")
        row.onboarding_completed = 1
        row.updated_at = datetime.now(timezone.utc)
        db.commit()

    return {
        "success": True,
        "onboarding_completed": True,
        "profile": _profile_from_claims(claims),
    }


@router.post("/phone/send")
def send_phone_otp(
    request: PhoneRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    owner_key = f"google:{claims['auth_subject']}"
    challenge = otp_manager.create_challenge(owner_key, request.phone)
    upsert_profile(
        auth_provider=claims["auth_provider"],
        auth_subject=claims["auth_subject"],
        phone=request.phone,
    )
    return {
        "success": True,
        "challenge_id": challenge.challenge_id,
        "expires_at": challenge.expires_at,
        "delivery": "sms_provider" if otp_manager.provider is not None else "not_configured",
    }


@router.post("/phone/verify")
def verify_phone_otp(
    request: OTPVerifyRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    owner_key = f"google:{claims['auth_subject']}"
    challenge_phone = otp_manager.challenge_phone(owner_key, request.challenge_id)
    profile = _profile_from_claims(claims)
    if challenge_phone is None or challenge_phone != profile["phone"]:
        raise HTTPException(status_code=400, detail="Invalid or expired verification challenge.")
    if not otp_manager.verify(owner_key, request.challenge_id, request.code):
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")

    updated = mark_phone_verified(claims["auth_provider"], claims["auth_subject"])
    return {"success": True, "phone_verified": True, "profile": updated}


@router.get("/memory")
def get_profile_memory(claims: dict[str, Any] = Depends(authenticate_request)):
    profile = _profile_from_claims(claims)
    return {"success": True, "memories": list_memory(profile["id"])}


@router.post("/memory")
def create_profile_memory(
    request: MemoryCreateRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    profile = _profile_from_claims(claims)
    return {
        "success": True,
        "memory": add_memory(
            profile_id=profile["id"],
            memory_type=request.memory_type,
            content=request.content,
            importance=request.importance,
            confidence=request.confidence,
            source=request.source,
            confirmed=request.confirmed,
        ),
    }


@router.patch("/memory/{memory_id}")
def edit_profile_memory(
    memory_id: str,
    request: MemoryUpdateRequest,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    profile = _profile_from_claims(claims)
    updated = update_memory(memory_id, profile["id"], **request.model_dump(exclude_unset=True))
    if updated is None:
        raise HTTPException(status_code=404, detail="Memory not found.")
    return {"success": True, "memory": updated}


@router.delete("/memory/{memory_id}")
def remove_profile_memory(
    memory_id: str,
    claims: dict[str, Any] = Depends(authenticate_request),
):
    profile = _profile_from_claims(claims)
    if not delete_memory(memory_id, profile["id"]):
        raise HTTPException(status_code=404, detail="Memory not found.")
    return {"success": True, "deleted": True}
