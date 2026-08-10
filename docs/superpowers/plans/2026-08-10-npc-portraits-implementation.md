# NPC Portraits Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 13 NPC bust portraits (named or not, grounded in the shipped chapter text) plus a 3-stage progressive-wear Farrukh portrait, generated offline via pixellab, and displayed in two corner slots in `ChapterView` above the choices.

**Architecture:** Three independent tasks. Task 1 extracts the shared pixflux request/response logic that `generate_backgrounds.py` already proved against the real API into `tools/pixellab/pixflux_client.py`, then adds `generate_portraits.py` on top of it (13 independent NPC busts + Farrukh's 3 chained stages). Task 2 is pure content: an optional `"npc_portrait"` key added to specific already-shipped dialogue nodes across 8 chapters, plus a `"farrukh_wear_stage"` key added to every entry in `manifest.json` - no engine or scene code touched. Task 3 wires `ChapterView` to actually display whatever portrait files exist, with the same null-safe fallback discipline as the background pass, and does not depend on Task 1 having produced real art.

**Tech Stack:** Python 3 + `requests` (already proven against the real API in the backgrounds pass) · Godot 4.3 / GDScript (`TextureRect`, `Image`, `FileAccess`) · GUT.

## Global Constraints

- Godot 4.3 floor.
- GUT headless test discipline: prime once per fresh worktree (`godot --headless --path . --editor --quit`), then `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`. Never re-run priming in the same worktree.
- Commit per task.
- **No task may spend real pixellab credits or make a real network call.** Task 1 is verified with a fake client (mocking `requests.post`, matching the mock shape already used and proven for the backgrounds pass), never `pixellab.Client`. The real 13+3 generations are a manual step the human runs afterward, outside this plan.
- `generate_portraits.py` (and the shared `pixflux_client.py`) get no committed automated test file - same explicit, stated carve-out as `generate_backgrounds.py`. `ChapterView`'s new code *does* get a normal committed GUT test.
- Every `npc_portrait` value and every `farrukh_wear_stage` value in this plan was derived by directly reading the current shipped content of all 8 chapter files, not inferred from memory or the design spec - treat the tables in Task 2 as ground truth for exactly which nodes change.

---

## Task 1: shared pixflux client + portrait generator

**Files:**
- Create: `tools/pixellab/pixflux_client.py`
- Modify: `tools/pixellab/generate_backgrounds.py`
- Create: `tools/pixellab/npcs.json`
- Create: `tools/pixellab/generate_portraits.py`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing Task 2 or Task 3 depend on - both work against a manifest/mapping that's fixed regardless of whether real art exists yet.

- [ ] **Step 1: Write `tools/pixellab/pixflux_client.py`**

Extracts the style constants and the direct-POST bypass that `generate_backgrounds.py` already has and proved against the real API (the installed pixellab SDK's response model crashes on this account's `generations`-typed usage field - see that file's own docstring). Both the background and portrait generators need this identical logic; extracting it here means the fix and the style direction only exist in one place.

```python
"""Shared pixflux request/response handling for this project's art generators.

Bypasses client.generate_image_pixflux() entirely and posts to the endpoint
directly: the installed pixellab SDK's response model hardcodes
usage.type == "usd", but this account's real API responses come back
usage.type == "generations" (subscription/generation-allowance plan), which
crashes the SDK's Pydantic validation and discards the successfully
generated image along with it. Still uses the SDK's Client for auth/config
(client.base_url, client.headers()).
"""
from __future__ import annotations

import base64
import hashlib
from io import BytesIO
from typing import Optional

import PIL.Image

STYLE_CLAUSE = (
    "Persian miniature painting, flat gouache color fields, ochre and lapis "
    "palette, 11th-century Khorasan architecture, illuminated manuscript "
    "background"
)
NEGATIVE_DESCRIPTION = (
    "photorealistic, 3d render, modern clothing, modern buildings, gradient "
    "shading, blur, text, watermark, signature"
)


def compute_seed(key: str) -> int:
    """Deterministic seed from any string key, so re-running a generation
    for the same subject reproduces the same image rather than drawing a
    new random one."""
    digest = hashlib.sha256(key.encode("utf-8")).hexdigest()
    return int(digest[:8], 16) % 1_000_000


PORTRAIT_STYLE_CLAUSE = (
    "Persian miniature painting, flat gouache color fields, ochre and lapis "
    "palette, 11th-century Khorasan dress and bearing"
)


def build_description(subject_description: str, style_clause: str = STYLE_CLAUSE) -> str:
    """style_clause defaults to the full-scene backgrounds style. Portraits
    use PORTRAIT_STYLE_CLAUSE instead - it drops "illuminated manuscript
    background," which would otherwise fight no_background=true and leave
    scene fragments around an otherwise-transparent bust."""
    return f"{style_clause}, {subject_description}"


def _encode_image(image: Optional[PIL.Image.Image]) -> Optional[dict]:
    if image is None:
        return None
    buffered = BytesIO()
    image.save(buffered, format="PNG")
    return {
        "type": "base64",
        "base64": base64.b64encode(buffered.getvalue()).decode(),
        "format": "png",
    }


def generate_pixflux(
    client,
    description: str,
    image_size: dict,
    seed: int,
    no_background: bool = False,
    init_image: Optional[PIL.Image.Image] = None,
    color_image: Optional[PIL.Image.Image] = None,
    outline: str = "single color black outline",
    shading: str = "flat shading",
    detail: str = "low detail",
    view: str = "side",
    text_guidance_scale: int = 8,
) -> tuple[PIL.Image.Image, dict]:
    """POSTs to /generate-image-pixflux and parses the JSON ourselves.
    Returns (generated PIL.Image, raw usage dict - shape varies by account
    plan, caller decides how to report it)."""
    import requests

    request_data = {
        "description": description,
        "image_size": image_size,
        "negative_description": NEGATIVE_DESCRIPTION,
        "text_guidance_scale": text_guidance_scale,
        "outline": outline,
        "shading": shading,
        "detail": detail,
        "view": view,
        "direction": None,
        "isometric": False,
        "no_background": no_background,
        "coverage_percentage": None,
        "init_image": _encode_image(init_image),
        "init_image_strength": 300,
        "color_image": _encode_image(color_image),
        "seed": seed,
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
    return image, payload.get("usage", {})
```

- [ ] **Step 2: Update `tools/pixellab/generate_backgrounds.py` to import from the shared module**

Read the current file first - it has its own copies of `STYLE_CLAUSE`, `NEGATIVE_DESCRIPTION`, `compute_seed`, and the direct-POST-and-parse logic inline inside `generate_location()`. Replace those with imports from `pixflux_client` and a call to `generate_pixflux()`, keeping every other line (the chapter-id-keyed file-copying logic, the idempotent skip/`--force` loop in `run()`, the `main()` CLI) exactly as it is:

```python
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
```

- [ ] **Step 3: Re-verify `generate_backgrounds.py` still behaves identically after the refactor**

Transient check, nothing committed - same mock shape already proven for this file, run from `tools/pixellab/`:

```bash
cd tools/pixellab
python3 -c "
import sys, tempfile, base64
from pathlib import Path
from unittest import mock
sys.path.insert(0, '.')
import generate_backgrounds as gb

import PIL.Image
from io import BytesIO
buf = BytesIO()
PIL.Image.new('RGB', (4, 4), 'red').save(buf, format='PNG')
fake_png_b64 = base64.b64encode(buf.getvalue()).decode()

class FakeResponse:
    def raise_for_status(self):
        pass
    def json(self):
        return {
            'image': {'type': 'base64', 'base64': fake_png_b64, 'format': 'png'},
            'usage': {'type': 'generations', 'generations': 1.0},
        }

class FakeClient:
    base_url = 'https://fake.example/v1'
    def headers(self):
        return {'Authorization': 'Bearer fake'}

with tempfile.TemporaryDirectory() as tmp:
    backgrounds_dir = Path(tmp)
    locations = gb.load_locations()
    client = FakeClient()
    with mock.patch('requests.post', return_value=FakeResponse()) as mock_post:
        failures = gb.run(client, locations, force=None, backgrounds_dir=backgrounds_dir)
        assert failures == [], failures
        assert mock_post.call_count == 10, mock_post.call_count
        assert (backgrounds_dir / 'chapter_00_prologue.png').exists()
        assert (backgrounds_dir / 'chapter_04a_herat.png').exists()
        assert (backgrounds_dir / 'chapter_04b_herat_favor.png').exists()

print('OK: generate_backgrounds.py behaves identically after the pixflux_client extraction')
"
```

Expected: `OK: generate_backgrounds.py behaves identically after the pixflux_client extraction`. If it fails, fix the refactor (not the check) until it passes.

- [ ] **Step 4: Write `tools/pixellab/npcs.json`**

```json
{
  "npcs": [
    {
      "id": "nasuh",
      "description": "an ink-stained clerk in a plain robe, seated with an open ledger, quiet composed bearing, waist-up portrait bust"
    },
    {
      "id": "ostad",
      "description": "an elderly letter-writer in a simple dignified robe, pen and paper, gentle bearing, waist-up portrait bust"
    },
    {
      "id": "saidibnyaqub",
      "description": "a young customs officer in good cloth worn thin at the cuffs, stack of ledgers, waist-up portrait bust"
    },
    {
      "id": "mihran",
      "description": "a sarraf money-changer at his scale, weighing silver, waist-up portrait bust"
    },
    {
      "id": "ummkavus",
      "description": "a widow running a caravanserai alone, practical dress, keys at her belt, waist-up portrait bust"
    },
    {
      "id": "tahir",
      "description": "a tired ex-soldier, younger than expected, worn campaign-era clothing, guarded posture, waist-up portrait bust"
    },
    {
      "id": "ardashir",
      "description": "an older, quiet sarraf at a mint counting-table, precise composed bearing, waist-up portrait bust"
    },
    {
      "id": "rostam",
      "description": "a young, sharp-eyed courier-network fixer, better dressed than his surroundings, waist-up portrait bust"
    },
    {
      "id": "behdinshopkeeper",
      "description": "a Zoroastrian Behdin shopkeeper, a woman in early widowhood, plain dress, waist-up portrait bust"
    },
    {
      "id": "tarsamerchant",
      "description": "a Christian Tarsa cloth merchant, bolts of dyed cloth nearby, waist-up portrait bust"
    },
    {
      "id": "pushanggateofficer",
      "description": "a young, tired Ghaznavid gate officer with a requisition list, waist-up portrait bust"
    },
    {
      "id": "bahram",
      "description": "an older ghulam gate-officer in service dress, watchful bearing, waist-up portrait bust"
    },
    {
      "id": "teacher",
      "description": "an old, self-effacing teacher in plain worn robes, seated simply, no ornament, waist-up portrait bust"
    }
  ],
  "farrukh_stages": [
    {
      "stage": 1,
      "description": "a young merchant's son, nineteen, plain mourning-appropriate travel dress, composed but grieving expression, clean-kept, waist-up portrait bust"
    },
    {
      "stage": 2,
      "description": "the same young merchant, road-dust on his clothes, more guarded and hardened expression, sun-worn, waist-up portrait bust"
    },
    {
      "stage": 3,
      "description": "the same young merchant, visibly travel-worn, weathered and resolute bearing, dust and wear on travel clothes, waist-up portrait bust"
    }
  ]
}
```

- [ ] **Step 5: Write `tools/pixellab/generate_portraits.py`**

```python
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

PORTRAIT_SIZE = {"width": 96, "height": 96}


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
```

- [ ] **Step 6: Verify the new script's logic with a throwaway mock run - do NOT install `pixellab` or hit the network**

```bash
cd tools/pixellab
python3 -c "
import sys, tempfile, base64
from pathlib import Path
from unittest import mock
sys.path.insert(0, '.')
import generate_portraits as gp

import PIL.Image
from io import BytesIO
buf = BytesIO()
PIL.Image.new('RGBA', (4, 4), (255, 0, 0, 0)).save(buf, format='PNG')
fake_png_b64 = base64.b64encode(buf.getvalue()).decode()

class FakeResponse:
    def raise_for_status(self):
        pass
    def json(self):
        return {
            'image': {'type': 'base64', 'base64': fake_png_b64, 'format': 'png'},
            'usage': {'type': 'generations', 'generations': 1.0},
        }

class FakeClient:
    base_url = 'https://fake.example/v1'
    def headers(self):
        return {'Authorization': 'Bearer fake'}

with tempfile.TemporaryDirectory() as tmp:
    portraits_dir = Path(tmp)
    data = gp.load_npcs()
    assert len(data['npcs']) == 13, f\"expected 13 npcs, got {len(data['npcs'])}\"
    assert len(data['farrukh_stages']) == 3, f\"expected 3 farrukh stages, got {len(data['farrukh_stages'])}\"

    client = FakeClient()
    with mock.patch('requests.post', return_value=FakeResponse()) as mock_post:
        npc_failures = gp.run_npcs(client, data['npcs'], force=None, portraits_dir=portraits_dir)
        assert npc_failures == [], npc_failures
        assert mock_post.call_count == 13, mock_post.call_count
        assert (portraits_dir / 'bahram.png').exists()
        assert (portraits_dir / 'teacher.png').exists()

        stage_failures = gp.run_farrukh_stages(client, data['farrukh_stages'], force=None, portraits_dir=portraits_dir)
        assert stage_failures == [], stage_failures
        assert mock_post.call_count == 16, mock_post.call_count
        assert (portraits_dir / 'farrukh_stage_1.png').exists()
        assert (portraits_dir / 'farrukh_stage_2.png').exists()
        assert (portraits_dir / 'farrukh_stage_3.png').exists()

        # every farrukh_stages call after the first must have passed a non-null init_image
        stage_calls = mock_post.call_args_list[13:16]
        for i, call in enumerate(stage_calls):
            body = call.kwargs['json']
            has_init = body['init_image'] is not None
            expected = (i != 0)  # stage 1 has no predecessor, stages 2 and 3 do
            assert has_init == expected, f'stage {i+1}: init_image presence was {has_init}, expected {expected}'

        # idempotent re-run: nothing already on disk gets regenerated, but chaining still works
        stage_failures_2 = gp.run_farrukh_stages(client, data['farrukh_stages'], force=None, portraits_dir=portraits_dir)
        assert mock_post.call_count == 16, 'idempotent re-run must not regenerate any stage'

print('OK: portrait generator (independent NPCs + chained Farrukh stages) verified')
"
```

Expected: `OK: portrait generator (independent NPCs + chained Farrukh stages) verified`. Fix `generate_portraits.py` (not the check) until it passes.

- [ ] **Step 7: Commit**

```bash
git add tools/pixellab/pixflux_client.py tools/pixellab/generate_backgrounds.py tools/pixellab/npcs.json tools/pixellab/generate_portraits.py
git commit -m "feat: add NPC portrait generator, sharing pixflux logic with the background generator"
```

---

## Task 2: annotate chapters with portrait keys

**Files:**
- Modify: `content/chapters/chapter_00_prologue/prologue.json`
- Modify: `content/chapters/chapter_01_teginabad/teginabad.json`
- Modify: `content/chapters/chapter_02_bost/bost.json`
- Modify: `content/chapters/chapter_03_farah/farah.json`
- Modify: `content/chapters/chapter_04a_herat/herat.json`
- Modify: `content/chapters/chapter_04b_herat_favor/herat_favor.json`
- Modify: `content/chapters/chapter_06_pushang/pushang.json`
- Modify: `content/chapters/chapter_07_sarakhs/sarakhs.json`
- Modify: `content/chapters/chapter_08_nishapur/nishapur.json`
- Modify: `content/chapters/manifest.json`
- Test: `tests/unit/test_npc_portrait_content.gd` (new)

**Interfaces:**
- Consumes: nothing from Task 1 or Task 3.
- Produces: the `"npc_portrait"` node key and `"farrukh_wear_stage"` manifest key that Task 3's `ChapterView` code reads. Chapters 5 (`chapter_05_plunder_ending`) and Merv (`chapter_07b_merv`) are **not** in the modify list above - confirmed by direct read to have zero NPCs, so neither file changes; they still need `"farrukh_wear_stage"` added to `manifest.json`.

- [ ] **Step 1: Add `"npc_portrait"` to the exact nodes below**

For each `(file, node id, value)` triple, open that node in that file and add `"npc_portrait": "<value>"` as a new key on the node object (anywhere in the object - e.g. right after `"text"` reads cleanly). Every node not listed here, in every chapter (including ones not listed at all), gets no such key - do not add it speculatively to nodes not in this list, and do not skip any node that is listed.

**`chapter_00_prologue/prologue.json`:**
| node id | value |
|---|---|
| `n08_nasuh_ledger` | `nasuh` |
| `n09_suftaja_letter_choice` | `nasuh` |
| `n10a_read_letter` | `nasuh` |
| `n10b_let_it_go` | `nasuh` |
| `n11_ostad_comfort` | `ostad` |

**`chapter_01_teginabad/teginabad.json`:**
| node id | value |
|---|---|
| `n02_the_official` | `saidibnyaqub` |
| `n03_politics` | `saidibnyaqub` |
| `n04_the_demand` | `saidibnyaqub` |
| `n05_prayer_interlude` | `saidibnyaqub` |
| `n06_the_choice` | `saidibnyaqub` |
| `n07a_bribe` | `saidibnyaqub` |
| `n07b_inspection` | `saidibnyaqub` |
| `n07b_letter_callback` | `saidibnyaqub` |

**`chapter_02_bost/bost.json`:**
| node id | value |
|---|---|
| `n02_seeking_the_sarraf` | `mihran` |
| `n03_mihran_examines` | `mihran` |
| `n04_the_second_mark` | `mihran` |
| `n05_ibn_hasan` | `mihran` |
| `n06_the_danger` | `mihran` |
| `n07_the_offer` | `mihran` |
| `n08a_pressed` | `mihran` |
| `n08b_patient` | `mihran` |

**`chapter_03_farah/farah.json`:**
| node id | value |
|---|---|
| `n08_umm_kavus_introduced` | `ummkavus` |
| `n09_umm_kavus_backstory` | `ummkavus` |
| `n10_the_price_of_a_bed` | `ummkavus` |
| `n11a_paid_full` | `ummkavus` |
| `n11b_haggled` | `ummkavus` |
| `n13_two_doors` | `ummkavus` |
| `n13x_the_name_already_known` | `ummkavus` |
| `n14_the_choice` | `ummkavus` |
| `n15a_umm_kavus_channel` | `ummkavus` |
| `n16a_the_wait` | `ummkavus` |
| `n18a_departure_farah_mystery` | `ummkavus` |
| `n15b_finding_tahir` | `tahir` |
| `n16b_tahirs_price` | `tahir` |
| `n17b_the_war_he_carries` | `tahir` |
| `n18b_the_favor_owed` | `tahir` |

**`chapter_04a_herat/herat.json`** (all `ardashir`; verified against the file's real node ids directly - `n03a_the_old_soldier` and `n04a_the_1020_muster` are the excluded old-soldier background-mention beats, and `n20_aftermath`/`n21_departure_herat` are after Ardashir leaves the scene):
`n06_ardashir_introduced`, `n07_the_exchange_rate`, `n08a_accepted_the_rate`, `n08b_argued_the_discount`, `n09_grudging_exchange`, `n08c_kept_the_old_coin`, `n10_after_first_exchange`, `n11_the_correspondence`, `n12a_paid_in_full`, `n12b_haggled_the_fee`, `n13_reduced_fee`, `n14_pushed_too_far`, `n12c_declined_the_service`, `n15_after_second_exchange`, `n16_raising_the_rayy_connection`, `n17_ardashirs_hesitation`, `n18_the_moment_of_truth`, `n19a_the_partial_truth`, `n19b_the_full_truth`.

**`chapter_04b_herat_favor/herat_favor.json`** (all `rostam`; verified against the file's real node ids directly):
`n06_rostam_introduced`, `n07_the_delivery`, `n08_the_price_of_a_favor`, `n09a_paid_as_agreed`, `n09b_pushing_for_more`, `n10_extracted_more`, `n09c_took_the_scraps`, `n11_after_the_payment`, `n12_rostams_boast`, `n14_the_choice`, `n15a_entangled_deeper`, `n16a_the_first_task`, `n15b_pivot_away`, `n16b_the_veiled_threat`.

`n13_the_weight_of_knowing` gets **no** key - it's a reflective aside, Rostam is not on-page there. `n17a_departure_bound` and `n17b_departure_free` also get **no** key - both are past the last Rostam scene.

**`chapter_06_pushang/pushang.json`:**
| node id | value |
|---|---|
| `n03_the_behdin_shopkeeper` | `behdinshopkeeper` |
| `n04_closing_early` | `behdinshopkeeper` |
| `n05_the_tarsa_merchant` | `tarsamerchant` |
| `n06_two_names_one_people` | `tarsamerchant` |
| `n09_the_officers_demand` | `pushanggateofficer` |
| `n10a_complied` | `pushanggateofficer` |
| `n10b_haggled` | `pushanggateofficer` |
| `n10c_refused` | `pushanggateofficer` |
| `n10d_bribed` | `pushanggateofficer` |

**`chapter_07_sarakhs/sarakhs.json`** (all `bahram`):
`n05_bahram_the_gatekeeper`, `n06_what_nasa_taught_him`, `n07_a_quiet_request`, `n08_the_commanders_charge`, `n09a_accepted_freely`, `n09b_accepted_for_coin`, `n09c_declined_plainly`.

**`chapter_08_nishapur/nishapur.json`** (all `teacher`):
`n06_the_khaneqah_at_dusk`, `n07_nobody_son_of_nobody`.

- [ ] **Step 2: Add `"farrukh_wear_stage"` to every entry in `content/chapters/manifest.json`**

Add this key to all 11 existing entries (do not remove or reorder any existing key):

| chapter_id | farrukh_wear_stage |
|---|---|
| `chapter_00_prologue` | `1` |
| `chapter_01_teginabad` | `1` |
| `chapter_02_bost` | `1` |
| `chapter_03_farah` | `2` |
| `chapter_04a_herat` | `2` |
| `chapter_04b_herat_favor` | `2` |
| `chapter_05_plunder_ending` | `3` |
| `chapter_06_pushang` | `2` |
| `chapter_07_sarakhs` | `3` |
| `chapter_07b_merv` | `3` |
| `chapter_08_nishapur` | `3` |

Example for one entry (apply the same pattern to all 11, using each row's value above):

```json
"chapter_07_sarakhs": {
  "dialogue_path": "res://content/chapters/chapter_07_sarakhs/sarakhs.json",
  "glossary_path": "res://content/glossary/sarakhs_terms.json",
  "next_chapter_id": null,
  "farrukh_wear_stage": 3
}
```

- [ ] **Step 3: Write the failing test, `tests/unit/test_npc_portrait_content.gd`**

```gdscript
extends GutTest

func _load_dialogue(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	var nodes = JSON.parse_string(file.get_as_text())
	file.close()
	return nodes

func _portrait_for(nodes: Array, node_id: String):
	for node in nodes:
		if node["id"] == node_id:
			return node.get("npc_portrait", null)
	fail_test("no node with id '%s' found" % node_id)
	return null

func test_prologue_portrait_keys_are_correct():
	var nodes := _load_dialogue("res://content/chapters/chapter_00_prologue/prologue.json")
	assert_eq(_portrait_for(nodes, "n08_nasuh_ledger"), "nasuh")
	assert_eq(_portrait_for(nodes, "n11_ostad_comfort"), "ostad")
	assert_null(_portrait_for(nodes, "n01_naming"), "the opening node has no NPC on-page yet")

func test_farah_switches_portrait_from_umm_kavus_to_tahir():
	var nodes := _load_dialogue("res://content/chapters/chapter_03_farah/farah.json")
	assert_eq(_portrait_for(nodes, "n08_umm_kavus_introduced"), "ummkavus")
	assert_eq(_portrait_for(nodes, "n15b_finding_tahir"), "tahir")
	assert_eq(_portrait_for(nodes, "n18b_the_favor_owed"), "tahir")

func test_pushang_has_three_distinct_unlabeled_npc_portraits():
	var nodes := _load_dialogue("res://content/chapters/chapter_06_pushang/pushang.json")
	assert_eq(_portrait_for(nodes, "n03_the_behdin_shopkeeper"), "behdinshopkeeper")
	assert_eq(_portrait_for(nodes, "n05_the_tarsa_merchant"), "tarsamerchant")
	assert_eq(_portrait_for(nodes, "n09_the_officers_demand"), "pushanggateofficer")

func test_herat_4a_ardashir_portrait_covers_the_full_exchange_including_side_branches():
	var nodes := _load_dialogue("res://content/chapters/chapter_04a_herat/herat.json")
	assert_eq(_portrait_for(nodes, "n06_ardashir_introduced"), "ardashir")
	assert_eq(_portrait_for(nodes, "n08b_argued_the_discount"), "ardashir")
	assert_eq(_portrait_for(nodes, "n19b_the_full_truth"), "ardashir")
	assert_null(_portrait_for(nodes, "n03a_the_old_soldier"), "background-mention figure, not on the roster")
	assert_null(_portrait_for(nodes, "n21_departure_herat"), "Ardashir is no longer on-page by departure")

func test_herat_favors_reflective_aside_has_no_portrait():
	var nodes := _load_dialogue("res://content/chapters/chapter_04b_herat_favor/herat_favor.json")
	assert_null(_portrait_for(nodes, "n13_the_weight_of_knowing"))
	assert_eq(_portrait_for(nodes, "n09b_pushing_for_more"), "rostam")
	assert_eq(_portrait_for(nodes, "n12_rostams_boast"), "rostam")
	assert_null(_portrait_for(nodes, "n17a_departure_bound"))

func test_sarakhs_and_nishapur_portrait_keys_are_correct():
	var sarakhs_nodes := _load_dialogue("res://content/chapters/chapter_07_sarakhs/sarakhs.json")
	assert_eq(_portrait_for(sarakhs_nodes, "n05_bahram_the_gatekeeper"), "bahram")
	assert_eq(_portrait_for(sarakhs_nodes, "n08_the_commanders_charge"), "bahram")

	var nishapur_nodes := _load_dialogue("res://content/chapters/chapter_08_nishapur/nishapur.json")
	assert_eq(_portrait_for(nishapur_nodes, "n06_the_khaneqah_at_dusk"), "teacher")
	assert_eq(_portrait_for(nishapur_nodes, "n07_nobody_son_of_nobody"), "teacher")

func test_farrukh_wear_stage_is_set_on_every_manifest_chapter():
	var manifest_file := FileAccess.open("res://content/chapters/manifest.json", FileAccess.READ)
	var manifest = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()

	var expected_stages := {
		"chapter_00_prologue": 1, "chapter_01_teginabad": 1, "chapter_02_bost": 1,
		"chapter_03_farah": 2, "chapter_04a_herat": 2, "chapter_04b_herat_favor": 2,
		"chapter_05_plunder_ending": 3, "chapter_06_pushang": 2, "chapter_07_sarakhs": 3,
		"chapter_07b_merv": 3, "chapter_08_nishapur": 3,
	}
	for chapter_id in expected_stages:
		assert_true(manifest.has(chapter_id), "manifest is missing expected chapter '%s'" % chapter_id)
		assert_eq(manifest[chapter_id].get("farrukh_wear_stage", null), expected_stages[chapter_id],
			"chapter '%s' has the wrong farrukh_wear_stage" % chapter_id)
```

- [ ] **Step 4: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_npc_portrait_content.gd` FAILS (the keys don't exist yet, so `.get("npc_portrait", null)` returns `null` everywhere and `.get("farrukh_wear_stage", null)` does too).

- [ ] **Step 5: Make the edits from Steps 1-2, then run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: `test_npc_portrait_content.gd` fully passes, and the whole suite is still green (228 tests before this task; 235 after - 228 + 7 new).

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_00_prologue/prologue.json content/chapters/chapter_01_teginabad/teginabad.json content/chapters/chapter_02_bost/bost.json content/chapters/chapter_03_farah/farah.json content/chapters/chapter_04a_herat/herat.json content/chapters/chapter_04b_herat_favor/herat_favor.json content/chapters/chapter_06_pushang/pushang.json content/chapters/chapter_07_sarakhs/sarakhs.json content/chapters/chapter_08_nishapur/nishapur.json content/chapters/manifest.json tests/unit/test_npc_portrait_content.gd
git commit -m "feat: annotate chapters with NPC portrait keys and Farrukh's wear stage"
```

---

## Task 3: ChapterView portrait display

**Files:**
- Modify: `scenes/chapter_view/ChapterView.tscn`
- Modify: `scenes/chapter_view/ChapterView.gd`
- Test: `tests/unit/test_chapter_view_portraits.gd` (new)

**Interfaces:**
- Consumes: `dialogue_engine.current_node().get("npc_portrait", null)` and a new `farrukh_wear_stage: int` member set in `load_chapter_by_id()` (mirrors how `next_chapter_id` is already set there from the manifest entry). Neither depends on Task 1 having produced real art or Task 2 having annotated real content - this task's own test fixtures are self-contained, same discipline as the background pass.
- Produces: `_update_portraits() -> void`, called from `_render_current_node()`. Last task in the plan.

- [ ] **Step 1: Write the failing tests in `tests/unit/test_chapter_view_portraits.gd`**

A separate file, same reasoning as `test_chapter_view_background.gd` - its fixture creates and deletes files on disk, so it should only run around these tests, not the rest of the suite.

```gdscript
extends GutTest

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")
const NPC_FIXTURE_PATH := "res://assets/portraits/__test_fixture_npc__.png"
# Stage 98 is synthetic and out of npcs.json's real range (1-3) - using a real
# stage number here (e.g. farrukh_stage_1.png) would mean after_each() deletes
# the real, committed asset once the human has actually run the generator.
const FARRUKH_FIXTURE_STAGE := 98
const FARRUKH_FIXTURE_PATH := "res://assets/portraits/farrukh_stage_98.png"

func before_each():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/portraits"))
	var fixture_image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	fixture_image.fill(Color.RED)
	fixture_image.save_png(NPC_FIXTURE_PATH)
	fixture_image.save_png(FARRUKH_FIXTURE_PATH)

func after_each():
	for path in [NPC_FIXTURE_PATH, FARRUKH_FIXTURE_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _view_with_node(node: Dictionary, farrukh_wear_stage: int = 1):
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([node], node["id"])
	chapter_view.farrukh_wear_stage = farrukh_wear_stage
	return chapter_view

func test_npc_portrait_shows_when_the_current_node_names_one_that_exists_on_disk():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "npc_portrait": "__test_fixture_npc__", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("NpcPortrait")
	assert_not_null(npc_portrait.texture)

func test_npc_portrait_is_absent_when_the_current_node_names_none():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("NpcPortrait")
	assert_null(npc_portrait.texture)

func test_npc_portrait_clears_when_moving_from_a_named_node_to_one_with_none():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "npc_portrait": "__test_fixture_npc__", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("NpcPortrait")
	assert_not_null(npc_portrait.texture, "sanity check: must actually be set first")

	chapter_view.dialogue_engine.load_tree([{"id": "n02", "text": "", "choices": []}], "n02")
	chapter_view._update_portraits()
	assert_null(npc_portrait.texture)

func test_farrukh_portrait_always_shows_using_the_loaded_wear_stage():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []}, FARRUKH_FIXTURE_STAGE)
	chapter_view._update_portraits()
	var farrukh_portrait: TextureRect = chapter_view.get_node("FarrukhPortrait")
	assert_not_null(farrukh_portrait.texture, "Farrukh's bust must show even on a node with zero NPCs")

func test_farrukh_portrait_missing_file_clears_without_erroring():
	# 99 is synthetic and deliberately has no fixture file at all (unlike 98, which
	# before_each() creates) - proves the missing-file fallback without touching
	# any real stage_1/2/3 art.
	var chapter_view = _view_with_node({"id": "n01", "text": "", "choices": []}, 99)
	chapter_view._update_portraits()
	var farrukh_portrait: TextureRect = chapter_view.get_node("FarrukhPortrait")
	assert_null(farrukh_portrait.texture, "stage 99 has no fixture file on disk, so this must clear rather than error")

func test_npc_portrait_with_unknown_id_clears_without_erroring():
	var chapter_view = _view_with_node({"id": "n01", "text": "", "npc_portrait": "no_such_npc", "choices": []})
	chapter_view._update_portraits()
	var npc_portrait: TextureRect = chapter_view.get_node("NpcPortrait")
	assert_null(npc_portrait.texture)
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_chapter_view_portraits.gd` FAILS - `ChapterView` has no `NpcPortrait`/`FarrukhPortrait` nodes yet, no `farrukh_wear_stage` member, and no `_update_portraits()` method.

- [ ] **Step 3: Add the `NpcPortrait` and `FarrukhPortrait` `TextureRect` nodes to `ChapterView.tscn`**

The current file's node order is: `ChapterView` (root) → `Background` → `StatusReadout` → `NarrationLabel` → `ChoicesContainer` → `MarginPopup`. Insert both new nodes **after `ChoicesContainer` and before `MarginPopup`** - drawn on top of the background/status/narration/choices (so the busts are visible over the scene), but still under `MarginPopup` (so a clicked glossary popup - which overlaps this same bottom-right region - still wins, unchanged from today's behavior).

```
[node name="NpcPortrait" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = -280.0
offset_right = 88.0
offset_bottom = -208.0
expand_mode = 1
stretch_mode = 6

[node name="FarrukhPortrait" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -88.0
offset_top = -280.0
offset_right = -16.0
offset_bottom = -208.0
expand_mode = 1
stretch_mode = 6
```

(`anchors_preset = 2` is `PRESET_BOTTOM_LEFT`, `anchors_preset = 3` is `PRESET_BOTTOM_RIGHT` - the same preset `MarginPopup` already uses. Both busts are a 72x72 box sitting directly above `ChoicesContainer`'s top edge (`offset_top = -200.0` on that node) with an 8px gap. `expand_mode`/`stretch_mode` match `Background`'s own values, for the same reason: fill the box without distorting the image.)

The full file's node declarations should now read, in this order: `ChapterView` (root) → `Background` → `StatusReadout` → `NarrationLabel` → `ChoicesContainer` → `NpcPortrait` → `FarrukhPortrait` → `MarginPopup`.

- [ ] **Step 4: Add the new members and `_update_portraits()` to `ChapterView.gd`**

Add these two `@onready` lines next to the existing ones near the top of the file:

```gdscript
@onready var npc_portrait: TextureRect = $NpcPortrait
@onready var farrukh_portrait: TextureRect = $FarrukhPortrait
```

Add this new member next to the existing `var next_chapter_id = null`:

```gdscript
var farrukh_wear_stage: int = 1
```

In `load_chapter_by_id()`, set it from the manifest entry alongside the existing `next_chapter_id` line:

```gdscript
	var entry: Dictionary = manifest[id]
	chapter_id = id
	next_chapter_id = entry.get("next_chapter_id", null)
	# JSON.parse_string() parses all numbers as float, same reason _apply_effects()
	# already casts reputation deltas explicitly - farrukh_wear_stage must be int
	# for the "farrukh_stage_%d" format string in _update_portraits() below.
	farrukh_wear_stage = int(entry.get("farrukh_wear_stage", 1))
	load_chapter(entry["dialogue_path"], entry["glossary_path"])
```

Add this new method anywhere after `_update_background()`:

```gdscript
func _update_portraits() -> void:
	var npc_id = dialogue_engine.current_node().get("npc_portrait", null)
	npc_portrait.texture = _load_portrait_texture(npc_id)
	farrukh_portrait.texture = _load_portrait_texture("farrukh_stage_%d" % farrukh_wear_stage)

func _load_portrait_texture(portrait_id) -> Texture2D:
	if portrait_id == null:
		return null
	var path := "res://assets/portraits/%s.png" % portrait_id
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)
```

In `_render_current_node()`, add a call to the new method alongside the existing `_update_background()` call:

```gdscript
func _render_current_node() -> void:
	dialogue_engine.reputation = reputation_tracker.to_dict()
	_update_status_readout()
	_update_background()
	_update_portraits()
	var node := dialogue_engine.current_node()
	narration_label.text = GlossedTextParser.parse_to_bbcode(node.get("text", ""))
	...
```

(Only the new `_update_portraits()` line is added; everything else in `_render_current_node()` stays exactly as it is.)

- [ ] **Step 5: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_chapter_view_portraits.gd` passes, and the whole suite is still green (235 tests before this task; 241 after - 235 + 6 new).

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.tscn scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view_portraits.gd
git commit -m "feat: display NPC and Farrukh portraits above the choices"
```

---

## Self-Review Notes

- **Spec coverage:** roster/13 NPCs → Task 1 Step 4 (`npcs.json`) and Task 2 Step 1 (node keys). Farrukh's 3 chained stages → Task 1 Step 5 (`run_farrukh_stages`'s init_image chaining) and Task 2 Step 2 (manifest field). The `next_chapter_id`-style node-key mechanism → Task 2 Step 1 and Task 3 Step 4 (`current_node().get("npc_portrait", null)`). Layout (corner busts, drawn after `ChoicesContainer`, before `MarginPopup`) → Task 3 Step 3. `no_background: true` for portraits vs. full-scene backgrounds → Task 1 Steps 4-5. Shared style/negative-description/generations-usage-bypass with the background generator → Task 1 Steps 1-2 (the `pixflux_client.py` extraction). "Never spend real credits during implementation" → satisfied by Task 1 Steps 3 and 6, both fully mocked. No-automated-test carve-out for the generator scripts → stated in Global Constraints, honored by Steps 3/6 being transient.
- **Placeholder scan:** none found - every step has literal file content or an exact, unambiguous table of values, not a description of what to do.
- **Type consistency:** `_update_portraits()` defined once (Task 3 Step 4), called once (same step). `farrukh_wear_stage` is `int` everywhere it appears - the manifest JSON value (Task 2 Step 2), the new `ChapterView.gd` member's declared type (Task 3 Step 4), and the GUT test's literal arguments (Task 3 Step 1) all agree. `npc_portrait` is a `String` (a lookup key) everywhere - JSON node key (Task 2), `.get("npc_portrait", null)` call site (Task 3), and every test fixture.
- **Task independence confirmed:** Task 2 needs nothing from Task 1 (it edits chapter JSON directly) or Task 3 (its test parses JSON directly, never touches `ChapterView`). Task 3 needs nothing from Task 1 (fixtures are synthetic, same discipline as the background pass) or Task 2 (its tests construct nodes inline via `dialogue_engine.load_tree()` rather than loading real chapter files). Any task can be implemented, reviewed, and merged before either of the others.
- **Known limitation carried forward, not solved here:** same exported-build gap already recorded for backgrounds (raw `res://` PNG reads via `FileAccess`/`Image.load_from_file()` don't survive an export) - this pass uses the identical mechanism, so it inherits the identical, already-accepted limitation. Not re-documented as a new decision; the backgrounds design spec's note already covers it.
- **Advisor pass caught and fixed before dispatch:** (1) Task 3's tests originally used `farrukh_stage_1.png` as their fixture path - a real production filename that `after_each()` would delete on every suite run once real art is committed, and a "stage 2 has no art" assertion that goes stale the moment real art exists. Switched to synthetic, out-of-range stage numbers 98/99, matching the same synthetic-id discipline the background pass already established (`__test_fixture_chapter__`). (2) Herat 4A's and Herat-Favor 4B's node-id tables were originally abbreviated placeholders with a "use the file's real id" hedge - the single largest, least-verifiable block of edits in the plan. Replaced with the real ids, read directly from both files, plus two new test assertions covering nodes from the previously-abbreviated middle of each chapter so a wrong or skipped id fails loudly instead of passing silently. (3) `STYLE_CLAUSE`'s "illuminated manuscript background" phrase fights `no_background: true` on every bust - added a separate `PORTRAIT_STYLE_CLAUSE` without that phrase, used only by `generate_portraits.py`.
- **Caught by Task 2's own implementer, fixed in the plan before Task 3 dispatch:** `JSON.parse_string()` parses every number as float, so `entry.get("farrukh_wear_stage", 1)` in `load_chapter_by_id()` would assign a float into the `int`-typed `farrukh_wear_stage` member - same class of bug `_apply_effects()` already casts around explicitly elsewhere in this file. Task 3 Step 4 now wraps it in `int(...)`.
