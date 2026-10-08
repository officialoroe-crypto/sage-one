from __future__ import annotations

import json
from typing import Any
from urllib.parse import urlparse

from web.reader import WebReader


class SalesEngine:
    """Bounded sales intelligence pipeline.

    Discovery is represented by the supplied business. Audit is read-only.
    Scoring and outreach preparation are deterministic and transparent.
    Outreach is always approval-gated and never sent by this engine.
    """

    def __init__(self, reader: WebReader | None = None):
        self.reader = reader or WebReader(timeout=12, max_chars=30000)

    @staticmethod
    def _score_page(content: str, title: str | None) -> dict[str, Any]:
        text = f"{title or ''} {content}".lower()
        checks = {
            "website_presence": 15,
            "clear_cta": 15 if any(x in text for x in ("contact", "call us", "whatsapp", "quote", "get started")) else 0,
            "branding": 15 if any(x in text for x in ("about", "our story", "brand", "quality")) else 0,
            "content": 15 if any(x in text for x in ("blog", "news", "gallery", "video", "project", "portfolio")) else 0,
            "trust": 15 if any(x in text for x in ("review", "testimonial", "trusted", "years", "experience")) else 0,
        }
        if content:
            checks["website_presence"] = 15
        return checks

    def audit_business(self, business_name: str, website: str | None, instagram: str | None, notes: str | None) -> dict[str, Any]:
        page = None
        website_valid = bool(website and urlparse(website).scheme in {"http", "https"} and urlparse(website).netloc)
        if website_valid:
            page = self.reader.read(website)

        content = (page or {}).get("content", "") if page else ""
        title = (page or {}).get("title") if page else None
        checks = self._score_page(content, title)
        if not website_valid:
            checks["website_presence"] = 0

        if instagram:
            checks["social_presence"] = 10
        else:
            checks["social_presence"] = 0

        score = max(0, min(100, sum(checks.values())))
        tier = "hot" if score < 45 else "warm" if score < 70 else "nurture"
        gaps = [key for key, value in checks.items() if value == 0]

        draft = (
            f"Hi {business_name}, I checked your online presence and found a few quick opportunities "
            f"to improve visibility and customer conversion. The biggest gaps I found are: "
            f"{', '.join(gaps[:4]) or 'no major gaps detected'}. "
            "I can show you a short improvement plan if you're interested."
        )
        return {
            "success": True,
            "workflow": ["discovery", "audit", "score", "lead", "intelligence", "outreach_draft"],
            "lead": {
                "business_name": business_name.strip(),
                "website": website,
                "instagram": instagram,
                "score": score,
                "tier": tier,
                "gaps": gaps,
                "audit": checks,
                "source": page.get("final_url") if page else website,
                "notes": notes,
            },
            "intelligence": {
                "opportunity": "Improve digital presence and conversion where gaps were detected.",
                "priority": "high" if score < 45 else "medium",
            },
            "outreach": {
                "channel": "whatsapp_draft",
                "requires_approval": True,
                "sent": False,
                "draft": draft,
            },
        }

    def run_from_task(self, description: str, task_id: str, owner_key: str | None, project_id: str | None, profile_id: str | None) -> dict[str, Any]:
        del task_id, owner_key, project_id, profile_id
        try:
            payload = json.loads(description)
        except json.JSONDecodeError as exc:
            raise ValueError("Sales task payload is invalid JSON.") from exc
        business_name = str(payload.get("business_name") or "").strip()
        if not business_name:
            raise ValueError("Sales task requires business_name.")
        return self.audit_business(
            business_name=business_name,
            website=payload.get("website"),
            instagram=payload.get("instagram"),
            notes=payload.get("notes"),
        )


sales_engine = SalesEngine()
