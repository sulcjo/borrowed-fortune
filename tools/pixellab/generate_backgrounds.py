#!/usr/bin/env python3
"""Generate Persian-miniature-style location background PNGs via pixellab's pixflux API.

Offline dev tool. Never runs inside the shipped game. See tools/pixellab/README.md
for setup and usage.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from pixflux_client import build_description, compute_seed, generate_pixflux

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
LOCATIONS_PATH = SCRIPT_DIR / "locations.json"
BACKGROUNDS_DIR = REPO_ROOT / "assets" / "backgrounds"
ENV_PATH = REPO_ROOT / ".env"

IMAGE_SIZE = {"width": 320, "height": 180}


def load_locations(path: Path = LOCATIONS_PATH) -> list[dict]:
    with path.open() as f:
        return json.load(f)


def generate_location(client, entry: dict, backgrounds_dir: Path) -> tuple[dict, Path]:
    """Generates one image and saves it to every chapter id sharing this
    location - only chapter-id-named files ever land on disk (matching
    ChapterView's res://assets/backgrounds/<chapter_id>.png lookup). The
    location's own "output" name is a logical key only (used for --force
    matching and log messages) and never becomes a path on disk."""
    image, usage = generate_pixflux(
        client,
        description=build_description(entry["description"]),
        image_size=IMAGE_SIZE,
        seed=compute_seed(entry["output"]),
        detail="highly detailed",
    )
    backgrounds_dir.mkdir(parents=True, exist_ok=True)
    chapter_paths = [backgrounds_dir / f"{chapter_id}.png" for chapter_id in entry["chapter_ids"]]
    for chapter_path in chapter_paths:
        image.save(chapter_path)
    return usage, chapter_paths[0]


def run(client, locations: list[dict], force, backgrounds_dir: Path = BACKGROUNDS_DIR) -> list[str]:
    """force: None (skip anything already on disk), True (regenerate everything),
    or an output filename string (regenerate just that one location).
    Returns the list of output filenames that failed to generate."""
    total_usd = 0.0
    total_generations = 0.0
    failures: list[str] = []
    for entry in locations:
        primary_path = backgrounds_dir / f"{entry['chapter_ids'][0]}.png"
        should_force = force is True or force == entry["output"]
        if primary_path.exists() and not should_force:
            print(f"skip {entry['output']} (already exists)")
            continue
        try:
            usage, path = generate_location(client, entry, backgrounds_dir)
        except Exception as exc:
            print(f"FAILED {entry['output']}: {exc}")
            failures.append(entry["output"])
            continue
        total_usd += usage.get("usd", 0.0)
        total_generations += usage.get("generations", 0.0)
        print(f"generated {entry['output']} -> {path} (usage: {usage})")
    print(f"total spent this run: ${total_usd:.4f}, {total_generations:g} generations")
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

    try:
        print(f"remaining balance: {client.get_balance()}")
    except Exception as exc:
        print(f"could not fetch balance (non-fatal): {exc}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
