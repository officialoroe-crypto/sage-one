from __future__ import annotations

from typing import Any


def score_opportunity(audit: dict[str, Any]) -> dict[str, Any]:
    """Return a transparent 0-100 sales opportunity score."""
    signals: list[dict[str, Any]] = []
    score = 0.0

    def add(key: str, points: int, reason: str, condition: bool) -> None:
        nonlocal score
        if condition:
            score += points
            signals.append({"key": key, "points": points, "reason": reason})

    add("no_website", 20, "No public website was found.", not audit.get("website", {}).get("present", False))
    add("weak_website", 15, "Website appears thin or lacks useful business content.", audit.get("website", {}).get("quality") == "weak")
    add("no_instagram", 15, "No Instagram presence was detected.", not audit.get("social", {}).get("instagram"))
    add("no_video", 15, "No video/reel signal was detected.", not audit.get("content", {}).get("video_present", False))
    add("inconsistent_content", 10, "Content activity appears inconsistent.", audit.get("content", {}).get("consistency") == "weak")
    add("weak_branding", 10, "Branding/content signals appear weak or inconsistent.", audit.get("branding", {}).get("quality") == "weak")
    add("missing_cta", 5, "No clear call-to-action was detected.", not audit.get("website", {}).get("cta_present", False))
    add("missing_contact", 5, "No obvious public contact signal was detected.", not audit.get("contact", {}).get("present", False))

    return {
        "score": min(100.0, score),
        "signals": signals,
        "tier": "hot" if score >= 60 else "warm" if score >= 35 else "cold",
    }
