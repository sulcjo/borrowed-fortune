#!/usr/bin/env python3
"""Generate NPC bust portraits and Farrukh's 3-stage progressive-wear
portrait via pixellab's pixflux API.

Offline dev tool. Never runs inside the shipped game. See
tools/pixellab/README.md for setup and usage.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import PIL.Image

from pixflux_client import PORTRAIT_STYLE_CLAUSE, build_description, compute_seed, generate_pixflux

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
NPCS_PATH = SCRIPT_DIR / "npcs.json"
PORTRAITS_DIR = REPO_ROOT / "assets" / "portraits"
ENV_PATH = REPO_ROOT / ".env"

PORTRAIT_SIZE = {"width": 200, "height": 200}


def load_npcs(path: Path = NPCS_PATH) -> dict:
    with path.open() as f:
        return json.load(f)


def generate_npc(client, entry: dict, portraits_dir: Path) -> tuple[dict, Path]:
    image, usage = generate_pixflux(
        client,
        description=build_description(entry["description"], style_clause=PORTRAIT_STYLE_CLAUSE),
        image_size=PORTRAIT_SIZE,
        seed=compute_seed(entry["id"]),
        no_background=True,
        detail="highly detailed",
    )
    portraits_dir.mkdir(parents=True, exist_ok=True)
    path = portraits_dir / f"{entry['id']}.png"
    image.save(path)
    return usage, path


def run_npcs(client, npcs: list[dict], force, portraits_dir: Path = PORTRAITS_DIR) -> list[str]:
    """force: None (skip anything already on disk), True (regenerate everything),
    or an npc id string (regenerate just that one). Returns the list of npc
    ids that failed to generate."""
    failures: list[str] = []
    for entry in npcs:
        path = portraits_dir / f"{entry['id']}.png"
        should_force = force is True or force == entry["id"]
        if path.exists() and not should_force:
            print(f"skip {entry['id']} (already exists)")
            continue
        try:
            usage, saved_path = generate_npc(client, entry, portraits_dir)
        except Exception as exc:
            print(f"FAILED {entry['id']}: {exc}")
            failures.append(entry["id"])
            continue
        print(f"generated {entry['id']} -> {saved_path} (usage: {usage})")
    return failures


def run_farrukh_stages(client, stages: list[dict], force, portraits_dir: Path = PORTRAITS_DIR) -> list[str]:
    """Stages must chain: each stage's call passes the previous stage's
    image as init_image/color_image so the three stages read as the same
    person getting progressively more worn, not three independent rolls.
    A stage already on disk is loaded (not regenerated) so a later stage
    can still chain off it without spending a credit re-generating it -
    unless force applies to that specific stage."""
    portraits_dir.mkdir(parents=True, exist_ok=True)
    seed = compute_seed("farrukh")
    previous_image: PIL.Image.Image | None = None
    failures: list[str] = []
    for entry in sorted(stages, key=lambda s: s["stage"]):
        stage = entry["stage"]
        path = portraits_dir / f"farrukh_stage_{stage}.png"
        should_force = force is True or force == f"farrukh_stage_{stage}"
        if path.exists() and not should_force:
            print(f"skip farrukh_stage_{stage} (already exists)")
            previous_image = PIL.Image.open(path)
            continue
        try:
            image, usage = generate_pixflux(
                client,
                description=build_description(entry["description"], style_clause=PORTRAIT_STYLE_CLAUSE),
                image_size=PORTRAIT_SIZE,
                seed=seed,
                no_background=True,
                init_image=previous_image,
                color_image=previous_image,
                detail="highly detailed",
            )
        except Exception as exc:
            print(f"FAILED farrukh_stage_{stage}: {exc}")
            failures.append(f"farrukh_stage_{stage}")
            continue
        image.save(path)
        previous_image = image
        print(f"generated farrukh_stage_{stage} -> {path} (usage: {usage})")
    return failures


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        nargs="?",
        const=True,
        default=None,
        help="regenerate everything, or pass an id (e.g. bahram, farrukh_stage_2) to regenerate just one",
    )
    args = parser.parse_args(argv)

    import pixellab  # deferred: keeps `--help` working even if the package isn't installed yet

    client = pixellab.Client.from_env_file(str(ENV_PATH))
    data = load_npcs()

    npc_failures = run_npcs(client, data["npcs"], args.force)
    stage_failures = run_farrukh_stages(client, data["farrukh_stages"], args.force)
    failures = npc_failures + stage_failures

    if failures:
        print(f"failed: {', '.join(failures)}")

    try:
        print(f"remaining balance: {client.get_balance()}")
    except Exception as exc:
        print(f"could not fetch balance (non-fatal): {exc}")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
