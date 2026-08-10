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


def generate_location(client, entry: dict, backgrounds_dir: Path) -> tuple[dict, Path]:
    """Generates one image and saves it to every chapter id sharing this
    location - only chapter-id-named files ever land on disk (matching
    ChapterView's res://assets/backgrounds/<chapter_id>.png lookup). The
    location's own "output" name is a logical key only (used for --force
    matching and log messages) and never becomes a path on disk.

    Deliberately bypasses client.generate_image_pixflux() and posts to the
    endpoint directly: the installed pixellab SDK's response model hardcodes
    usage.type == "usd", but some accounts (subscription/generation-allowance
    plans) get back usage.type == "generations" instead, which crashes the
    SDK's Pydantic validation - discarding the successfully generated image
    along with it. Posting and parsing the JSON ourselves tolerates either
    usage shape. Still uses the SDK's Client for auth/config
    (client.base_url, client.headers())."""
    import base64
    from io import BytesIO

    import PIL.Image
    import requests

    request_data = {
        "description": build_description(entry),
        "image_size": IMAGE_SIZE,
        "negative_description": NEGATIVE_DESCRIPTION,
        "text_guidance_scale": GENERATION_PARAMS["text_guidance_scale"],
        "outline": GENERATION_PARAMS["outline"],
        "shading": GENERATION_PARAMS["shading"],
        "detail": GENERATION_PARAMS["detail"],
        "view": GENERATION_PARAMS["view"],
        "direction": None,
        "isometric": False,
        "no_background": GENERATION_PARAMS["no_background"],
        "coverage_percentage": None,
        "init_image": None,
        "init_image_strength": 300,
        "color_image": None,
        "seed": compute_seed(entry["output"]),
    }
    response = requests.post(
        f"{client.base_url}/generate-image-pixflux",
        headers=client.headers(),
        json=request_data,
    )
    response.raise_for_status()
    payload = response.json()

    image_bytes = base64.b64decode(payload["image"]["base64"])
    image = PIL.Image.open(BytesIO(image_bytes))

    backgrounds_dir.mkdir(parents=True, exist_ok=True)
    chapter_paths = [backgrounds_dir / f"{chapter_id}.png" for chapter_id in entry["chapter_ids"]]
    for chapter_path in chapter_paths:
        image.save(chapter_path)

    return payload.get("usage", {}), chapter_paths[0]


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
