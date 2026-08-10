# Pixellab Art Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an offline, re-runnable Python tool that generates ten Persian-miniature-style location background PNGs via pixellab's `pixflux` API, and wire `ChapterView` to display whichever of those PNGs exists for the current chapter, with a silent no-op fallback for any chapter that doesn't have one yet.

**Architecture:** Two independent halves. `tools/pixellab/` is a standalone Python script + JSON manifest that never runs inside the shipped game and is never touched by GDScript. `ChapterView`'s new `_update_background()` only ever reads raw PNG bytes off disk via `FileAccess.file_exists()` + `Image.load_from_file()` — the same raw-file-loading convention the codebase already uses for JSON content (`load_chapter()`/`load_chapter_by_id()` use `FileAccess.open()`, never Godot's `load()`/resource-import pipeline). This is deliberate: a PNG dropped into `assets/backgrounds/` by the Python script, in a fresh checkout that has never had its editor opened, loads immediately — no import-cache dependency, no new priming step.

**Tech Stack:** Python 3 + the `pixellab` PyPI package (offline tool only) · Godot 4.3 / GDScript (`Image`, `ImageTexture`, `TextureRect`) · GUT for the GDScript test.

## Global Constraints

- Godot 4.3 floor (matches the rest of the project).
- GUT headless test discipline: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`; a fresh worktree needs one priming run first (`godot --headless --path . --editor --quit`) — never run priming twice in the same worktree (known-harmless SIGSEGV on the second attempt, but don't trigger it).
- Commit per task.
- **No task in this plan may spend real pixellab credits or make a real network call.** Task 1's script is verified by code inspection and a throwaway, non-committed mock-based dry run (a fake client object, not `pixellab.Client`). The real 10-image generation against the live API is a manual step the human runs by hand, afterward, outside this plan's task loop.
- `tools/pixellab/generate_backgrounds.py` gets no committed automated test file — a deliberate, explicitly-stated carve-out (see the design spec's "Testing" section), not an oversight. Task 1's own verification step below is transient, run once during implementation, and not checked in.
- `ChapterView`'s new code *does* get a normal committed GUT test, per the project's existing discipline for everything under `scenes/`.

---

## Task 1: `tools/pixellab/` generator

**Files:**
- Create: `tools/pixellab/locations.json`
- Create: `tools/pixellab/generate_backgrounds.py`
- Create: `tools/pixellab/README.md`
- Create: `.env.example`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: nothing from other tasks (this task has no dependency on Task 2).
- Produces: nothing Task 2 depends on either — Task 2's test builds its own throwaway PNG fixture rather than relying on this task's script having ever actually run. This task's real output (`assets/backgrounds/*.png`) is produced later, by hand, by the human running the script for real.

- [ ] **Step 1: Write `tools/pixellab/locations.json`**

```json
[
  {
    "output": "ghazni.png",
    "chapter_ids": ["chapter_00_prologue"],
    "description": "a busy capital bazaar street of mud-brick shopfronts and a mosque courtyard, market stalls and awnings, a quiet graveyard just beyond the city wall"
  },
  {
    "output": "teginabad.png",
    "chapter_ids": ["chapter_01_teginabad"],
    "description": "a fortress gate of patterned brick squatting on a narrow desert road, thick defensive walls, a single watchtower, dusty ochre stone against a pale open sky"
  },
  {
    "output": "bost.png",
    "chapter_ids": ["chapter_02_bost"],
    "description": "a canal-fed green valley beneath low domes and a long red-brick palace facade, a garrison-market town catching the last sun"
  },
  {
    "output": "farah.png",
    "chapter_ids": ["chapter_03_farah"],
    "description": "a scatter of mud-brick huts and tamarisk windbreaks at a dusty crossroads, thin irrigation channels threading pale desert scrubland"
  },
  {
    "output": "herat.png",
    "chapter_ids": ["chapter_04a_herat", "chapter_04b_herat_favor"],
    "description": "a green river valley city among dense orchards, a wide steady river, domed rooftops rising from garden greenery"
  },
  {
    "output": "road_west.png",
    "chapter_ids": ["chapter_05_plunder_ending"],
    "description": "an empty open road running west through flat indifferent country under a wide pale sky, no city or wall in sight"
  },
  {
    "output": "pushang.png",
    "chapter_ids": ["chapter_06_pushang"],
    "description": "a smaller walled town of the same patterned brick and canal-fed green as a larger sister city, modest ramparts against patient desert"
  },
  {
    "output": "sarakhs.png",
    "chapter_ids": ["chapter_07_sarakhs"],
    "description": "a heavy fortress gate astride a road on a river's near bank, thick stone walls and a garrison yard, a wide river marking the frontier beyond"
  },
  {
    "output": "merv.png",
    "chapter_ids": ["chapter_07b_merv"],
    "description": "an old provincial capital threaded by canals, market streets and an oasis of green amid open desert"
  },
  {
    "output": "nishapur.png",
    "chapter_ids": ["chapter_08_nishapur"],
    "description": "a bustling turquoise-stone market street, stalls of blue-green mineral wealth, a settled provincial capital under open sky"
  }
]
```

- [ ] **Step 2: Write `tools/pixellab/generate_backgrounds.py`**

```python
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
    response = client.generate_image_pixflux(
        description=build_description(entry),
        image_size=IMAGE_SIZE,
        negative_description=NEGATIVE_DESCRIPTION,
        seed=compute_seed(entry["output"]),
        **GENERATION_PARAMS,
    )
    image = response.image.pil_image()
    backgrounds_dir.mkdir(parents=True, exist_ok=True)
    primary_path = backgrounds_dir / entry["output"]
    image.save(primary_path)
    for chapter_id in entry["chapter_ids"]:
        chapter_path = backgrounds_dir / f"{chapter_id}.png"
        if chapter_path != primary_path:
            image.save(chapter_path)
    return response.usage.usd, primary_path


def run(client, locations: list[dict], force, backgrounds_dir: Path = BACKGROUNDS_DIR) -> list[str]:
    """force: None (skip anything already on disk), True (regenerate everything),
    or an output filename string (regenerate just that one location).
    Returns the list of output filenames that failed to generate."""
    total_cost = 0.0
    failures: list[str] = []
    for entry in locations:
        primary_path = backgrounds_dir / entry["output"]
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
        print(f"generated {path} (${cost:.4f})")
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
```

- [ ] **Step 3: Verify the script's logic with a throwaway mock run — do NOT install `pixellab` or hit the network for this**

This step is transient verification, not a committed test. Run it from `tools/pixellab/`:

```bash
cd tools/pixellab
python3 -c "
import sys, tempfile
from pathlib import Path
sys.path.insert(0, '.')
import generate_backgrounds as gb

class FakeImage:
    def save(self, path):
        Path(path).write_bytes(b'fake-png-bytes')

class FakeUsage:
    usd = 0.01

class FakeResponse:
    image = FakeImage()
    usage = FakeUsage()

class FakeClient:
    calls = []
    def generate_image_pixflux(self, **kwargs):
        FakeClient.calls.append(kwargs)
        return FakeResponse()

with tempfile.TemporaryDirectory() as tmp:
    backgrounds_dir = Path(tmp)
    locations = gb.load_locations()
    assert len(locations) == 10, f'expected 10 locations, got {len(locations)}'

    client = FakeClient()
    failures = gb.run(client, locations, force=None, backgrounds_dir=backgrounds_dir)
    assert failures == [], failures
    assert len(FakeClient.calls) == 10, f'expected 10 generate calls, got {len(FakeClient.calls)}'
    assert (backgrounds_dir / 'ghazni.png').exists()
    assert (backgrounds_dir / 'herat.png').exists()
    assert (backgrounds_dir / 'chapter_04a_herat.png').exists(), 'herat.png must be copied to chapter_04a_herat.png'
    assert (backgrounds_dir / 'chapter_04b_herat_favor.png').exists(), 'herat.png must be copied to chapter_04b_herat_favor.png'

    # second run with no --force: everything already exists, zero new calls
    failures2 = gb.run(client, locations, force=None, backgrounds_dir=backgrounds_dir)
    assert len(FakeClient.calls) == 10, 'idempotent re-run must not generate again'

    # --force herat.png: exactly one new call, targeting herat.png
    failures3 = gb.run(client, locations, force='herat.png', backgrounds_dir=backgrounds_dir)
    assert len(FakeClient.calls) == 11, '--force herat.png must trigger exactly one new call'

    seed_a = gb.compute_seed('herat.png')
    seed_b = gb.compute_seed('herat.png')
    assert seed_a == seed_b, 'seed must be deterministic for the same output name'
    assert isinstance(seed_a, int) and 0 <= seed_a < 1_000_000

print('OK: all mock-based checks passed')
"
```

Expected output: `OK: all mock-based checks passed`. If any `assert` fails, fix `generate_backgrounds.py` (not the check) and re-run this exact command until it passes. Nothing from this step is committed — it's a one-time confidence check on the logic.

- [ ] **Step 4: Write `tools/pixellab/README.md`**

```markdown
# Pixellab art generator

Generates the game's location background PNGs via [pixellab.ai](https://www.pixellab.ai)'s
`pixflux` API. Offline dev tool — the shipped game never calls this API; it only
ever reads whatever PNGs already exist under `assets/backgrounds/`.

## Setup

1. Get an API token from your pixellab.ai account dashboard.
2. `pip install pixellab`
3. Copy `.env.example` (repo root) to `.env` and fill in your token:
   ```
   PIXELLAB_SECRET=your-token-here
   ```
   `.env` is gitignored — never commit your real token.

## Usage

From the repo root:

```bash
python3 tools/pixellab/generate_backgrounds.py
```

Generates every location listed in `locations.json` that doesn't already have
a PNG under `assets/backgrounds/`. Safe to re-run — already-generated
locations are skipped, so it costs nothing to run again after adding one new
location.

To force a regeneration:

```bash
python3 tools/pixellab/generate_backgrounds.py --force              # regenerate everything
python3 tools/pixellab/generate_backgrounds.py --force herat.png    # regenerate just one location
```

Each location is generated once and its PNG is copied to every chapter id
listed in its `chapter_ids` array (e.g. Herat's Chapter 4A and 4B share one
generated image, so this only spends one generation, not two).

## Adding a new location

Add an entry to `locations.json`:

```json
{
  "output": "some_place.png",
  "chapter_ids": ["chapter_09_some_place"],
  "description": "one line, grounded in that chapter's actual opening prose"
}
```

Then re-run the script — it will only generate the new entry.
```

- [ ] **Step 5: Write `.env.example` at the repo root**

```
# Copy this file to .env and fill in your real pixellab.ai token.
# Get a token from your pixellab.ai account dashboard.
# .env is gitignored - never commit your real token.
PIXELLAB_SECRET=
```

- [ ] **Step 6: Add `.env` to `.gitignore`**

Open `.gitignore` (currently: `.godot/`, `*.tmp`, `export.cfg`, `export_presets.cfg`, `.worktrees/`) and add one new line:

```
.env
```

(`.env.example` is not gitignored — it stays committed as the template.)

- [ ] **Step 7: Commit**

```bash
git add tools/pixellab/locations.json tools/pixellab/generate_backgrounds.py tools/pixellab/README.md .env.example .gitignore
git commit -m "feat: add pixellab background art generator"
```

---

## Task 2: `ChapterView` background display

**Files:**
- Modify: `scenes/chapter_view/ChapterView.tscn`
- Modify: `scenes/chapter_view/ChapterView.gd`
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `chapter_id: String` (already exists on `ChapterView.gd`, set inside `load_chapter_by_id()` before `load_chapter()` runs — see `ChapterView.gd:65-67`).
- Produces: `_update_background() -> void`, called from `_render_current_node()`. Nothing later depends on this beyond `ChapterView` itself — this is the last task in the plan.

- [ ] **Step 1: Write the failing tests in `tests/unit/test_chapter_view.gd`**

Add these two new tests. Place them anywhere in the file after the existing `const ChapterViewScene := preload(...)` line (around line 17) so they can use it:

```gdscript
func before_each():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/backgrounds"))
	var fixture_image := Image.create_empty(4, 4, false, Image.FORMAT_RGB8)
	fixture_image.fill(Color.RED)
	fixture_image.save_png("res://assets/backgrounds/__test_fixture_chapter__.png")

func after_each():
	var fixture_path := ProjectSettings.globalize_path("res://assets/backgrounds/__test_fixture_chapter__.png")
	if FileAccess.file_exists("res://assets/backgrounds/__test_fixture_chapter__.png"):
		DirAccess.remove_absolute(fixture_path)

func test_update_background_sets_a_texture_when_a_background_png_exists_for_the_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.chapter_id = "__test_fixture_chapter__"
	chapter_view._update_background()
	var background: TextureRect = chapter_view.get_node("Background")
	assert_not_null(background.texture)

func test_update_background_leaves_texture_null_when_no_background_png_exists_for_the_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.chapter_id = "chapter_id_with_no_art_yet"
	chapter_view._update_background()
	var background: TextureRect = chapter_view.get_node("Background")
	assert_null(background.texture)
```

`before_each`/`after_each` are GUT lifecycle hooks that run around every test in this file — check the top of the existing file first: if it does not already define `before_each`/`after_each`, add these exactly as shown; if it already defines either one, merge this fixture's body into the existing hook instead of declaring it twice (GDScript does not allow two functions with the same name in one file).

- [ ] **Step 2: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both new tests FAIL. `test_update_background_sets_a_texture_when_a_background_png_exists_for_the_chapter_id` fails because `ChapterView` has no `Background` node yet (`get_node("Background")` returns null and the next line errors) and no `_update_background()` method. `test_update_background_leaves_texture_null_when_no_background_png_exists_for_the_chapter_id` fails the same way.

- [ ] **Step 3: Add the `Background` `TextureRect` node to `ChapterView.tscn`**

The current file (`scenes/chapter_view/ChapterView.tscn`) declares child nodes in this order: `StatusReadout`, `NarrationLabel`, `ChoicesContainer`, `MarginPopup`. Godot draws `Control` siblings in declaration order, each one on top of the ones before it — so `Background` must be inserted **before** `StatusReadout` to render behind everything else.

Insert this block immediately after the `[node name="ChapterView" type="Control"]` block's properties (i.e. right after the `script = ExtResource("1")` line) and before the existing `[node name="StatusReadout" ...]` block:

```
[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
expand_mode = 1
stretch_mode = 6
```

(`expand_mode = 1` is `EXPAND_IGNORE_SIZE`, `stretch_mode = 6` is `STRETCH_KEEP_ASPECT_COVERED` — fills the full rect without distorting the image, per Godot 4.3's `TextureRect` enum values.)

The full file's node declarations should now read, in this order: `ChapterView` (root) → `Background` → `StatusReadout` → `NarrationLabel` → `ChoicesContainer` → `MarginPopup`. Do not change anything else in the file.

- [ ] **Step 4: Add `_update_background()` to `ChapterView.gd` and call it from `_render_current_node()`**

Add the new `@onready` line next to the existing ones near the top of the file (`ChapterView.gd:3-6`):

```gdscript
@onready var background: TextureRect = $Background
```

Add this new method anywhere after `_render_current_node()` (e.g. directly after `_update_status_readout()`):

```gdscript
func _update_background() -> void:
	var path := "res://assets/backgrounds/%s.png" % chapter_id
	if not FileAccess.file_exists(path):
		background.texture = null
		return
	var image := Image.load_from_file(path)
	if image == null:
		background.texture = null
		return
	background.texture = ImageTexture.create_from_image(image)
```

In `_render_current_node()` (`ChapterView.gd:72-89`), add a call to the new method alongside the existing `_update_status_readout()` call:

```gdscript
func _render_current_node() -> void:
	dialogue_engine.reputation = reputation_tracker.to_dict()
	_update_status_readout()
	_update_background()
	var node := dialogue_engine.current_node()
	narration_label.text = GlossedTextParser.parse_to_bbcode(node.get("text", ""))
	...
```

(Only the new `_update_background()` line is added; everything else in `_render_current_node()` stays exactly as it is.)

- [ ] **Step 5: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both new tests PASS, and every pre-existing test in the suite still passes (226 tests before this task; 228 after).

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.tscn scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd
git commit -m "feat: display a location background behind chapter dialogue"
```

---

## Self-Review Notes

- **Spec coverage:** locations table (10/10, including the shared Herat pair) → Task 1 Step 1. Prompt template / style params → Task 1 Step 2 constants. Secrets handling (`PIXELLAB_SECRET`, `.env`/`.env.example`, gitignore) → Task 1 Steps 5-6. Idempotent skip + `--force` + per-location error isolation + cost/balance reporting → Task 1 Step 2 `run()`/`main()`. `tools/pixellab/README.md` → Task 1 Step 4. Background display + null-safe fallback → Task 2 Steps 3-4. GUT tests for both the found and missing-art paths → Task 2 Step 1. Explicit no-automated-test carve-out for the generator, with a stated alternative verification → Task 1 Step 3. "Never spend real credits/network during implementation" constraint → satisfied by Task 1 Step 3 using a fully fake client, never `pixellab.Client`.
- **Placeholder scan:** none found — every step has literal file content, not a description of content.
- **Type consistency:** `_update_background()` is defined once (Task 2 Step 4) and called once (same step); no other task references it. `chapter_id` is read-only from this plan's perspective (already produced by existing code) and its type (`String`) is used consistently with `%s` formatting, matching the existing `save_path()` method's own use of `chapter_id` two lines away in the same file.
- **Task independence confirmed:** Task 2's test fixture (`__test_fixture_chapter__.png`, written and deleted by the test itself) has zero dependency on Task 1 ever having produced a real background — verified explicitly so the two tasks can be implemented, reviewed, and tested in either order without one blocking the other.
