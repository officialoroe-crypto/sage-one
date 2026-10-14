from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "website"
PAGES = (
    SITE / "index.html",
    SITE / "chat" / "index.html",
    SITE / "app-preview" / "index.html",
)


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tags: list[tuple[str, dict[str, str | None]]] = []
        self.ids: set[str] = set()
        self.title = ""
        self.in_title = False
        self.buttons: list[dict[str, str | None]] = []
        self.button_text: list[str] = []
        self._button_depth = 0
        self.inputs: list[dict[str, str | None]] = []
        self.labels: list[dict[str, str | None]] = []
        self.images: list[dict[str, str | None]] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        item = dict(attrs)
        self.tags.append((tag, item))
        if item.get("id"):
            self.ids.add(str(item["id"]))
        if tag == "title":
            self.in_title = True
        if tag == "button":
            self.buttons.append(item)
            self.button_text.append("")
            self._button_depth += 1
        elif self._button_depth:
            self._button_depth += 1
        if tag == "input":
            self.inputs.append(item)
        if tag == "label":
            self.labels.append(item)
        if tag == "img":
            self.images.append(item)

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False
        if self._button_depth:
            self._button_depth -= 1

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title += data.strip()
        if self._button_depth and self.button_text:
            self.button_text[-1] += data.strip()

    @property
    def descriptions(self) -> list[str]:
        return [
            str(attrs.get("content", ""))
            for tag, attrs in self.tags
            if tag == "meta" and attrs.get("name") == "description"
        ]


def parse(path: Path) -> PageParser:
    parser = PageParser()
    parser.feed(path.read_text(encoding="utf-8"))
    return parser


def local_target(page: Path, raw_url: str) -> Path | None:
    parsed = urlsplit(raw_url)
    if parsed.scheme or parsed.netloc or raw_url.startswith(("data:", "mailto:", "tel:")):
        return None
    target = (page.parent / parsed.path).resolve() if parsed.path else page.resolve()
    if target.is_dir():
        target = target / "index.html"
    return target


def test_every_website_page_has_core_metadata_and_favicon() -> None:
    for page in PAGES:
        parser = parse(page)
        assert parser.title.strip(), f"{page.relative_to(ROOT)} is missing a title"
        assert parser.descriptions and parser.descriptions[0].strip(), (
            f"{page.relative_to(ROOT)} is missing a meta description"
        )
        assert any(
            tag == "meta" and attrs.get("name") == "viewport"
            for tag, attrs in parser.tags
        ), f"{page.relative_to(ROOT)} is missing a viewport meta tag"
        assert any(
            tag == "link" and attrs.get("rel") == "icon"
            for tag, attrs in parser.tags
        ), f"{page.relative_to(ROOT)} is missing a favicon"
        for image in parser.images:
            assert image.get("alt") is not None, (
                f"Image without alt attribute in {page.relative_to(ROOT)}: {image.get('src')}"
            )


def test_local_links_and_page_assets_resolve() -> None:
    failures: list[str] = []
    for page in PAGES:
        parser = parse(page)
        for tag, attrs in parser.tags:
            raw_url = attrs.get("href") if tag in {"a", "link"} else (
                attrs.get("src") if tag in {"script", "img"} else None
            )
            if not raw_url:
                continue
            target = local_target(page, str(raw_url))
            if target is None:
                continue
            if not target.exists():
                failures.append(f"{page.relative_to(ROOT)} -> {raw_url}")
                continue
            if tag == "a" and urlsplit(str(raw_url)).fragment:
                fragment = urlsplit(str(raw_url)).fragment
                if target == page.resolve() and fragment not in parser.ids:
                    failures.append(f"{page.relative_to(ROOT)} -> missing #{fragment}")
    assert not failures, "Broken local links/assets:\n" + "\n".join(failures)


def test_buttons_and_form_controls_have_accessible_names() -> None:
    for page in PAGES:
        parser = parse(page)
        for button, text in zip(parser.buttons, parser.button_text, strict=False):
            assert button.get("aria-label") or text.strip(), (
                f"Unnamed button in {page.relative_to(ROOT)}"
            )
        label_ids = {str(label.get("for")) for label in parser.labels if label.get("for")}
        for item in parser.inputs:
            if item.get("type") == "hidden":
                continue
            assert (
                item.get("aria-label")
                or item.get("aria-labelledby")
                or (item.get("id") and str(item["id"]) in label_ids)
            ), f"Unlabelled input in {page.relative_to(ROOT)}: {item}"


def test_mobile_menu_is_connected_and_copyright_is_dynamic() -> None:
    html = (SITE / "index.html").read_text(encoding="utf-8")
    css = (SITE / "styles.css").read_text(encoding="utf-8")
    js = (SITE / "app.js").read_text(encoding="utf-8")
    assert 'id="menuToggle"' in html and 'id="primaryNav"' in html
    assert 'aria-controls="primaryNav"' in html and 'aria-expanded="false"' in html
    assert ".topbar nav.is-open" in css and "@media (max-width: 760px)" in css
    assert "function setMenuOpen" in js and "event.key === 'Escape'" in js
    assert 'id="copyrightYear"' in html and "new Date().getFullYear()" in js
    assert 'class="hero-logo-link" href="#top"' in html
    assert "243 backend tests passing" not in html
    assert "Implemented in code (verification varies)" in html
    assert "being built as a personal AI mentor" in html


def _luminance(hex_color: str) -> float:
    channels = [int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [
        value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
        for value in channels
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def _contrast_ratio(first: str, second: str) -> float:
    high, low = sorted((_luminance(first), _luminance(second)), reverse=True)
    return (high + 0.05) / (low + 0.05)


def test_core_text_palette_meets_wcag_aa_contrast_on_dark_surfaces() -> None:
    import re

    css = (SITE / "styles.css").read_text(encoding="utf-8")
    variables = dict(re.findall(r"--([a-z0-9-]+):\s*(#[0-9a-fA-F]{6})\s*;", css))
    backgrounds = ("bg", "surface", "surface-2")
    text_tokens = ("fg", "muted", "cyan", "blue", "violet", "gold", "ok", "fail")
    for token in backgrounds + text_tokens:
        assert token in variables, f"Missing CSS color token --{token}"
    for token in text_tokens:
        for background in backgrounds:
            ratio = _contrast_ratio(variables[token], variables[background])
            assert ratio >= 4.5, (
                f"--{token} on --{background} has contrast {ratio:.2f}:1, below WCAG AA 4.5:1"
            )
