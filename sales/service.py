from __future__ import annotations

from typing import Any


def build_sales_intelligence(business_name: str, audit: dict[str, Any], score: dict[str, Any]) -> dict[str, Any]:
    services: list[str] = []
    if not audit.get("website", {}).get("present") or audit.get("website", {}).get("quality") == "weak":
        services.append("website/landing-page improvement")
    if not audit.get("social", {}).get("instagram"):
        services.append("Instagram setup and content system")
    if not audit.get("content", {}).get("video_present"):
        services.append("short-form video/reels")
    if audit.get("branding", {}).get("quality") == "weak":
        services.append("branding and visual-content refresh")
    if not services:
        services.append("social/content performance improvement")
    return {
        "business_name": business_name,
        "fit": score["tier"],
        "opportunity_score": score["score"],
        "why_fit": [signal["reason"] for signal in score["signals"]],
        "recommended_services": services,
        "next_action": "Review the audit, customize the proposal, then approve outreach.",
    }


def build_outreach(business_name: str, intelligence: dict[str, Any]) -> dict[str, Any]:
    service_text = ", ".join(intelligence["recommended_services"][:3])
    message = (f"Hi {business_name}, I came across your business and noticed a few opportunities "
               f"to improve your online presence, especially around {service_text}. "
               "I can share a short, practical audit with a few ideas specific to your business. "
               "Would you like me to send it?")
    return {"channel": "whatsapp", "message": message, "requires_owner_approval": True}
