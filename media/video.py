from __future__ import annotations

import os
import re
import subprocess
import uuid
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont
import imageio_ffmpeg


class VideoRenderError(RuntimeError):
    """Raised when SAGE cannot render a video asset."""


def _safe_name(value: str) -> str:
    value = re.sub(r"[^a-zA-Z0-9_-]+", "-", value.strip()).strip("-")
    return value[:80] or "sage-video"


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        os.getenv("SAGE_VIDEO_FONT", ""),
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default()


def _wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textbbox((0, 0), trial, font=font)[2] <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [""]


def _frame(
    width: int,
    height: int,
    title: str,
    subtitle: str,
    cta: str,
    progress: float,
) -> Image.Image:
    image = Image.new("RGB", (width, height), (8, 7, 18))
    draw = ImageDraw.Draw(image)

    # Lightweight cinematic gradient; intentionally generated inside SAGE.
    for y in range(height):
        t = y / max(height - 1, 1)
        r = int(8 + 20 * t)
        g = int(7 + 12 * t)
        b = int(18 + 45 * t)
        draw.line((0, y, width, y), fill=(r, g, b))

    glow = int(width * 0.42)
    cx = int(width * (0.18 + 0.64 * progress))
    cy = int(height * 0.22)
    draw.ellipse((cx - glow, cy - glow, cx + glow, cy + glow), fill=(35, 28, 82))

    title_font = _font(max(34, width // 16), bold=True)
    body_font = _font(max(22, width // 30))
    cta_font = _font(max(20, width // 34), bold=True)

    title_lines = _wrap(draw, title, title_font, int(width * 0.82))
    body_lines = _wrap(draw, subtitle, body_font, int(width * 0.78))

    y = int(height * 0.42)
    for line in title_lines[:4]:
        bbox = draw.textbbox((0, 0), line, font=title_font)
        x = (width - (bbox[2] - bbox[0])) // 2
        draw.text((x, y), line, font=title_font, fill=(245, 244, 255))
        y += int(title_font.size * 1.15)

    y += 20
    for line in body_lines[:7]:
        bbox = draw.textbbox((0, 0), line, font=body_font)
        x = (width - (bbox[2] - bbox[0])) // 2
        draw.text((x, y), line, font=body_font, fill=(191, 193, 220))
        y += int(body_font.size * 1.35)

    if cta.strip():
        cta_bbox = draw.textbbox((0, 0), cta, font=cta_font)
        pad_x, pad_y = 34, 18
        box_w = cta_bbox[2] - cta_bbox[0] + pad_x * 2
        box_h = cta_bbox[3] - cta_bbox[1] + pad_y * 2
        x = (width - box_w) // 2
        y = int(height * 0.82)
        draw.rounded_rectangle((x, y, x + box_w, y + box_h), radius=18, fill=(105, 78, 220))
        draw.text((x + pad_x, y + pad_y - 2), cta, font=cta_font, fill=(255, 255, 255))

    return image


def render_text_video(
    *,
    title: str,
    subtitle: str = "",
    cta: str = "",
    output_dir: str | Path = "./generated_media",
    duration_seconds: float = 5.0,
    width: int = 720,
    height: int = 1280,
    fps: int = 24,
) -> Path:
    """Render a small self-contained MP4 from text using SAGE's local renderer."""
    if not title.strip():
        raise VideoRenderError("Video title cannot be empty.")
    if not 2 <= duration_seconds <= 30:
        raise VideoRenderError("duration_seconds must be between 2 and 30.")
    if width < 320 or height < 320:
        raise VideoRenderError("Video dimensions are too small.")
    if not 12 <= fps <= 30:
        raise VideoRenderError("fps must be between 12 and 30.")

    root = Path(output_dir)
    root.mkdir(parents=True, exist_ok=True)
    output = root / f"{_safe_name(title)}-{uuid.uuid4().hex[:10]}.mp4"
    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()

    command = [
        ffmpeg,
        "-y",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-pix_fmt", "rgb24",
        "-s", f"{width}x{height}",
        "-r", str(fps),
        "-i", "-",
        "-an",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-movflags", "+faststart",
        str(output),
    ]

    try:
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        assert process.stdin is not None
        total_frames = max(1, int(duration_seconds * fps))
        for index in range(total_frames):
            progress = index / max(total_frames - 1, 1)
            frame = _frame(width, height, title.strip(), subtitle.strip(), cta.strip(), progress)
            process.stdin.write(frame.tobytes())
        process.stdin.close()
        stderr = process.stderr.read().decode("utf-8", errors="replace")
        return_code = process.wait()
        if return_code != 0:
            raise VideoRenderError(f"FFmpeg failed with exit code {return_code}: {stderr[-1000:]}")
    except Exception:
        if output.exists():
            output.unlink()
        raise

    if not output.exists() or output.stat().st_size == 0:
        raise VideoRenderError("SAGE video renderer produced no output.")
    return output
