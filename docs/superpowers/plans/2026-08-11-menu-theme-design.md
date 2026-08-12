# Menu Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a project-wide Godot `Theme` (EB Garamond font, boxed brown/gold buttons with real disabled-state contrast) plus a bordeaux cloth-banner panel on `MainMenu`/`JourneyMapScreen` only, per `docs/superpowers/specs/2026-08-11-menu-theme-design.md`.

**Architecture:** A GDScript class (`BorrowedFortuneTheme.build() -> Theme`) constructs the whole `Theme` object in code — `set_stylebox`/`set_color`/`set_font_size`/`set_type_variation` calls fail loudly on a typo and are directly unit-testable, unlike hand-typed `.tres` resource keys. A one-off script (`tools/build_theme.gd`) runs it once and saves the result as a real committed `res://theme/borrowed_fortune_theme.tres`, wired in project-wide via `project.godot`'s `[gui] theme/custom`. The banner's cloth shape is generated art (pixellab, transparent background); the gold trim is two native `ColorRect` nodes — Godot's `StyleBox` system can't draw a tapered pennant without a shader, and this project has none.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless), Python 3 + pixellab SDK (offline dev tool, not shipped), Google Fonts CSS API (EB Garamond TTFs).

## Global Constraints

- Godot 4.3.
- GUT headless test discipline: prime once per fresh worktree via `godot --headless --path . --editor --quit` (expect a possible harmless SIGSEGV on that first priming run — confirmed harmless repeatedly this session). Never re-run priming twice in the same worktree except to fix a confirmed real gap (see Task 1 Step 4). This priming pass's only purpose in this plan is rebuilding `.godot/global_script_class_cache.cfg` (needed because Task 1 adds a new `class_name` file) — it is **not** needed for font loading (see next bullet).
- No shaders anywhere in this codebase — this is why the banner shape is generated art with native `ColorRect` trim, not a `StyleBox`/shader trick.
- Any pixellab-generated PNG is loaded at runtime via raw `FileAccess.file_exists()` + `Image.load_from_file()` + `ImageTexture.create_from_image()` — never Godot's `load()`/resource-import pipeline. Font `.ttf` files follow the same philosophy for the same reason, via a different API: `FontFile.new()` + `load_dynamic_font(path)` (see Task 1 Step 3) reads the raw TTF bytes at runtime and was confirmed, empirically, to work in this environment where `load()` on a freshly-`curl`'d font does not — a fresh worktree's editor-mode import scan never actually completes here (the GUT editor plugin crashes on its own bundled assets before `EditorFileSystem` gets a turn, deterministically, confirmed across 3 separate priming attempts). Never use plain `load()` for these two font files.
- Commit per task.
- Standing project override in effect: **no reviewer subagent dispatch at any stage** — this overrides subagent-driven-development's default per-task reviewer step. The controller self-verifies every diff (`git diff`) and every test run directly instead.
- Test baseline confirmed on current master just before this plan was written: **274 tests, 273 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated to this work — do not attempt to fix it), 1089 asserts.
- Isolation: `git worktree add -b menu-theme master .worktrees/menu-theme` (or similar) from the repo root — not the generic `EnterWorktree` tool, per this project's established convention.

---

## File Structure

| File | Task | Purpose |
|---|---|---|
| `assets/fonts/EBGaramond-Regular.ttf`, `EBGaramond-Bold.ttf` | 1 | Create — font files |
| `assets/fonts/LICENSE-EBGaramond.txt` | 1 | Create — OFL license text |
| `engine/theme/BorrowedFortuneTheme.gd` | 1 | Create — `Theme` builder class |
| `tools/build_theme.gd` | 1 | Create — one-off generation script (Godot `-s` entry point) |
| `theme/borrowed_fortune_theme.tres` | 1 | Create — generated output, committed |
| `project.godot` | 1 | Modify — add `[gui] theme/custom=` |
| `tests/unit/test_borrowed_fortune_theme.gd` | 1 | Create — GUT test for the builder |
| `tools/pixellab/ui_assets.json` | 2 | Create — 2 banner art entries |
| `tools/pixellab/generate_ui_assets.py` | 2 | Create — generator script |
| `scenes/main_menu/MainMenu.tscn` | 3 | Modify — `BannerPanel` restructure |
| `scenes/main_menu/MainMenu.gd` | 3 | Modify — banner texture load + bold-button toggle |
| `tests/unit/test_main_menu.gd` | 3 | Modify — updated `get_node` paths |
| `scenes/journey_map/JourneyMapScreen.tscn` | 4 | Modify — `TitleBannerPanel` restructure |
| `scenes/journey_map/JourneyMapScreen.gd` | 4 | Modify — banner texture load |

---

### Task 1: Font, project-wide Theme, and `project.godot` wiring

**Files:**
- Create: `assets/fonts/EBGaramond-Regular.ttf`, `assets/fonts/EBGaramond-Bold.ttf`, `assets/fonts/LICENSE-EBGaramond.txt`
- Create: `engine/theme/BorrowedFortuneTheme.gd`
- Create: `tools/build_theme.gd`
- Create: `theme/borrowed_fortune_theme.tres` (generated, not hand-written)
- Modify: `project.godot`
- Test: `tests/unit/test_borrowed_fortune_theme.gd`

**Interfaces:**
- Produces: `BorrowedFortuneTheme.build() -> Theme` (static function, class_name `BorrowedFortuneTheme`) — Task 3 will `preload`/reference the two type-variation name strings this defines: `"BannerButton"` (Button variation) and `"BannerTitle"` (Label variation). Task 3 also needs the two font paths this task fetches: `res://assets/fonts/EBGaramond-Regular.ttf` and `res://assets/fonts/EBGaramond-Bold.ttf` (for its own bold-toggle logic).

- [ ] **Step 1: Fetch the EB Garamond font files**

Run from the repo root:

```bash
curl -s "https://fonts.googleapis.com/css2?family=EB+Garamond:wght@400;700&display=swap" -A "Mozilla/5.0" -o /tmp/ebgaramond.css
grep -oE 'https://fonts.gstatic.com/[^)]+\.ttf' /tmp/ebgaramond.css
```

This prints two URLs — one for weight 400 (Regular), one for weight 700 (Bold). Download each:

```bash
mkdir -p assets/fonts
curl -s "<the 400-weight URL>" -o assets/fonts/EBGaramond-Regular.ttf
curl -s "<the 700-weight URL>" -o assets/fonts/EBGaramond-Bold.ttf
```

Verify both downloaded as real font files, not HTML error pages:

```bash
file assets/fonts/EBGaramond-Regular.ttf assets/fonts/EBGaramond-Bold.ttf
```

Expected: both report as TrueType font data (not "HTML document" or "ASCII text").

- [ ] **Step 2: Add the OFL license file**

Create `assets/fonts/LICENSE-EBGaramond.txt` with the standard SIL Open Font License 1.1 text (fetch it from the canonical source alongside the fonts, or from `https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/OFL.txt`):

```bash
curl -s "https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/OFL.txt" -o assets/fonts/LICENSE-EBGaramond.txt
```

Verify it's non-empty and starts with the OFL preamble:

```bash
head -5 assets/fonts/LICENSE-EBGaramond.txt
```

Expected: starts with `Copyright` and mentions "SIL OPEN FONT LICENSE".

- [ ] **Step 3: Write the `BorrowedFortuneTheme` builder**

Create `engine/theme/BorrowedFortuneTheme.gd`:

```gdscript
extends RefCounted
class_name BorrowedFortuneTheme

const REGULAR_FONT_PATH := "res://assets/fonts/EBGaramond-Regular.ttf"
const BOLD_FONT_PATH := "res://assets/fonts/EBGaramond-Bold.ttf"

const BUTTON_FILL_NORMAL := Color("#3d2a15")
const BUTTON_FILL_HOVER := Color("#4a3520")
const BUTTON_FILL_PRESSED := Color("#2e2013")
const BUTTON_FILL_DISABLED := Color(60.0 / 255.0, 48.0 / 255.0, 32.0 / 255.0, 0.5)
const BUTTON_BORDER := Color("#7a5a32")
const BUTTON_BORDER_DISABLED := Color(122.0 / 255.0, 90.0 / 255.0, 50.0 / 255.0, 0.25)
const BUTTON_TEXT := Color("#f0e6cc")
const BUTTON_TEXT_DISABLED := Color(240.0 / 255.0, 230.0 / 255.0, 204.0 / 255.0, 0.35)
const FOCUS_RING := Color("#6b7f8a")

const BANNER_TEXT := Color("#f2e2c0")
const BANNER_TEXT_DISABLED := Color(0.949, 0.886, 0.753, 0.32)

static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = _load_font(REGULAR_FONT_PATH)

	_apply_global_button_style(theme)
	_apply_banner_button_variation(theme)
	_apply_banner_title_variation(theme)

	return theme

static func _apply_global_button_style(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", _boxed_stylebox(BUTTON_FILL_NORMAL, BUTTON_BORDER))
	theme.set_stylebox("hover", "Button", _boxed_stylebox(BUTTON_FILL_HOVER, BUTTON_BORDER))
	theme.set_stylebox("pressed", "Button", _boxed_stylebox(BUTTON_FILL_PRESSED, BUTTON_BORDER))
	theme.set_stylebox("disabled", "Button", _boxed_stylebox(BUTTON_FILL_DISABLED, BUTTON_BORDER_DISABLED))
	theme.set_stylebox("focus", "Button", _focus_stylebox())

	theme.set_color("font_color", "Button", BUTTON_TEXT)
	theme.set_color("font_hover_color", "Button", BUTTON_TEXT)
	theme.set_color("font_pressed_color", "Button", BUTTON_TEXT)
	theme.set_color("font_focus_color", "Button", BUTTON_TEXT)
	theme.set_color("font_disabled_color", "Button", BUTTON_TEXT_DISABLED)
	theme.set_font_size("font_size", "Button", 18)

static func _apply_banner_button_variation(theme: Theme) -> void:
	theme.set_type_variation("BannerButton", "Button")
	theme.set_stylebox("normal", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("hover", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("pressed", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("disabled", "BannerButton", StyleBoxEmpty.new())
	theme.set_stylebox("focus", "BannerButton", _focus_stylebox())

	theme.set_color("font_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_hover_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_pressed_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_focus_color", "BannerButton", BANNER_TEXT)
	theme.set_color("font_disabled_color", "BannerButton", BANNER_TEXT_DISABLED)
	theme.set_font_size("font_size", "BannerButton", 20)

static func _apply_banner_title_variation(theme: Theme) -> void:
	theme.set_type_variation("BannerTitle", "Label")
	theme.set_font("font", "BannerTitle", _load_font(BOLD_FONT_PATH))
	theme.set_font_size("font_size", "BannerTitle", 36)
	theme.set_color("font_color", "BannerTitle", BANNER_TEXT)
	theme.set_color("font_shadow_color", "BannerTitle", Color(0, 0, 0, 0.4))
	theme.set_constant("shadow_offset_x", "BannerTitle", 2)
	theme.set_constant("shadow_offset_y", "BannerTitle", 2)

static func _load_font(path: String) -> FontFile:
	var font := FontFile.new()
	font.load_dynamic_font(path)
	return font

static func _boxed_stylebox(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	return box

static func _focus_stylebox() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = FOCUS_RING
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	return box
```

`_load_font()` uses `FontFile.new()` + `load_dynamic_font(path)` instead of Godot's `load()` — this is the same reason every pixellab PNG in this project uses raw `FileAccess`/`Image.load_from_file()` instead of `load()`: a font file dropped in via `curl` (not through the editor) has no import metadata (`.godot/imported/...fontdata`) until an editor pass processes it, and — confirmed empirically while writing this plan, across three separate priming attempts in a fresh worktree — that import scan never actually completes in this environment: the GUT editor plugin's own `_enter_tree()` tries to load its bundled UI images (`addons/gut/gui/play.png`, etc.) synchronously at plugin-init time, before `EditorFileSystem`'s import scan gets a turn, and crashes identically every time (confirmed: 3 runs, identical crash, identical zero files in `.godot/imported/` after each). `load_dynamic_font()` reads the raw TTF bytes directly at runtime and is explicitly designed for exactly this case (loading a font Godot's import system has never seen) — it sidesteps the whole problem rather than depending on a Godot-editor import pass that does not reliably complete here.

- [ ] **Step 4: Prime the worktree (class cache only — fonts no longer need this) — run exactly once**

```bash
godot --headless --path . --editor --quit
```

A SIGSEGV on exit is expected and harmless (confirmed repeatedly on this project). Do not re-run this command again in this worktree — its only remaining purpose is rebuilding `.godot/global_script_class_cache.cfg` so the headless GUT runner can resolve the new `BorrowedFortuneTheme` global class name; it is not needed for font loading at all (see the note above `_load_font()`).

Verify the class cache actually picked up the new class:

```bash
grep -c "BorrowedFortuneTheme" .godot/global_script_class_cache.cfg
```

Expected: 2 (one `"class"` entry, one `"path"` entry). If this comes back 0, the priming pass didn't register the class — re-run the same command once (this is the "real, confirmed gap" case the Global Constraints section already carves out an exception for), then re-check.

- [ ] **Step 5: Write and run the one-off theme-generation script**

Create `tools/build_theme.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	var theme := BorrowedFortuneTheme.build()
	var err := ResourceSaver.save(theme, "res://theme/borrowed_fortune_theme.tres")
	if err != OK:
		printerr("Failed to save theme: %s" % error_string(err))
		quit(1)
		return
	print("Theme saved to res://theme/borrowed_fortune_theme.tres")
	quit(0)
```

```bash
mkdir -p theme
godot --headless --path . -s tools/build_theme.gd
```

Expected output: `Theme saved to res://theme/borrowed_fortune_theme.tres`, exit code 0.

```bash
ls -la theme/borrowed_fortune_theme.tres
head -20 theme/borrowed_fortune_theme.tres
```

Expected: the file exists and its header reads `[gd_resource type="Theme" ...]` — a real, human-readable Godot resource file, not empty.

- [ ] **Step 6: Write the GUT test for the builder**

Create `tests/unit/test_borrowed_fortune_theme.gd`:

```gdscript
extends GutTest

func test_button_disabled_text_is_visible_not_washed_out():
	var theme := BorrowedFortuneTheme.build()
	var disabled_color: Color = theme.get_color("font_disabled_color", "Button")
	assert_almost_eq(disabled_color.a, 0.35, 0.001)
	assert_true(disabled_color.a > 0.3)

func test_button_font_size_is_bumped_up_from_default():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("font_size", "Button"), 18)

func test_banner_button_variation_has_no_visible_box():
	var theme := BorrowedFortuneTheme.build()
	var normal_style: StyleBox = theme.get_stylebox("normal", "BannerButton")
	assert_true(normal_style is StyleBoxEmpty)

func test_banner_button_font_size_is_larger_than_global_default():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("font_size", "BannerButton"), 20)

func test_banner_title_uses_the_bold_font_at_36px():
	var theme := BorrowedFortuneTheme.build()
	assert_eq(theme.get_font_size("font_size", "BannerTitle"), 36)
	assert_not_null(theme.get_font("font", "BannerTitle"))

func test_focus_ring_color_matches_the_confirmed_slate_blue():
	var theme := BorrowedFortuneTheme.build()
	var focus_style: StyleBoxFlat = theme.get_stylebox("focus", "Button")
	assert_eq(focus_style.border_color, Color("#6b7f8a"))
```

- [ ] **Step 7: Run the new test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_borrowed_fortune_theme.gd -gexit
```

Expected: `6/6 passed`, 0 failures. If `BorrowedFortuneTheme` is reported as an unknown identifier, the class-cache priming in Step 4 didn't take — re-run Step 4's `find` check; do not re-run the priming command itself a second time without first confirming via `git status`/`.godot/global_script_class_cache.cfg` that it's actually missing the new class (re-priming is safe to repeat if genuinely needed, the "never twice" rule is about avoiding redundant no-op runs, not about refusing a real fix).

- [ ] **Step 8: Wire `project.godot`**

Add a `[gui]` section (project.godot currently has no `[gui]` section):

```ini
[gui]

theme/custom="res://theme/borrowed_fortune_theme.tres"
```

- [ ] **Step 9: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 280 tests (274 baseline + 6 new), 279 passing + the same 1 pre-existing risky test. No new failures. This is the step that would surface any existing test silently depending on Godot's default font metrics (e.g. a text-wrapping assertion) — if anything outside `test_borrowed_fortune_theme.gd` newly fails, read the failure directly; do not assume it's unrelated.

- [ ] **Step 10: Commit**

```bash
git add assets/fonts/ engine/theme/BorrowedFortuneTheme.gd tools/build_theme.gd theme/borrowed_fortune_theme.tres project.godot tests/unit/test_borrowed_fortune_theme.gd
git commit -m "feat: add project-wide Theme (EB Garamond font, boxed button contrast fix)"
```

---

### Task 2: Banner art generation pipeline

**Files:**
- Create: `tools/pixellab/ui_assets.json`
- Create: `tools/pixellab/generate_ui_assets.py`

**Interfaces:**
- Consumes: `pixflux_client.PORTRAIT_STYLE_CLAUSE`, `build_description()`, `compute_seed()`, `generate_pixflux()` (all already defined in `tools/pixellab/pixflux_client.py` — do not modify that file). Uses `PORTRAIT_STYLE_CLAUSE`, not the default `STYLE_CLAUSE`: the default clause's "illuminated manuscript background" phrase actively fights `no_background=True` (this is documented in `pixflux_client.py`'s own `build_description()` docstring, and is exactly why `generate_portraits.py` already uses `PORTRAIT_STYLE_CLAUSE` for its own `no_background=True` calls).
- Produces: `assets/ui/menu_banner_tall.png`, `assets/ui/menu_banner_short.png` (only after the script is actually *run* — this task creates the tool, it does not spend API credits itself). Task 3 and Task 4 load these two exact paths.

- [ ] **Step 1: Write `tools/pixellab/ui_assets.json`**

```json
{
  "ui_assets": [
    {
      "id": "menu_banner_tall",
      "description": "a hanging bordeaux wine-red cloth pennant banner, tapered pointed bottom edge, subtle fabric folds and creases, no text, no border trim, transparent background",
      "width": 300,
      "height": 400
    },
    {
      "id": "menu_banner_short",
      "description": "a hanging bordeaux wine-red cloth pennant banner, tapered pointed bottom edge, subtle fabric folds and creases, no text, no border trim, transparent background",
      "width": 400,
      "height": 168
    }
  ]
}
```

Dimensions confirmed against a live API call, corrected after the fact (not known when this plan was first written): pixflux's `generate-image-pixflux` endpoint rejects any width/height over 400px, and requires both dimensions divisible by 4. The values above already reflect that (rescaled from an earlier 360x480/480x200 draft, same aspect ratios).

- [ ] **Step 2: Write `tools/pixellab/generate_ui_assets.py`**

Mirrors `generate_portraits.py`'s `run_npcs()` shape (per-entry skip-if-exists, `--force` support), not `generate_backgrounds.py`'s (which fans one location out to multiple chapter-id files — not needed here, each entry maps to exactly one output file):

```python
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
```

- [ ] **Step 3: Commit the pipeline**

```bash
git add tools/pixellab/ui_assets.json tools/pixellab/generate_ui_assets.py
git commit -m "feat: add UI asset generation pipeline for transparent banner art"
```

- [ ] **Step 4: Generate the real art (separate real-money step, run right after this task, not deferred)**

This is a real pixellab API call and costs money — matching every prior art-generation step this session, do not run it silently as part of a larger batch:

```bash
python3 tools/pixellab/generate_ui_assets.py
```

Expected: `generated menu_banner_tall -> assets/ui/menu_banner_tall.png (usage: ...)`, same for `menu_banner_short`, then a `remaining balance:` line. If either generation fails, Tasks 3/4 will still run and pass (the null-safe `FileAccess.file_exists()` fallback in `_update_banner()` means a missing PNG renders as no banner texture, not a crash) — but the menus will visibly regress (themed text/buttons floating with no panel behind them) until the art actually exists on disk. Do not treat a failed generation as blocking Tasks 3/4 — retry it, or proceed and retry later; it's independent of the scene-tree work.

```bash
git add assets/ui/menu_banner_tall.png assets/ui/menu_banner_short.png
git commit -m "feat: add generated menu banner art"
```

---

### Task 3: `MainMenu` banner restructure

**Files:**
- Modify: `scenes/main_menu/MainMenu.tscn`
- Modify: `scenes/main_menu/MainMenu.gd`
- Modify: `tests/unit/test_main_menu.gd`

**Interfaces:**
- Consumes: `theme_type_variation` names `"BannerButton"`/`"BannerTitle"` (Task 1); `res://assets/ui/menu_banner_tall.png` (Task 2); the existing `_update_background()` FileAccess/Image/ImageTexture pattern already used in this same file for `Background`, and already used identically in `JourneyMapScreen.gd` for its own background and thumbnails — copy that exact pattern for the new `_update_banner()` method, don't invent a new one.
- Produces: nothing consumed by a later task — this is a leaf scene.

- [ ] **Step 1: Restructure `MainMenu.tscn`**

Replace the full file with:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/main_menu/MainMenu.gd" id="1"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 6

[node name="BannerPanel" type="Control" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -160.0
offset_top = -220.0
offset_right = 160.0
offset_bottom = 220.0

[node name="BannerTexture" type="TextureRect" parent="BannerPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 5

[node name="GoldTrimLeft" type="ColorRect" parent="BannerPanel"]
layout_mode = 1
anchor_bottom = 0.82
offset_right = 6.0
mouse_filter = 2
color = Color(0.788235, 0.635294, 0.294118, 1)

[node name="GoldTrimRight" type="ColorRect" parent="BannerPanel"]
layout_mode = 1
anchor_left = 1.0
anchor_right = 1.0
anchor_bottom = 0.82
offset_left = -6.0
mouse_filter = 2
color = Color(0.788235, 0.635294, 0.294118, 1)

[node name="TitleLabel" type="Label" parent="BannerPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 16.0
offset_top = 24.0
offset_right = -16.0
offset_bottom = 80.0
theme_type_variation = &"BannerTitle"
horizontal_alignment = 1
text = "Borrowed Fortune"

[node name="ButtonsContainer" type="VBoxContainer" parent="BannerPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = 100.0
offset_right = -40.0
offset_bottom = -40.0

[node name="NewGameButton" type="Button" parent="BannerPanel/ButtonsContainer"]
layout_mode = 2
theme_type_variation = &"BannerButton"
text = "New Game"

[node name="ContinueButton" type="Button" parent="BannerPanel/ButtonsContainer"]
layout_mode = 2
theme_type_variation = &"BannerButton"
text = "Continue"

[node name="MapButton" type="Button" parent="BannerPanel/ButtonsContainer"]
layout_mode = 2
theme_type_variation = &"BannerButton"
text = "Map"

[node name="QuitButton" type="Button" parent="BannerPanel/ButtonsContainer"]
layout_mode = 2
theme_type_variation = &"BannerButton"
text = "Quit"
```

Notes on what changed from the shipped file: `TitleLabel`'s old `theme_override_font_sizes/font_size = 36` line is removed — the `"BannerTitle"` variation now supplies that same 36px value, so the local override would be redundant. `Color(0.788235, 0.635294, 0.294118, 1)` is `#c9a24b` in Godot's 0-1 float notation.

- [ ] **Step 2: Update `MainMenu.gd`**

Replace the full file with:

```gdscript
extends Control

const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"
const ROUTE_PATH := "res://content/map/route.json"
const BOLD_FONT := preload("res://assets/fonts/EBGaramond-Bold.ttf")

@onready var background: TextureRect = $Background
@onready var banner_texture: TextureRect = $BannerPanel/BannerTexture
@onready var continue_button: Button = $BannerPanel/ButtonsContainer/ContinueButton
@onready var new_game_button: Button = $BannerPanel/ButtonsContainer/NewGameButton
@onready var map_button: Button = $BannerPanel/ButtonsContainer/MapButton
@onready var quit_button: Button = $BannerPanel/ButtonsContainer/QuitButton

func _ready() -> void:
	_update_background()
	_update_banner()
	continue_button.disabled = not FileAccess.file_exists(POINTER_PATH)
	map_button.disabled = _map_button_should_be_disabled()
	_update_default_action_emphasis()
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	map_button.pressed.connect(_on_map_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _update_background() -> void:
	var path := "res://assets/backgrounds/main_menu.png"
	if not FileAccess.file_exists(path):
		background.texture = null
		return
	var image := Image.load_from_file(path)
	if image == null:
		background.texture = null
		return
	background.texture = ImageTexture.create_from_image(image)

func _update_banner() -> void:
	var path := "res://assets/ui/menu_banner_tall.png"
	if not FileAccess.file_exists(path):
		banner_texture.texture = null
		return
	var image := Image.load_from_file(path)
	if image == null:
		banner_texture.texture = null
		return
	banner_texture.texture = ImageTexture.create_from_image(image)

func _update_default_action_emphasis() -> void:
	if continue_button.disabled:
		new_game_button.add_theme_font_override("font", BOLD_FONT)
		continue_button.remove_theme_font_override("font")
	else:
		continue_button.add_theme_font_override("font", BOLD_FONT)
		new_game_button.remove_theme_font_override("font")

func _map_button_should_be_disabled() -> bool:
	var route_data := _load_route_data()
	var builder := JourneyMapBuilder.new()
	for chapter_id in builder.all_chapter_ids(route_data):
		if FileAccess.file_exists("user://borrowed_fortune_%s.json" % chapter_id):
			return false
	return true

func _load_route_data() -> Dictionary:
	var file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/journey_map/JourneyMapScreen.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
```

`_update_default_action_emphasis()` is the "exactly one button is bold" rule from the spec: bold follows whichever of New Game / Continue is actually the sensible default, using the same `continue_button.disabled` check the method right above it already computes — not a new decision, just made visible.

- [ ] **Step 3: Update `tests/unit/test_main_menu.gd`**

Every `get_node("ButtonsContainer/...")` call becomes `get_node("BannerPanel/ButtonsContainer/...")`. The file has 6 such calls (lines 33, 41, 46, 52, 61, 62 in the pre-Task-3 file). Apply this exact substitution throughout the file — old → new:

```gdscript
menu.get_node("ButtonsContainer/ContinueButton")
```
→
```gdscript
menu.get_node("BannerPanel/ButtonsContainer/ContinueButton")
```

(same substitution for `.../MapButton` at each of its 2 occurrences). No other line in this file changes.

- [ ] **Step 4: Run the main-menu tests**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_main_menu.gd -gexit
```

Expected: `5/5 passed`, 0 failures.

- [ ] **Step 5: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 280 tests total (same count as after Task 1 — this task doesn't add or remove tests), 279 passing + the 1 pre-existing risky test, no new failures.

- [ ] **Step 6: Commit**

```bash
git add scenes/main_menu/MainMenu.tscn scenes/main_menu/MainMenu.gd tests/unit/test_main_menu.gd
git commit -m "feat: restructure MainMenu with bordeaux banner panel and bold default-action emphasis"
```

---

### Task 4: `JourneyMapScreen` banner restructure

**Files:**
- Modify: `scenes/journey_map/JourneyMapScreen.tscn`
- Modify: `scenes/journey_map/JourneyMapScreen.gd`

**Interfaces:**
- Consumes: `"BannerTitle"` type variation (Task 1); `res://assets/ui/menu_banner_short.png` (Task 2); same `_update_banner()` pattern as Task 3.
- Produces: nothing — leaf scene.

**Note:** applying `"BannerTitle"` here changes this screen's title from its current 32px to 36px (the variation's fixed size, matching `MainMenu`'s title). This is a real, visible side effect of sharing one variation across both screens — call it out if it looks odd during a later visual check, but it's the spec's explicit design, not a mistake to "fix" mid-task.

- [ ] **Step 1: Restructure `JourneyMapScreen.tscn`**

Replace the full file with:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/journey_map/JourneyMapScreen.gd" id="1"]

[node name="JourneyMapScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 6

[node name="TitleBannerPanel" type="Control" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.0
anchor_right = 0.5
anchor_bottom = 0.0
offset_left = -240.0
offset_top = 16.0
offset_right = 240.0
offset_bottom = 156.0

[node name="BannerTexture" type="TextureRect" parent="TitleBannerPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
expand_mode = 1
stretch_mode = 5

[node name="GoldTrimLeft" type="ColorRect" parent="TitleBannerPanel"]
layout_mode = 1
anchor_bottom = 0.82
offset_right = 6.0
mouse_filter = 2
color = Color(0.788235, 0.635294, 0.294118, 1)

[node name="GoldTrimRight" type="ColorRect" parent="TitleBannerPanel"]
layout_mode = 1
anchor_left = 1.0
anchor_right = 1.0
anchor_bottom = 0.82
offset_left = -6.0
mouse_filter = 2
color = Color(0.788235, 0.635294, 0.294118, 1)

[node name="TitleLabel" type="Label" parent="TitleBannerPanel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = 8.0
offset_right = -16.0
offset_bottom = -8.0
theme_type_variation = &"BannerTitle"
horizontal_alignment = 1
text = "The Road So Far"

[node name="WaypointsContainer" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -500.0
offset_top = -55.0
offset_right = 500.0
offset_bottom = 55.0

[node name="BackButton" type="Button" parent="."]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = -56.0
offset_right = 116.0
offset_bottom = -16.0
text = "Back"
```

`WaypointsContainer` and `BackButton` are untouched (same anchors/offsets as the shipped file) — only `TitleLabel` moved, into the new `TitleBannerPanel`. `TitleLabel`'s old `theme_override_font_sizes/font_size = 32` line is removed (superseded by `"BannerTitle"`'s 36px, per the note above).

- [ ] **Step 2: Update `JourneyMapScreen.gd`**

Add a `banner_texture` onready var and an `_update_banner()` method, and call it from `_ready()`:

```gdscript
extends Control

const ROUTE_PATH := "res://content/map/route.json"
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

@onready var background: TextureRect = $Background
@onready var banner_texture: TextureRect = $TitleBannerPanel/BannerTexture
@onready var waypoints_container: HBoxContainer = $WaypointsContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	_update_background()
	_update_banner()
	back_button.pressed.connect(_on_back_pressed)
	_render_waypoints()

func _update_background() -> void:
	var path := "res://assets/backgrounds/journey_map.png"
	if not FileAccess.file_exists(path):
		background.texture = null
		return
	var image := Image.load_from_file(path)
	if image == null:
		background.texture = null
		return
	background.texture = ImageTexture.create_from_image(image)

func _update_banner() -> void:
	var path := "res://assets/ui/menu_banner_short.png"
	if not FileAccess.file_exists(path):
		banner_texture.texture = null
		return
	var image := Image.load_from_file(path)
	if image == null:
		banner_texture.texture = null
		return
	banner_texture.texture = ImageTexture.create_from_image(image)

func _render_waypoints() -> void:
	var route_data := _load_route_data()
	var builder := JourneyMapBuilder.new()
	var visited_chapter_ids := _scan_visited_chapter_ids(route_data, builder)
	var current_chapter_id := _read_current_chapter_id()
	var waypoints := builder.build_waypoints(route_data, visited_chapter_ids, current_chapter_id)

	for child in waypoints_container.get_children():
		child.queue_free()
	for waypoint in waypoints:
		waypoints_container.add_child(_build_waypoint_node(waypoint))

func _load_route_data() -> Dictionary:
	var file := FileAccess.open(ROUTE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed

func _scan_visited_chapter_ids(route_data: Dictionary, builder: JourneyMapBuilder) -> Dictionary:
	var visited: Dictionary = {}
	for chapter_id in builder.all_chapter_ids(route_data):
		if FileAccess.file_exists("user://borrowed_fortune_%s.json" % chapter_id):
			visited[chapter_id] = true
	return visited

func _read_current_chapter_id() -> String:
	if not FileAccess.file_exists(POINTER_PATH):
		return ""
	var file := FileAccess.open(POINTER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary) or not parsed.has("chapter_id"):
		return ""
	return parsed["chapter_id"]

func _build_waypoint_node(waypoint: Dictionary) -> Control:
	var container := VBoxContainer.new()
	container.name = waypoint["chapter_id"]

	var texture_rect := TextureRect.new()
	texture_rect.name = "Thumbnail"
	texture_rect.custom_minimum_size = Vector2(112, 63)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture = _load_thumbnail(waypoint["chapter_id"])
	if waypoint["status"] == "unvisited":
		texture_rect.modulate = Color(0.5, 0.5, 0.5, 0.55)
	container.add_child(texture_rect)

	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if waypoint["is_ending"] and waypoint["status"] != "unvisited":
		label.text = "Journey's End"
	elif waypoint["status"] == "current":
		label.text = "▶ %s" % waypoint["display_name"]
	else:
		label.text = waypoint["display_name"]
	container.add_child(label)

	return container

func _load_thumbnail(chapter_id: String) -> Texture2D:
	var path := "res://assets/backgrounds/%s.png" % chapter_id
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
```

Only `banner_texture` and `_update_banner()` are new; everything else in this file is unchanged from the shipped version.

- [ ] **Step 3: Verify `test_journey_map_screen.gd` needs no changes**

```bash
grep -n "get_node\|waypoints_container\|TitleLabel" tests/unit/test_journey_map_screen.gd
```

Confirm every match uses `screen.waypoints_container` (the `@onready` var, untouched) or `.get_child(N)` on `waypoints_container` — none references `TitleLabel` by path. If this turns up a path-based lookup on `TitleLabel` that this plan's summary missed, update it the same way Task 3 updated `test_main_menu.gd`'s paths before proceeding; otherwise no test file edit is needed here.

- [ ] **Step 4: Run the journey-map tests**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_journey_map_screen.gd -gexit
```

Expected: `2/2 passed`, 0 failures.

- [ ] **Step 5: Run the full suite (final regression gate for this plan)**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 280 tests total, 279 passing + the 1 pre-existing risky test, 0 new failures. This is the last task in the plan — a clean run here means the whole theme + banner pass is regression-free.

- [ ] **Step 6: Commit**

```bash
git add scenes/journey_map/JourneyMapScreen.tscn scenes/journey_map/JourneyMapScreen.gd
git commit -m "feat: add title banner panel to JourneyMapScreen"
```

---

## Self-Review

**Spec coverage:**
- "Project-wide Theme resource" → Task 1 (font + global Button style, wired via `project.godot`). ✓
- "Global default Button style" (exact hex/px values) → Task 1's `_apply_global_button_style()`. ✓
- "BannerButton"/"BannerTitle" type variations (exact hex/px values) → Task 1's `_apply_banner_button_variation()`/`_apply_banner_title_variation()`. ✓
- "Exactly one button is bold" rule → Task 3's `_update_default_action_emphasis()`. ✓
- "Banner art: generated cloth shape, native gold trim" → Task 2 (pipeline) + Tasks 3/4 (native `ColorRect` trim, `TextureRect` for the generated shape). ✓
- "Scene structure changes" for `MainMenu.tscn` → Task 3 Step 1. ✓
- "Scene structure changes" for `JourneyMapScreen.tscn` → Task 4 Step 1. ✓
- "`ChapterView.tscn`: no scene changes at all" → no task touches it; it inherits the Theme via `project.godot` alone. ✓ (not a gap — the spec explicitly requires zero edits here)
- Testing section's required `test_main_menu.gd` path updates → Task 3 Step 3. ✓
- Testing section's claim that `test_journey_map_screen.gd` is unaffected → Task 4 Step 3 verifies this rather than assuming it. ✓
- "Font sourcing via Google Fonts CSS API" → Task 1 Step 1. ✓
- OFL license file → Task 1 Step 2. ✓

**Placeholder scan:** no "TBD"/"TODO" strings; every code block is complete, runnable code, not a description of code. Anchor/offset pixel values in Tasks 3/4 are concrete numbers, not ranges or "adjust as needed" language.

**Type/signature consistency:** `BorrowedFortuneTheme.build() -> Theme` (Task 1) is called identically in the GUT test (Task 1 Step 6) and is never called again after that — Tasks 3/4 only reference the *string names* `"BannerButton"`/`"BannerTitle"` it registers, not the function itself, so there's no signature drift risk across tasks. `_update_banner()` appears in both Task 3 and Task 4 as separate per-scene methods (not a shared utility) — intentional, matching this codebase's existing convention of duplicating this exact same small loader per-scene (`MainMenu.gd` and the pre-existing `JourneyMapScreen.gd` already do this for `_update_background()`), not a DRY violation worth introducing an extra shared file for.

**Task granularity check:** Task 1 is the largest (10 steps) because font-fetch, theme-builder, generation-script, and project.godot wiring are all one indivisible deliverable — none of the four is independently testable or reviewable without the others; splitting them would create false checkpoints with no working intermediate state. Tasks 2-4 are each a single coherent, independently-testable deliverable.
