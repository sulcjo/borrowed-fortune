#!/usr/bin/env python3
"""Generate Persian-miniature-style cinematic cutscene panel PNGs via
pixellab's pixflux API.

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
PANELS_PATH = SCRIPT_DIR / "cutscene_panels.json"
CUTSCENES_DIR = REPO_ROOT / "assets" / "cutscenes"
ENV_PATH = REPO_ROOT / ".env"

IMAGE_SIZE = {"width": 400, "height": 168}


def load_panels(path: Path = PANELS_PATH) -> list[dict]:
    with path.open() as f:
        return json.load(f)


def generate_panel(client, entry: dict, cutscenes_dir: Path) -> tuple[dict, Path]:
    image, usage = generate_pixflux(
        client,
        description=build_description(entry["description"]),
        image_size=IMAGE_SIZE,
        seed=compute_seed(entry["output"]),
        outline="single color black outline",
        shading="flat shading",
        detail="highly detailed",
    )
    cutscenes_dir.mkdir(parents=True, exist_ok=True)
    path = cutscenes_dir / entry["output"]
    image.save(path)
    return usage, path


def run(client, panels: list[dict], force, cutscenes_dir: Path = CUTSCENES_DIR) -> list[str]:
    """force: None (skip anything already on disk), True (regenerate everything),
    or an output filename string (regenerate just that one panel).
    Returns the list of output filenames that failed to generate."""
    total_usd = 0.0
    total_generations = 0.0
    failures: list[str] = []
    for entry in panels:
        primary_path = cutscenes_dir / entry["output"]
        should_force = force is True or force == entry["output"]
        if primary_path.exists() and not should_force:
            print(f"skip {entry['output']} (already exists)")
            continue
        try:
            usage, path = generate_panel(client, entry, cutscenes_dir)
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
        help="regenerate everything, or pass an output filename (e.g. prologue_intro_01.png) to regenerate just one panel",
    )
    parser.add_argument("--config", type=Path, default=PANELS_PATH, help="path to the panel-config JSON (default: this cutscene's own cutscene_panels.json)")
    parser.add_argument("--output-dir", type=Path, default=CUTSCENES_DIR, help="directory to write generated PNGs into (default: assets/cutscenes)")
    args = parser.parse_args(argv)

    import pixellab  # deferred: keeps `--help` working even if the package isn't installed yet

    client = pixellab.Client.from_env_file(str(ENV_PATH))
    panels = load_panels(args.config)
    failures = run(client, panels, args.force, args.output_dir)

    try:
        print(f"remaining balance: {client.get_balance()}")
    except Exception as exc:
        print(f"could not fetch balance (non-fatal): {exc}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
