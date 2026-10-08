from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Any, Protocol


@dataclass
class BusinessCandidate:
    business_name: str
    location: str | None = None
    website_url: str | None = None
    social_urls: dict[str, str] | None = None
    contact: dict[str, Any] | None = None
    source: str = "provider"


class DiscoveryProvider(Protocol):
    def search(self, query: str, location: str | None = None, limit: int = 10) -> list[BusinessCandidate]: ...


class MockDiscoveryProvider:
    def __init__(self, candidates: list[BusinessCandidate] | None = None):
        self.candidates = candidates or []

    def search(self, query: str, location: str | None = None, limit: int = 10) -> list[BusinessCandidate]:
        return self.candidates[:limit]


class DuckDuckGoDiscoveryProvider:
    """Lightweight discovery adapter; network work stays outside the API contract."""

    def search(self, query: str, location: str | None = None, limit: int = 10) -> list[BusinessCandidate]:
        try:
            from ddgs import DDGS
        except ImportError as exc:
            raise RuntimeError("The DDGS discovery dependency is not installed.") from exc
        search_query = f"{query} {location or ''}".strip()
        results = DDGS().text(search_query, max_results=limit)
        candidates: list[BusinessCandidate] = []
        for item in results:
            url = item.get("href") or item.get("url")
            title = item.get("title") or item.get("body") or "Unknown business"
            candidates.append(BusinessCandidate(business_name=title[:200], location=location, website_url=url, source="duckduckgo"))
        return candidates


class DiscoveryService:
    def __init__(self, provider: DiscoveryProvider | None = None):
        self.provider = provider or DuckDuckGoDiscoveryProvider()

    def search(self, query: str, location: str | None = None, limit: int = 10) -> list[dict[str, Any]]:
        return [asdict(item) for item in self.provider.search(query.strip(), location, limit)]


discovery_service = DiscoveryService()
