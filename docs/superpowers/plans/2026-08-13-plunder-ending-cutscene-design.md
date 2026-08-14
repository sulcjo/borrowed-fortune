# Plunder Ending Cutscene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generalize the Prologue's cutscene engine into a reusable component, wire a new manifest-driven "play a cutscene after a true ending" mechanism, and use both to add a dark, atmospheric coda after Chapter 5's plunder ending, per `docs/superpowers/specs/2026-08-13-plunder-ending-cutscene-design.md`.

**Architecture:** Task 1 does the engine work — extracts `Cutscene.gd` from `PrologueCutscene.gd` (two hardcoded consts become `@export` vars, everything else byte-identical), re-points the existing `PrologueCutscene.tscn` at it with zero behavior change, adds the new `post_ending_cutscene_path` manifest field and its `ChapterView` wiring, and splits/relocates the existing test file to match. All of Task 1 is testable without any new art or content. Task 2 depends on Task 1's exact export-variable names and file layout, and adds the real content, art, `EndingCutscene.tscn`, the manifest wiring for Chapter 5, and live verification.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless), Python (pixellab tooling).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **314 tests, 313 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this plan: **316** (2 new tests; the existing 5 cutscene tests are only relocated, not duplicated or removed), 315 passing + the same 1 pre-existing risky test.
- **The Prologue cutscene's behavior must not change at all.** `PrologueCutscene.tscn` keeps its exact existing file path (referenced by `MainMenu.gd` and by name in tests) — only its attached script and two new export values change, and those export values must exactly reproduce the old hardcoded consts (`res://content/cutscenes/prologue_intro.json` / `res://scenes/main/Main.tscn`).
- Chapter 5's own dialogue content (`content/chapters/chapter_05_plunder_ending/plunder_ending.json`) is not touched anywhere in this plan — 0 nodes added, 0 nodes modified.
- No sound/music anywhere in this pass — this game has no audio system, and both cutscenes stay silent.
- No branching by which of Chapter 5's 4 terminal variants was reached — one shared ending cutscene for all of them.
- No new plot event or confirmed outcome in the new cutscene's content — tonal/atmospheric only, per the spec.
- Every raw pixellab-generated PNG is loaded via `Image.load_from_file(path)` wrapped in `ImageTexture.create_from_image(image)` — never `load()`/`preload()` on the PNG itself.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b plunder-ending-cutscene .worktrees/plunder-ending-cutscene master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.
- The pixellab pipeline needs the existing `.venv-pixellab` venv and `.env` (both already present in the repo, gitignored) — do not create new ones.

---

## File Structure

| File | Purpose |
|---|---|
| `scenes/cutscene/Cutscene.gd` | Create (Task 1) — the generic, reusable cutscene logic |
| `scenes/prologue_cutscene/PrologueCutscene.gd` | Delete (Task 1) — logic moved to `Cutscene.gd` |
| `scenes/prologue_cutscene/PrologueCutscene.tscn` | Modify (Task 1) — re-point script, set export values |
| `scenes/chapter_view/ChapterView.gd` | Modify (Task 1) — new `post_ending_cutscene_path` field + wiring |
| `content/chapters/manifest.json` | Modify (Task 2) — add `post_ending_cutscene_path` to `chapter_05_plunder_ending` |
| `tests/fixtures/manifest_fixture.json` | Modify (Task 1) — add a fixture entry with the new field |
| `tests/unit/test_prologue_cutscene.gd` | Delete (Task 1) — split into the two files below |
| `tests/unit/test_cutscene.gd` | Create (Task 1) — the 4 generic logic tests, relocated |
| `tests/unit/test_prologue_intro_content.gd` | Create (Task 1) — the Prologue content-structure test, relocated |
| `tests/unit/test_chapter_view.gd` | Modify (Task 1) — new fixture-based manifest-field test |
| `content/cutscenes/plunder_ending_outro.json` | Create (Task 2) — the real 6 panels |
| `tools/pixellab/generate_cutscene_panels.py` | Modify (Task 2) — add `--config`/`--output-dir` CLI args |
| `tools/pixellab/plunder_ending_cutscene_panels.json` | Create (Task 2) — the 6 image descriptions |
| `assets/cutscenes/plunder_ending_outro_01.png` … `_06.png` | Create (Task 2) — the generated art |
| `scenes/ending_cutscene/EndingCutscene.tscn` | Create (Task 2) — the new cutscene scene instance |
| `tests/unit/test_plunder_ending_cutscene_content.gd` | Create (Task 2) — the new content-structure test |

---

### Task 1: Generalize the cutscene engine and wire the post-ending trigger

**Files:**
- Create: `scenes/cutscene/Cutscene.gd`
- Delete: `scenes/prologue_cutscene/PrologueCutscene.gd`
- Modify: `scenes/prologue_cutscene/PrologueCutscene.tscn`
- Modify: `scenes/chapter_view/ChapterView.gd`
- Modify: `tests/fixtures/manifest_fixture.json`
- Delete: `tests/unit/test_prologue_cutscene.gd`
- Create: `tests/unit/test_cutscene.gd`
- Create: `tests/unit/test_prologue_intro_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Produces: `Cutscene.gd`'s `@export var content_path: String` / `@export var next_scene_path: String`, and `ChapterView`'s new `post_ending_cutscene_path` instance variable. Task 2 depends on both — it sets the exports on the new `EndingCutscene.tscn` and relies on `ChapterView` reading `post_ending_cutscene_path` from the manifest.

- [ ] **Step 1: Create the generic `Cutscene.gd`**

Create `scenes/cutscene/Cutscene.gd` with exactly this content (this is `PrologueCutscene.gd`'s existing logic, with the two hardcoded consts converted to exported variables — everything else is byte-identical):

```gdscript
extends Control

const WORDS_PER_MINUTE := 180.0
const MINIMUM_PANEL_SECONDS := 4.0
const MAXIMUM_PANEL_SECONDS := 12.0
const FADE_DURATION_SECONDS := 0.6

@export var content_path: String = ""
@export var next_scene_path: String = ""

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
	if not FileAccess.file_exists(content_path):
		return []
	var file := FileAccess.open(content_path, FileAccess.READ)
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
	caption_label.text = "[center]%s[/center]" % panel["caption"]
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
	get_tree().change_scene_to_file(next_scene_path)
```

- [ ] **Step 2: Re-point `PrologueCutscene.tscn` at the new script and set its export values**

In `scenes/prologue_cutscene/PrologueCutscene.tscn`, find the `[ext_resource type="Script" path="res://scenes/prologue_cutscene/PrologueCutscene.gd" id="1"]` line and change the path to `res://scenes/cutscene/Cutscene.gd`.

In the root `[node name="PrologueCutscene" type="Control"]` block, add two new lines after `script = ExtResource("1")`:

```
content_path = "res://content/cutscenes/prologue_intro.json"
next_scene_path = "res://scenes/main/Main.tscn"
```

Do not change anything else in this file — the `Backdrop`, `PanelImage`, `CaptionBar`/`CaptionLabel`, and `SkipButton` nodes stay exactly as they are.

Delete `scenes/prologue_cutscene/PrologueCutscene.gd` — its logic now lives in `Cutscene.gd`.

- [ ] **Step 3: Add the `post_ending_cutscene_path` field to `ChapterView`**

In `scenes/chapter_view/ChapterView.gd`, add a new instance variable near the existing `next_chapter_id`/`farrukh_wear_stage` declarations:

```gdscript
var post_ending_cutscene_path = null
```

In `load_chapter_by_id()`, find:

```gdscript
	next_chapter_id = entry.get("next_chapter_id", null)
```

and add immediately after it:

```gdscript
	post_ending_cutscene_path = entry.get("post_ending_cutscene_path", null)
```

In `_save_and_finish()`, find:

```gdscript
	if resolved_next_chapter_id == null:
		return
```

and change it to:

```gdscript
	if resolved_next_chapter_id == null:
		if post_ending_cutscene_path != null:
			get_tree().change_scene_to_file(post_ending_cutscene_path)
		return
```

Do not change anything else in `_save_and_finish()` — the auto-transition-chain logic below this block is untouched.

- [ ] **Step 4: Add a fixture entry for the new field**

In `tests/fixtures/manifest_fixture.json`, add a new entry (reusing the already-existing `dialogue_fixture_b.json`, the same terminal dialogue fixture `fixture_chapter_b` already uses):

```json
"fixture_chapter_with_post_ending_cutscene": {
	"dialogue_path": "res://tests/fixtures/dialogue_fixture_b.json",
	"glossary_path": "res://tests/fixtures/glossary_fixture_a.json",
	"next_chapter_id": null,
	"post_ending_cutscene_path": "res://tests/fixtures/does_not_need_to_exist.tscn"
}
```

Match the file's existing formatting/indentation style.

- [ ] **Step 5: Add the new manifest-field test**

Add this new test function to `tests/unit/test_chapter_view.gd` (place it after `test_a_terminal_node_without_its_own_next_chapter_id_falls_back_to_the_manifest()`):

```gdscript
func test_post_ending_cutscene_path_is_read_from_the_manifest():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_with_post_ending_cutscene", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.post_ending_cutscene_path, "res://tests/fixtures/does_not_need_to_exist.tscn")
```

This tests the field-reading only, not the actual scene transition (this project has no precedent for unit-testing a real `change_scene_to_file()` call — the transition itself is verified live in Task 2).

- [ ] **Step 6: Split the existing cutscene test file**

Delete `tests/unit/test_prologue_cutscene.gd`. Create `tests/unit/test_cutscene.gd` with the 4 generic-logic tests, updated to reference the new script path (the instantiated scene stays `PrologueCutscene.tscn` — a real, valid instance of the now-generic logic, so no new fixture scene is needed just for these tests):

```gdscript
extends GutTest

const CutsceneScript := preload("res://scenes/cutscene/Cutscene.gd")
const PrologueCutsceneScene := preload("res://scenes/prologue_cutscene/PrologueCutscene.tscn")

func test_compute_panel_duration_seconds_clamps_short_captions_to_the_minimum():
	var short_caption := "Word word word."
	assert_almost_eq(CutsceneScript.compute_panel_duration_seconds(short_caption), 4.0, 0.0001)

func test_compute_panel_duration_seconds_clamps_long_captions_to_the_maximum():
	var words: Array[String] = []
	for i in range(50):
		words.append("word")
	var long_caption := " ".join(words)
	assert_almost_eq(CutsceneScript.compute_panel_duration_seconds(long_caption), 12.0, 0.0001)

func test_compute_panel_duration_seconds_scales_with_word_count_in_between():
	var words: Array[String] = []
	for i in range(24):
		words.append("word")
	var mid_caption := " ".join(words)
	assert_almost_eq(CutsceneScript.compute_panel_duration_seconds(mid_caption), 8.0, 0.0001)

func test_displaying_panel_data_sets_the_caption_and_starts_the_advance_timer():
	var cutscene = add_child_autofree(PrologueCutsceneScene.instantiate())
	var words: Array[String] = []
	for i in range(12):
		words.append("word")
	var caption := " ".join(words)
	cutscene._display_panel_data({"image_path": "res://this_fixture_path_does_not_need_to_exist.png", "caption": caption})
	assert_eq(cutscene.caption_label.get_parsed_text(), caption)
	assert_almost_eq(cutscene._advance_timer.wait_time, 4.0, 0.0001)
```

Create `tests/unit/test_prologue_intro_content.gd` with the relocated content-structure test:

```gdscript
extends GutTest

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

- [ ] **Step 7: Run the affected test files**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_cutscene.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_prologue_intro_content.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_chapter_view.gd -gexit
```

Expected: all tests pass, 0 failures. Also run the full suite once here to confirm the refactor introduced no regressions before Task 2 begins:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 315 tests total (314 baseline + 1 new manifest-field test; the other relocated tests net to zero), 314 passing + the 1 pre-existing risky test.

- [ ] **Step 8: Live-verify the Prologue cutscene is unaffected**

Run the game, press "New Game," confirm the Prologue cutscene still plays exactly as before (letterbox, auto-advance, fade, Skip button, lands on the interactive Prologue) — this refactor must be invisible to the player. This is a quick spot-check, not a full re-verification.

- [ ] **Step 9: Commit**

```bash
git add scenes/cutscene/ scenes/prologue_cutscene/ scenes/chapter_view/ChapterView.gd tests/fixtures/manifest_fixture.json tests/unit/test_cutscene.gd tests/unit/test_prologue_intro_content.gd tests/unit/test_chapter_view.gd
git rm tests/unit/test_prologue_cutscene.gd
git commit -m "refactor: generalize the cutscene scene and add a post-ending-cutscene manifest hook"
```

---

### Task 2: Content, art, and the new ending scene

**Files:**
- Create: `content/cutscenes/plunder_ending_outro.json`
- Modify: `tools/pixellab/generate_cutscene_panels.py`
- Create: `tools/pixellab/plunder_ending_cutscene_panels.json`
- Create: `assets/cutscenes/plunder_ending_outro_01.png` … `_06.png`
- Create: `scenes/ending_cutscene/EndingCutscene.tscn`
- Modify: `content/chapters/manifest.json`
- Create: `tests/unit/test_plunder_ending_cutscene_content.gd`

**Interfaces:**
- Consumes: `Cutscene.gd`'s `content_path`/`next_scene_path` exports and `ChapterView`'s `post_ending_cutscene_path` manifest field, both from Task 1.

- [ ] **Step 1: Write the real content file**

Create `content/cutscenes/plunder_ending_outro.json` with exactly these 6 entries, in order:

```json
[
	{"image_path": "res://assets/cutscenes/plunder_ending_outro_01.png", "caption": "The company thinned first. Then the light."},
	{"image_path": "res://assets/cutscenes/plunder_ending_outro_02.png", "caption": "A fire that answered to no one but himself."},
	{"image_path": "res://assets/cutscenes/plunder_ending_outro_03.png", "caption": "He watched his own hands the way he'd once watched a stranger's."},
	{"image_path": "res://assets/cutscenes/plunder_ending_outro_04.png", "caption": "Nothing followed. He no longer trusted the difference."},
	{"image_path": "res://assets/cutscenes/plunder_ending_outro_05.png", "caption": "The sky kept its own accounting, indifferent to his."},
	{"image_path": "res://assets/cutscenes/plunder_ending_outro_06.png", "caption": "Some men, walking, arrive as strangers to themselves before they arrive anywhere else."}
]
```

- [ ] **Step 2: Add the content-structure test**

Create `tests/unit/test_plunder_ending_cutscene_content.gd`:

```gdscript
extends GutTest

func test_plunder_ending_outro_has_six_panels_each_with_a_caption_and_image_path():
	var file := FileAccess.open("res://content/cutscenes/plunder_ending_outro.json", FileAccess.READ)
	var panels = JSON.parse_string(file.get_as_text())
	file.close()
	assert_eq(panels.size(), 6)
	for i in range(panels.size()):
		var panel: Dictionary = panels[i]
		assert_true(panel.get("caption", "").length() > 0, "panel %d must have a non-empty caption" % i)
		assert_eq(panel.get("image_path", ""), "res://assets/cutscenes/plunder_ending_outro_%02d.png" % (i + 1))
```

- [ ] **Step 3: Generalize the generation script and write the new panel config**

In `tools/pixellab/generate_cutscene_panels.py`, add `--config` and `--output-dir` CLI arguments defaulting to the Prologue's existing values (`PANELS_PATH`/`CUTSCENES_DIR`), so the existing bare invocation (`python tools/pixellab/generate_cutscene_panels.py`, no args) keeps working exactly as it does today. Read the script first to see its exact current `argparse` setup (it already has a `--force` argument) and add the two new ones consistently with that style — e.g.:

```python
parser.add_argument("--config", type=Path, default=PANELS_PATH, help="path to the panel-config JSON (default: this cutscene's own cutscene_panels.json)")
parser.add_argument("--output-dir", type=Path, default=CUTSCENES_DIR, help="directory to write generated PNGs into (default: assets/cutscenes)")
```

Thread `args.config` and `args.output_dir` through to `load_panels()` and `run()` in place of the hardcoded `PANELS_PATH`/`CUTSCENES_DIR` defaults (both functions already accept these as parameters with those same defaults — just pass the parsed args through instead of relying on the defaults implicitly).

Create `tools/pixellab/plunder_ending_cutscene_panels.json`:

```json
[
	{"output": "plunder_ending_outro_01.png", "description": "the road west at full dusk, empty, no caravan, a single traveler walking alone into fading light"},
	{"output": "plunder_ending_outro_02.png", "description": "a single small campfire against a vast dark landscape at night, no other travelers visible"},
	{"output": "plunder_ending_outro_03.png", "description": "a close view of a pair of hands by firelight, turning a coin over slowly"},
	{"output": "plunder_ending_outro_04.png", "description": "an empty desert road behind a traveler at dusk, long shadows, something ambiguous at the edge of visibility"},
	{"output": "plunder_ending_outro_05.png", "description": "a vast star-filled night sky over an empty desert road, no moon"},
	{"output": "plunder_ending_outro_06.png", "description": "a lone traveler's long, distorted shadow stretching ahead on a moonlit road"}
]
```

- [ ] **Step 4: Run the generation script and verify the real output**

```bash
source .venv-pixellab/bin/activate
python tools/pixellab/generate_cutscene_panels.py --config tools/pixellab/plunder_ending_cutscene_panels.json
```

Confirm all 6 files land in `assets/cutscenes/` at 400x168, and spot-check at least 2-3 by eye for the described content, a visibly darker/night-time mood than the Prologue's panels, and the same manuscript-miniature art style as the rest of the game's art.

- [ ] **Step 5: Create `EndingCutscene.tscn`**

Create `scenes/ending_cutscene/EndingCutscene.tscn` with the same node tree as `PrologueCutscene.tscn` (root `Control` named `EndingCutscene` with `Cutscene.gd` attached, `Backdrop`/`PanelImage`/`CaptionBar`→`CaptionLabel`/`SkipButton` children, identical anchors/properties to `PrologueCutscene.tscn`), but with:

```
content_path = "res://content/cutscenes/plunder_ending_outro.json"
next_scene_path = "res://scenes/main_menu/MainMenu.tscn"
```

The simplest reliable way to build this correctly: copy `scenes/prologue_cutscene/PrologueCutscene.tscn`'s full contents into the new file, rename the root node from `PrologueCutscene` to `EndingCutscene`, and change only the two export values as shown above. Verify it opens/parses with no errors before moving on.

- [ ] **Step 6: Wire Chapter 5's manifest entry**

In `content/chapters/manifest.json`, find `chapter_05_plunder_ending`'s entry:

```json
"chapter_05_plunder_ending": {
	"dialogue_path": "res://content/chapters/chapter_05_plunder_ending/plunder_ending.json",
	"glossary_path": "res://content/glossary/plunder_ending_terms.json",
	"next_chapter_id": null,
	"farrukh_wear_stage": 3
}
```

Add one new key:

```json
"chapter_05_plunder_ending": {
	"dialogue_path": "res://content/chapters/chapter_05_plunder_ending/plunder_ending.json",
	"glossary_path": "res://content/glossary/plunder_ending_terms.json",
	"next_chapter_id": null,
	"farrukh_wear_stage": 3,
	"post_ending_cutscene_path": "res://scenes/ending_cutscene/EndingCutscene.tscn"
}
```

Do not change any other manifest entry.

- [ ] **Step 7: Live verification**

Run the game and reach any of Chapter 5's 4 terminal endings — the fastest path is to load `chapter_05_plunder_ending` directly (e.g. via a temporary debug call, or by playing through from a save) and press through to any terminal node. Confirm: the new dark cutscene plays immediately afterward with visible letterbox bars, its own 6 panels and captions in sequence, a working Skip button, and lands on the main menu (`MainMenu.tscn`) when finished or skipped. Take at least one screenshot as evidence, using this project's established `xprop`-based screenshot technique (`DISPLAY=:0 xprop -root _NET_CLIENT_LIST` → find the Godot window by `WM_CLASS` → `import -window <id>`).

- [ ] **Step 8: Run the affected test files, then the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_plunder_ending_cutscene_content.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected full-suite baseline per the plan: 316 tests total (315 after Task 1 + 1 new from this task), 315 passing + 1 pre-existing unrelated "risky" zero-assertion test (not a failure). If your actual count differs, report the real number rather than assuming this arithmetic is right.

- [ ] **Step 9: Commit**

```bash
git add content/cutscenes/ tools/pixellab/generate_cutscene_panels.py tools/pixellab/plunder_ending_cutscene_panels.json assets/cutscenes/ scenes/ending_cutscene/ content/chapters/manifest.json tests/unit/test_plunder_ending_cutscene_content.gd
git commit -m "feat: add the plunder-ending cutscene content, art, and manifest wiring"
```

---

## Self-Review

**Spec coverage:** the `Cutscene.gd` extraction and `PrologueCutscene.tscn` re-pointing, with zero behavior change → Task 1 Steps 1-2, verbatim from the spec. The new `post_ending_cutscene_path` manifest field and its `ChapterView` wiring → Task 1 Step 3. The test-file split (relocate, don't duplicate) → Task 1 Steps 4-6. The 6-panel content and art pipeline generalization → Task 2 Steps 1-4. The new `EndingCutscene.tscn` and manifest wiring → Task 2 Steps 5-6. The GUT-vs-live testing split → Task 1 Step 8 (spot-check) and Task 2 Step 7 (full live verification). ✓ Nothing else in the spec requires a task.

**Placeholder scan:** none — every panel's real caption and image description is written out in full.

**Type/signature consistency:** `content_path`/`next_scene_path` are defined identically in `Cutscene.gd` (Task 1) and consumed identically by both `.tscn` files (`PrologueCutscene.tscn` in Task 1, `EndingCutscene.tscn` in Task 2). `post_ending_cutscene_path` is defined in `ChapterView.gd` (Task 1), tested via a fixture (Task 1), and set for real in the manifest (Task 2) — the key name matches exactly in all three places.

**Task granularity check:** two tasks, split because Task 1's refactor correctness (does the Prologue cutscene still work identically, does the new manifest field get read correctly) is independently reviewable from Task 2's content/art correctness (do the new captions read well, does the generated art match the darker mood) — and Task 2 cannot start until Task 1's exact export-variable names and file layout exist to depend on. This mirrors the engine-then-content split used for Nishapur's debt mechanic and this same session's Prologue cutscene work.
