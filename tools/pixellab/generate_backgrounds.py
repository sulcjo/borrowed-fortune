#!/usr/bin/env python3
"""Generate Persian-miniature-style location background PNGs via pixellab's pixflux API.

Offline dev tool. Never runs inside the shipped game. See tools/pixellab/README.md
for setup and usage.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
LOCATIONS_PATH = SCRIPT_DIR / "locations.json"
BACKGROUNDS_DIR = REPO_ROOT / "assets" / "backgrounds"
ENV_PATH = REPO_ROOT / ".env"

STYLE_CLAUSE = (
    "Persian miniature painting, flat gouache color fields, ochre and lapis "
    "palette, 11th-century Khorasan architecture, illuminated manuscript "
    "background"
)
NEGATIVE_DESCRIPTION = (
    "photorealistic, 3d render, modern clothing, modern buildings, gradient "
    "shading, blur, text, watermark, signature"
)
IMAGE_SIZE = {"width": 320, "height": 180}
GENERATION_PARAMS = dict(
    outline="single color black outline",
    shading="flat shading",
    detail="low detail",
    view="side",
    no_background=False,
    text_guidance_scale=8,
)


def load_locations(path: Path = LOCATIONS_PATH) -> list[dict]:
    with path.open() as f:
        return json.load(f)


def build_description(entry: dict) -> str:
    return f"{STYLE_CLAUSE}, {entry['description']}"


def compute_seed(output_name: str) -> int:
    """Deterministic seed from the output filename, so re-running the script
    for a single location reproduces the same image rather than drawing a
    new random one."""
    digest = hashlib.sha256(output_name.encode("utf-8")).hexdigest()
    return int(digest[:8], 16) % 1_000_000


def generate_location(client, entry: dict, backgrounds_dir: Path) -> tuple[float, Path]:
    """Generates one image and saves it to every chapter id sharing this
    location - only chapter-id-named files ever land on disk (matching
    ChapterView's res://assets/backgrounds/<chapter_id>.png lookup). The
    location's own "output" name is a logical key only (used for --force
    matching and log messages) and never becomes a path on disk."""
    response = client.generate_image_pixflux(
        description=build_description(entry),
        image_size=IMAGE_SIZE,
        negative_description=NEGATIVE_DESCRIPTION,
        seed=compute_seed(entry["output"]),
        **GENERATION_PARAMS,
    )
    image = response.image.pil_image()
    backgrounds_dir.mkdir(parents=True, exist_ok=True)
    chapter_paths = [backgrounds_dir / f"{chapter_id}.png" for chapter_id in entry["chapter_ids"]]
    for chapter_path in chapter_paths:
        image.save(chapter_path)
    return response.usage.usd, chapter_paths[0]


def run(client, locations: list[dict], force, backgrounds_dir: Path = BACKGROUNDS_DIR) -> list[str]:
    """force: None (skip anything already on disk), True (regenerate everything),
    or an output filename string (regenerate just that one location).
    Returns the list of output filenames that failed to generate."""
    total_cost = 0.0
    failures: list[str] = []
    for entry in locations:
        primary_path = backgrounds_dir / f"{entry['chapter_ids'][0]}.png"
        should_force = force is True or force == entry["output"]
        if primary_path.exists() and not should_force:
            print(f"skip {entry['output']} (already exists)")
            continue
        try:
            cost, path = generate_location(client, entry, backgrounds_dir)
        except Exception as exc:
            print(f"FAILED {entry['output']}: {exc}")
            failures.append(entry["output"])
            continue
        total_cost += cost
        print(f"generated {entry['output']} -> {path} (${cost:.4f})")
    print(f"total spent this run: ${total_cost:.4f}")
    if failures:
        print(f"failed: {', '.join(failures)}")
    return failures


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        nargs="?",
        const=True,
        default=None,
        help="regenerate everything, or pass an output filename (e.g. herat.png) to regenerate just one location",
    )
    args = parser.parse_args(argv)

    import pixellab  # deferred: keeps `--help` working even if the package isn't installed yet

    client = pixellab.Client.from_env_file(str(ENV_PATH))
    locations = load_locations()
    failures = run(client, locations, args.force)

    print(f"remaining balance: {client.get_balance()}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
