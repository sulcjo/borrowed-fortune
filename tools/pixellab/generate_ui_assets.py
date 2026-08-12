#!/usr/bin/env python3
"""Generate transparent-background UI chrome PNGs (menu banner shapes) via
pixellab's pixflux API.

Offline dev tool. Never runs inside the shipped game. See tools/pixellab/README.md
for setup and usage.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from pixflux_client import PORTRAIT_STYLE_CLAUSE, build_description, compute_seed, generate_pixflux

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
UI_ASSETS_PATH = SCRIPT_DIR / "ui_assets.json"
UI_DIR = REPO_ROOT / "assets" / "ui"
ENV_PATH = REPO_ROOT / ".env"


def load_ui_assets(path: Path = UI_ASSETS_PATH) -> list[dict]:
    with path.open() as f:
        return json.load(f)["ui_assets"]


def generate_ui_asset(client, entry: dict, ui_dir: Path) -> tuple[dict, Path]:
    image, usage = generate_pixflux(
        client,
        description=build_description(entry["description"], style_clause=PORTRAIT_STYLE_CLAUSE),
        image_size={"width": entry["width"], "height": entry["height"]},
        seed=compute_seed(entry["id"]),
        no_background=True,
        detail="highly detailed",
    )
    ui_dir.mkdir(parents=True, exist_ok=True)
    path = ui_dir / f"{entry['id']}.png"
    image.save(path)
    return usage, path


def run(client, entries: list[dict], force, ui_dir: Path = UI_DIR) -> list[str]:
    """force: None (skip anything already on disk), True (regenerate everything),
    or an id string (regenerate just that one). Returns the list of ids that
    failed to generate."""
    failures: list[str] = []
    for entry in entries:
        path = ui_dir / f"{entry['id']}.png"
        should_force = force is True or force == entry["id"]
        if path.exists() and not should_force:
            print(f"skip {entry['id']} (already exists)")
            continue
        try:
            usage, saved_path = generate_ui_asset(client, entry, ui_dir)
        except Exception as exc:
            print(f"FAILED {entry['id']}: {exc}")
            failures.append(entry["id"])
            continue
        print(f"generated {entry['id']} -> {saved_path} (usage: {usage})")
    return failures


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        nargs="?",
        const=True,
        default=None,
        help="regenerate everything, or pass an id (e.g. menu_banner_tall) to regenerate just one",
    )
    args = parser.parse_args(argv)

    import pixellab  # deferred: keeps `--help` working even if the package isn't installed yet

    client = pixellab.Client.from_env_file(str(ENV_PATH))
    entries = load_ui_assets()
    failures = run(client, entries, args.force)

    if failures:
        print(f"failed: {', '.join(failures)}")

    try:
        print(f"remaining balance: {client.get_balance()}")
    except Exception as exc:
        print(f"could not fetch balance (non-fatal): {exc}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
