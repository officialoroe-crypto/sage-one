"""Trusted Google identity verification for SAGE ONE.

The client may present a Google ID token, but SAGE never trusts the decoded
client payload. Verification happens server-side against Google's published
signing keys and the configured OAuth client ID.
"""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, Request
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from config.settings import settings
from identity.profile import get_profile, upsert_profile


def verify_google_id_token(raw_token: str) -> dict[str, Any]:
    if not raw_token or not raw_token.strip():
        raise HTTPException(status_code=401, detail="Google ID token is required.")
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=503, detail="Google authentication is not configured.")

    try:
        claims = id_token.verify_oauth2_token(
            raw_token.strip(),
            google_requests.Request(),
            settings.GOOGLE_CLIENT_ID,
        )
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="Invalid Google ID token.") from exc

    subject = claims.get("sub")
    issuer = claims.get("iss")
    if not subject or issuer not in {"accounts.google.com", "https://accounts.google.com"}:
        raise HTTPException(status_code=401, detail="Invalid Google identity claims.")

    return {
        "auth_provider": "google",
        "auth_subject": str(subject),
        "email": claims.get("email"),
        "email_verified": bool(claims.get("email_verified")),
        "name": claims.get("name"),
        "picture": claims.get("picture"),
    }


def authenticate_request(request: Request) -> dict[str, Any]:
    header = request.headers.get("Authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Bearer Google ID token required.")
    return verify_google_id_token(token)


def get_or_create_authenticated_profile(claims: dict[str, Any]) -> dict[str, Any]:
    existing = get_profile(claims["auth_provider"], claims["auth_subject"])
    if existing:
        # Refresh trusted Google display claims, but never overwrite user-entered
        # onboarding fields such as address, age, or phone.
        return upsert_profile(
            auth_provider=claims["auth_provider"],
            auth_subject=claims["auth_subject"],
            email=claims.get("email"),
            name=claims.get("name"),
        )

    return upsert_profile(
        auth_provider=claims["auth_provider"],
        auth_subject=claims["auth_subject"],
        email=claims.get("email"),
        name=claims.get("name"),
    )
