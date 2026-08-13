# Prologue Cold-Open Cutscene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a new, standalone 11-panel cinematic cutscene that plays before the interactive Prologue on every "New Game" press, per `docs/superpowers/specs/2026-08-13-prologue-cutscene-design.md`.

**Architecture:** Task 1 builds the new `PrologueCutscene` scene and its pure/testable logic (panel-duration computation, panel-display), tested against synthetic fixture data — no real art or content file needed yet. Task 2 writes the real 11-panel content JSON, generates the real art via a new pixellab script, wires `MainMenu`'s "New Game" button to the new scene, and does a live verification pass.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless), Python (pixellab tooling).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **305 tests, 304 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this plan: **310** (305 + 4 new tests from Task 1 + 1 new test from Task 2), 309 passing + the same 1 pre-existing risky test.
- No audio/sound anywhere in this pass — this game has no audio system, confirmed via search, and the cutscene stays silent.
- No new persistent "seen the intro" flag — the cutscene plays on every "New Game" press, by explicit user choice.
- Every raw pixellab-generated PNG is loaded via `Image.load_from_file(path)` wrapped in `ImageTexture.create_from_image(image)` — never `load()`/`preload()` on the PNG itself, which never completes in this environment for freshly-dropped assets.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b prologue-cutscene .worktrees/prologue-cutscene master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; if this plan's `PrologueCutscene.gd` does not declare a `class_name`, no re-priming should be needed — but if the implementer does add one, re-run the one-time `godot --headless --path . --editor --quit` priming step before running tests.
- The pixellab pipeline needs the existing `.venv-pixellab` venv and `.env` (both already present in the repo, gitignored) — do not create new ones.

---

## File Structure

| File | Purpose |
|---|---|
| `scenes/prologue_cutscene/PrologueCutscene.gd` | Create (Task 1) — the cutscene's logic |
| `scenes/prologue_cutscene/PrologueCutscene.tscn` | Create (Task 1) — the cutscene's node tree |
| `tests/unit/test_prologue_cutscene.gd` | Create (Task 1) — pure-logic tests; Modify (Task 2) — add the real-content test |
| `content/cutscenes/prologue_intro.json` | Create (Task 2) — the real 11 panels |
| `tools/pixellab/generate_cutscene_panels.py` | Create (Task 2) — generation script |
| `tools/pixellab/cutscene_panels.json` | Create (Task 2) — the 11 image descriptions |
| `assets/cutscenes/prologue_intro_01.png` … `_11.png` | Create (Task 2) — the generated art |
| `scenes/main_menu/MainMenu.gd` | Modify (Task 2) — retarget "New Game" |

---

### Task 1: Build the cutscene scene and its testable logic

**Files:**
- Create: `scenes/prologue_cutscene/PrologueCutscene.gd`
- Create: `scenes/prologue_cutscene/PrologueCutscene.tscn`
- Create: `tests/unit/test_prologue_cutscene.gd`

**Interfaces:**
- Produces: `PrologueCutscene.compute_panel_duration_seconds(caption: String) -> float` (a `static func`, callable via `preload("res://scenes/prologue_cutscene/PrologueCutscene.gd").compute_panel_duration_seconds(...)` without instantiating the scene — mirrors how this project's other pure-logic helpers are unit-tested). Also produces the instance method `_display_panel_data(panel: Dictionary) -> void`, taking `{"image_path": String, "caption": String}` and updating the display — Task 2 does not call this directly (it only supplies the real content file `_ready()` reads), but it is the seam Task 1's own tests use.

- [ ] **Step 1: Write `PrologueCutscene.gd`**

Create `scenes/prologue_cutscene/PrologueCutscene.gd` with exactly this content:

```gdscript
extends Control

const WORDS_PER_MINUTE := 180.0
const MINIMUM_PANEL_SECONDS := 4.0
const MAXIMUM_PANEL_SECONDS := 12.0
const FADE_DURATION_SECONDS := 0.6
const CUTSCENE_CONTENT_PATH := "res://content/cutscenes/prologue_intro.json"
const NEXT_SCENE_PATH := "res://scenes/main/Main.tscn"

@onready var panel_image: TextureRect = $PanelImage
@onready var caption_label: RichTextLabel = $CaptionBar/CaptionLabel
@onready var skip_button: Button = $SkipButton

var panels: Array = []
var current_index := 0
var _advance_timer: Timer

func _ready() -> void:
	panels = _load_panels()
	skip_button.pressed.connect(_on_skip_pressed)
	_advance_timer = Timer.new()
	_advance_timer.one_shot = true
	_advance_timer.timeout.connect(_advance)
	add_child(_advance_timer)
	if panels.is_empty():
		return
	_show_panel(0)

func _load_panels() -> Array:
	if not FileAccess.file_exists(CUTSCENE_CONTENT_PATH):
		return []
	var file := FileAccess.open(CUTSCENE_CONTENT_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

static func compute_panel_duration_seconds(caption: String) -> float:
	var word_count := caption.split(" ", false).size()
	var estimated := (word_count / WORDS_PER_MINUTE) * 60.0
	return clamp(estimated, MINIMUM_PANEL_SECONDS, MAXIMUM_PANEL_SECONDS)

func _show_panel(index: int) -> void:
	current_index = index
	_display_panel_data(panels[index])

func _display_panel_data(panel: Dictionary) -> void:
	var image := Image.load_from_file(panel["image_path"])
	if image == null:
		panel_image.texture = null
	else:
		panel_image.texture = ImageTexture.create_from_image(image)
	caption_label.text = panel["caption"]
	_advance_timer.start(compute_panel_duration_seconds(panel["caption"]))

func _advance() -> void:
	if current_index + 1 >= panels.size():
		_finish()
		return
	_fade_to_panel(current_index + 1)

func _fade_to_panel(index: int) -> void:
	var tween := create_tween()
	tween.tween_property(panel_image, "modulate:a", 0.0, FADE_DURATION_SECONDS)
	tween.tween_callback(_show_panel.bind(index))
	tween.tween_property(panel_image, "modulate:a", 1.0, FADE_DURATION_SECONDS)

func _on_skip_pressed() -> void:
	_finish()

func _finish() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
```

- [ ] **Step 2: Build `PrologueCutscene.tscn`**

Build a scene with this exact node tree (use the Godot editor or hand-author the `.tscn`, then verify it opens/runs with no parse errors before moving on):

- `Control` (root) — script: `PrologueCutscene.gd`; full-rect anchors (`anchor_right = 1`, `anchor_bottom = 1`)
  - `ColorRect` named `Backdrop` — full-rect anchors, `color = Color(0, 0, 0, 1)` (solid black)
  - `TextureRect` named `PanelImage` — full-rect anchors, `expand_mode = 1` (`EXPAND_IGNORE_SIZE`), `stretch_mode = 5` (`STRETCH_KEEP_ASPECT_CENTERED` — confirmed via a live Godot query against this exact 4.3 build, not guessed)
  - `ColorRect` named `CaptionBar` — anchored to the bottom ~18% of the screen (`anchor_top = 0.82`, `anchor_left = 0`, `anchor_right = 1`, `anchor_bottom = 1`), `color = Color(0, 0, 0, 0.72)` (semi-transparent black)
    - `RichTextLabel` named `CaptionLabel` — full-rect anchors within `CaptionBar`, `bbcode_enabled = false`, `horizontal_alignment = 1` (`HORIZONTAL_ALIGNMENT_CENTER`), `vertical_alignment = 1` (`VERTICAL_ALIGNMENT_CENTER`), some inset margin (e.g. `offset_left = 40`, `offset_right = -40`) so text doesn't touch the screen edges
  - `Button` named `SkipButton` — anchored top-right (e.g. `anchor_left = 1`, `anchor_top = 0`, `offset_left = -124`, `offset_top = 24`, `offset_right = -24`, `offset_bottom = 64`), `text = "Skip"`

Do not set an explicit theme override anywhere in this scene — it inherits `BorrowedFortuneTheme` project-wide via `project.godot`'s `[gui] theme/custom`, same as every other UI element in the game, for free.

- [ ] **Step 3: Write the pure-logic tests**

Create `tests/unit/test_prologue_cutscene.gd`:

```gdscript
extends GutTest

const PrologueCutsceneScript := preload("res://scenes/prologue_cutscene/PrologueCutscene.gd")
const PrologueCutsceneScene := preload("res://scenes/prologue_cutscene/PrologueCutscene.tscn")

func test_compute_panel_duration_seconds_clamps_short_captions_to_the_minimum():
	var short_caption := "Word word word."
	assert_almost_eq(PrologueCutsceneScript.compute_panel_duration_seconds(short_caption), 4.0, 0.0001)

func test_compute_panel_duration_seconds_clamps_long_captions_to_the_maximum():
	var words: Array[String] = []
	for i in range(50):
		words.append("word")
	var long_caption := " ".join(words)
	assert_almost_eq(PrologueCutsceneScript.compute_panel_duration_seconds(long_caption), 12.0, 0.0001)

func test_compute_panel_duration_seconds_scales_with_word_count_in_between():
	var words: Array[String] = []
	for i in range(24):
		words.append("word")
	var mid_caption := " ".join(words)
	assert_almost_eq(PrologueCutsceneScript.compute_panel_duration_seconds(mid_caption), 8.0, 0.0001)

func test_displaying_panel_data_sets_the_caption_and_starts_the_advance_timer():
	var cutscene = add_child_autofree(PrologueCutsceneScene.instantiate())
	var words: Array[String] = []
	for i in range(12):
		words.append("word")
	var caption := " ".join(words)
	cutscene._display_panel_data({"image_path": "res://this_fixture_path_does_not_need_to_exist.png", "caption": caption})
	assert_eq(cutscene.caption_label.text, caption)
	assert_almost_eq(cutscene._advance_timer.wait_time, 4.0, 0.0001)
```

Note the last test's fixture image path is deliberately nonexistent — `_display_panel_data()` is written to handle a missing/unloadable image gracefully (matching `ChapterView._update_background()`'s own established null-safety), so this test needs no real art file and passes with `panel_image.texture` left `null`.

- [ ] **Step 4: Run the test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_prologue_cutscene.gd -gexit
```

Expected: all 4 tests pass, 0 failures. (Do not run the full suite for this task — that happens after Task 2.)

- [ ] **Step 5: Commit**

```bash
git add scenes/prologue_cutscene/ tests/unit/test_prologue_cutscene.gd
git commit -m "feat: add the PrologueCutscene scene and its panel-timing logic"
```

---

### Task 2: Content, art, and wiring

**Files:**
- Create: `content/cutscenes/prologue_intro.json`
- Create: `tools/pixellab/generate_cutscene_panels.py`
- Create: `tools/pixellab/cutscene_panels.json`
- Create: `assets/cutscenes/prologue_intro_01.png` … `_11.png`
- Modify: `scenes/main_menu/MainMenu.gd`
- Modify: `tests/unit/test_prologue_cutscene.gd`

**Interfaces:**
- Consumes: `PrologueCutscene`'s `_load_panels()`/`_ready()` behavior from Task 1 — this task supplies the file it reads.

- [ ] **Step 1: Write the real content file**

Create `content/cutscenes/prologue_intro.json` with exactly these 11 entries, in order (image filenames match Step 3 below):

```json
[
	{"image_path": "res://assets/cutscenes/prologue_intro_01.png", "caption": "By the year 1035, Ghazni was the seat of an empire built, in a single generation, on the conquests of one king - a capital whose wealth had outgrown the mountains that once made it obscure."},
	{"image_path": "res://assets/cutscenes/prologue_intro_02.png", "caption": "Its roads reached further than any single army could hold them: Turkic soldiers, Persian clerks, Arab law, and merchants who spoke whichever tongue paid best that season."},
	{"image_path": "res://assets/cutscenes/prologue_intro_03.png", "caption": "Five years before, the throne had passed from father to son by force rather than by the old king's own wish - a settled matter by now, but not a forgotten one."},
	{"image_path": "res://assets/cutscenes/prologue_intro_04.png", "caption": "Along the frontier provinces, further from the capital's wealth than any map cared to show, the empire's grip had already begun to loosen, one small season at a time."},
	{"image_path": "res://assets/cutscenes/prologue_intro_05.png", "caption": "In Ghazni itself, ordinary life went on the way it always had - a shopfront, a ledger, a merchant's son who did not yet know how much of either he would inherit."},
	{"image_path": "res://assets/cutscenes/prologue_intro_06.png", "caption": "The merchant kept accounts like any other man of his trade. Not every paper in that ledger, though, was the kind a man showed his own clerk without being asked twice."},
	{"image_path": "res://assets/cutscenes/prologue_intro_07.png", "caption": "Further west, along the Khorasan road, Turkmen horsemen had been testing the frontier's patience for longer than anyone in Ghazni had thought worth mentioning."},
	{"image_path": "res://assets/cutscenes/prologue_intro_08.png", "caption": "It did not stay a testing for long. A garrison caught short, a stretch of road left unguarded for one afternoon too many - and men who had never worn a uniform rode off with whatever the wagons had been carrying."},
	{"image_path": "res://assets/cutscenes/prologue_intro_09.png", "caption": "Word of it moved the way word always did out here - caravan to caravan, faster than any courier the Sultan himself employed, arriving everywhere at once and nowhere official."},
	{"image_path": "res://assets/cutscenes/prologue_intro_10.png", "caption": "None of it had reached Ghazni yet. The city closed its shops at the same hour it always did, unaware that a season was about to turn."},
	{"image_path": "res://assets/cutscenes/prologue_intro_11.png", "caption": "In a shopfront no grander than any other on its street, a merchant's cough had just begun to worsen."}
]
```

- [ ] **Step 2: Add the real-content structure test**

Add this new test function to `tests/unit/test_prologue_cutscene.gd`:

```gdscript
func test_prologue_intro_content_has_eleven_panels_each_with_a_caption_and_image_path():
	var file := FileAccess.open("res://content/cutscenes/prologue_intro.json", FileAccess.READ)
	var panels = JSON.parse_string(file.get_as_text())
	file.close()
	assert_eq(panels.size(), 11)
	for i in range(panels.size()):
		var panel: Dictionary = panels[i]
		assert_true(panel.get("caption", "").length() > 0, "panel %d must have a non-empty caption" % i)
		assert_eq(panel.get("image_path", ""), "res://assets/cutscenes/prologue_intro_%02d.png" % (i + 1))
```

- [ ] **Step 3: Write the pixellab generation config and script**

Create `tools/pixellab/cutscene_panels.json`:

```json
[
	{"output": "prologue_intro_01.png", "description": "a grand Ghaznavid capital skyline at dawn, minarets and mudbrick towers rising from a fortified hill city, wide establishing view"},
	{"output": "prologue_intro_02.png", "description": "a busy caravan road stretching to the horizon, merchants and pack animals of many peoples, mountains in the distance"},
	{"output": "prologue_intro_03.png", "description": "an imperial palace courtyard, empty throne dais visible through an archway, guards standing at a respectful distance"},
	{"output": "prologue_intro_04.png", "description": "a remote frontier watchtower on a dusty ridge, a thinned patrol passing below, the land beyond looking unwatched"},
	{"output": "prologue_intro_05.png", "description": "a modest merchant's shopfront in a capital bazaar, awnings and stacked goods, ordinary daily commerce"},
	{"output": "prologue_intro_06.png", "description": "a merchant's hand closing a ledger book on a wooden counter, a lamp burning low, a folded paper tucked half-hidden beneath it"},
	{"output": "prologue_intro_07.png", "description": "Turkmen horsemen gathering on an open steppe at dusk, a line of riders silhouetted against the sky"},
	{"output": "prologue_intro_08.png", "description": "a chaotic skirmish at a frontier garrison wall, soldiers fighting in disarray, horsemen riding off in the background with sacks and bundles of plunder"},
	{"output": "prologue_intro_09.png", "description": "a caravan crossing open desert at speed, a lone rider peeling off from the group toward the horizon"},
	{"output": "prologue_intro_10.png", "description": "a capital city street at dusk, shops closing their shutters, lamplight beginning to show in windows, ordinary and calm"},
	{"output": "prologue_intro_11.png", "description": "a quiet merchant's shopfront interior at evening, a single lamp lit, an empty stool beside a stacked ledger"}
]
```

Create `tools/pixellab/generate_cutscene_panels.py`, following `tools/pixellab/generate_backgrounds.py`'s exact existing structure and imports (same `pixflux_client` module, same `.env`-loading `Client.from_env_file(".env")` pattern, same `compute_seed()` per-subject seeding, same output directory pattern but targeting `assets/cutscenes/` instead of `assets/backgrounds/`). Read `cutscene_panels.json`, and for each entry call `generate_pixflux()` with:
- `width=400, height=168` (the proven `menu_banner_short` dimensions — do not use the existing 320x180 background size for this asset)
- `outline="single color black outline"`, `shading="flat shading"` (reused verbatim from `generate_backgrounds.py` — same manuscript-miniature look as every other background)
- `detail="highly detailed"` (matching the current post-quality-upgrade baseline for all other art in the game, not the older `"low detail"` originally used for backgrounds)
- no `no_background` flag (these are full opaque scene images, not transparent-background UI assets — unlike the portrait/UI-asset pipelines)

Save each output to `assets/cutscenes/<output>`.

- [ ] **Step 4: Run the generation script and verify the real output**

```bash
source .venv-pixellab/bin/activate
python tools/pixellab/generate_cutscene_panels.py
```

Confirm all 11 files land in `assets/cutscenes/` at 400x168, and spot-check at least 2-3 of them by eye (open the PNGs directly) for the described content and the same manuscript-miniature look as the existing backgrounds — matching this project's own established practice of a real, human-verified generation pass rather than trusting the script's exit code alone.

- [ ] **Step 5: Wire `MainMenu`'s "New Game" button to the new scene**

In `scenes/main_menu/MainMenu.gd`, find `_on_new_game_pressed()`:

```gdscript
func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
```

Change only the final line's target scene:

```gdscript
func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	get_tree().change_scene_to_file("res://scenes/prologue_cutscene/PrologueCutscene.tscn")
```

Do not change `_on_continue_pressed()` — it must keep going straight to `Main.tscn`, skipping the cutscene, since resuming a save should never replay the intro. This project has no existing test asserting `_on_new_game_pressed()`'s exact navigation target (confirmed by reading `tests/unit/test_main_menu.gd` — it only tests button enabled/disabled state, never click-through navigation), so no test needs updating for this specific change; verify it live in Step 6 instead.

- [ ] **Step 6: Live verification**

Run the actual game (`godot --path . scenes/main_menu/MainMenu.tscn` or the project's own `run` pattern if one exists) and click "New Game." Confirm: the cutscene plays, panels advance automatically with a visible fade between them, the letterbox bars are visible top and bottom, the caption text is legible over the `CaptionBar`, the Skip button is visible and clickable from any panel, and skipping (or letting all 11 panels play out) lands on the interactive Prologue (`chapter_00_prologue`) via `Main.tscn`. Take a screenshot of at least one panel mid-playback as evidence, using this project's established `xprop`-based screenshot technique if a live X session is available.

- [ ] **Step 7: Run the affected test file, then the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_prologue_cutscene.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: `test_prologue_cutscene.gd` shows all 5 tests passing (4 from Task 1 + 1 new from Step 2). Full suite: 310 tests total (305 baseline + 4 from Task 1 + 1 from Task 2), 309 passing + the 1 pre-existing risky test. If your actual count differs, stop and report the real number rather than assuming this arithmetic is right.

- [ ] **Step 8: Commit**

```bash
git add content/cutscenes/ tools/pixellab/generate_cutscene_panels.py tools/pixellab/cutscene_panels.json assets/cutscenes/ scenes/main_menu/MainMenu.gd tests/unit/test_prologue_cutscene.gd
git commit -m "feat: add the Prologue cold-open cutscene content, art, and menu wiring"
```

---

## Self-Review

**Spec coverage:** the 11-panel content (image descriptions + captions) → Task 2 Steps 1 and 3, verbatim from the spec. The scene/logic architecture (duration formula, fade tween, skip, letterbox stretch mode) → Task 1 Steps 1-2, verbatim from the spec's code block and node-tree description. The art pipeline (400x168, style reuse, detail level) → Task 2 Step 3. The `MainMenu` wiring change → Task 2 Step 5. The GUT-vs-live testing split the spec calls for → Task 1 Step 3 (pure logic) and Task 2 Steps 4/6 (art/live verification). ✓ Nothing else in the spec requires a task.

**Placeholder scan:** none — every panel's real caption and image description is written out in full in both tasks, not summarized.

**Type/signature consistency:** `compute_panel_duration_seconds(caption: String) -> float` and `_display_panel_data(panel: Dictionary) -> void` are defined in Task 1 Step 1 and used identically in Task 1 Step 3's tests; the `image_path`/`caption` dictionary keys match exactly between the GDScript, the real content JSON (Task 2 Step 1), and the structure test (Task 2 Step 2).

**Task granularity check:** two tasks, split because Task 1's engine/UI correctness (does the timer duration compute right, does a panel render right) is independently reviewable from Task 2's content/art correctness (do the captions read well, does the generated art match the description) — and Task 2 cannot start until Task 1's exact file paths and method signatures exist to depend on. A fresh reviewer could approve Task 1's logic while still having concerns about Task 2's prose or art, or vice versa.
