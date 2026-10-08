from __future__ import annotations

import re
from typing import Any
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup


class BusinessAuditor:
    timeout_seconds = 8

    def audit(self, website_url: str | None, social_urls: dict[str, str] | None = None) -> dict[str, Any]:
        social = dict(social_urls or {})
        result: dict[str, Any] = {
            "website": {"present": bool(website_url), "reachable": False, "quality": "missing", "cta_present": False, "page_words": 0},
            "social": {"instagram": social.get("instagram"), "facebook": social.get("facebook"), "youtube": social.get("youtube")},
            "content": {"video_present": False, "consistency": "unknown"},
            "branding": {"quality": "unknown"},
            "contact": {"present": False},
            "warnings": [],
        }
        if not website_url:
            result["branding"]["quality"] = "unknown"
            return result
        try:
            response = requests.get(website_url, timeout=self.timeout_seconds, headers={"User-Agent": "SAGE-One-Sales-Audit/1.0"})
            response.raise_for_status()
            soup = BeautifulSoup(response.text, "html.parser")
            text = " ".join(soup.stripped_strings)
            lower = text.lower()
            links = [urljoin(response.url, a.get("href")) for a in soup.find_all("a", href=True)]
            result["website"].update({
                "present": True,
                "reachable": True,
                "final_url": response.url,
                "status_code": response.status_code,
                "page_words": len(text.split()),
                "title": (soup.title.string.strip() if soup.title and soup.title.string else None),
                "cta_present": bool(re.search(r"contact|call|book|quote|order|shop|whatsapp|get started", lower)),
                "quality": "good" if len(text.split()) >= 150 else "weak",
            })
            result["social"].update({
                "instagram": result["social"].get("instagram") or next((x for x in links if "instagram.com" in x.lower()), None),
                "facebook": result["social"].get("facebook") or next((x for x in links if "facebook.com" in x.lower()), None),
                "youtube": result["social"].get("youtube") or next((x for x in links if "youtube.com" in x.lower() or "youtu.be" in x.lower()), None),
            })
            result["content"]["video_present"] = bool(soup.find("video") or "youtube.com" in lower or "youtu.be" in lower or "video" in lower)
            result["branding"]["quality"] = "good" if soup.find("img") and soup.find("title") else "weak"
            result["contact"]["present"] = bool(re.search(r"[\\w.+-]+@[\\w-]+\\.[\\w.-]+|(?:\\+?\\d[\\d ()-]{7,})", text)) or bool(result["website"].get("cta_present"))
        except Exception as exc:
            result["warnings"].append(str(exc)[:300])
            result["website"]["quality"] = "weak"
        return result


auditor = BusinessAuditor()
