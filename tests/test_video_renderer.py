from pathlib import Path

import pytest

from media.video import VideoRenderError, render_text_video


def test_render_text_video_creates_mp4(tmp_path: Path):
    output = render_text_video(
        title="SAGE Demo",
        subtitle="Created inside SAGE ONE.",
        cta="Contact us",
        output_dir=tmp_path,
        duration_seconds=2,
        width=320,
        height=320,
        fps=12,
    )

    assert output.exists()
    assert output.suffix == ".mp4"
    assert output.stat().st_size > 0


@pytest.mark.parametrize(
    "kwargs",
    [
        {"title": ""},
        {"title": "SAGE", "duration_seconds": 1},
        {"title": "SAGE", "duration_seconds": 31},
        {"title": "SAGE", "fps": 10},
    ],
)
def test_render_text_video_rejects_invalid_input(tmp_path: Path, kwargs):
    with pytest.raises(VideoRenderError):
        render_text_video(output_dir=tmp_path, **kwargs)
