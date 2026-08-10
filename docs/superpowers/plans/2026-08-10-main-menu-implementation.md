# Main Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a New Game / Continue / Quit entry point, with a real, working Continue built on a small addition to the save mechanism that already exists but has never been read back.

**Architecture:** Two tasks, and - unlike this session's two prior pixellab-art-pass plans - genuinely sequential, not independent. Task 1 adds the save-pointer mechanism (`ChapterView._write_current_chapter_pointer()`, `Main._resolve_starting_chapter_id()`) with no new scene and no UI. Task 2 adds the actual menu scene, whose Continue button reads the exact pointer path Task 1 defines - Task 1 must be fully implemented, tested, and committed first.

**Tech Stack:** Godot 4.3 / GDScript. No new Python code - the art step reuses `generate_backgrounds.py` unchanged via one new `locations.json` entry.

## Global Constraints

- Godot 4.3 floor.
- GUT headless test discipline: prime once per fresh worktree (`godot --headless --path . --editor --quit`), then `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`. Never re-run priming in the same worktree.
- Commit per task.
- No reviewer subagent dispatch, task-level or final - standing project override. Controller self-verifies every diff and test run directly.
- GUT's headless runner never goes through `project.godot`'s `run/main_scene` (it's invoked via `-s addons/gut/gut_cmdln.gd`, bypassing the normal scene-launch path) - Task 2's one-line change to that value needs no special test handling.
- Tests that touch `user://borrowed_fortune_current_chapter.json` clear it in both `before_each()` and `after_each()`, same discipline as every other raw-file test fixture in this project.

---

## Task 1: save-pointer mechanism

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd`
- Modify: `scenes/main/Main.gd`
- Test: `tests/unit/test_chapter_view_save_pointer.gd` (new)
- Test: `tests/unit/test_main.gd` (new)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the pointer file path `"user://borrowed_fortune_current_chapter.json"` and its `{"chapter_id": "..."}` shape, written by `ChapterView._write_current_chapter_pointer()` and read by `Main._resolve_starting_chapter_id()`. **Task 2 depends on this path and shape exactly** - it is not independent of this task, unlike the background/portrait passes' task pairs.

- [ ] **Step 1: Write the failing tests in `tests/unit/test_chapter_view_save_pointer.gd`**

A separate file, same reasoning as `test_chapter_view_background.gd`/`test_chapter_view_portraits.gd` - its fixture touches a real file on disk, so it should only run around these tests, not the 390+ unrelated tests in `test_chapter_view.gd`.

```gdscript
extends GutTest

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

func before_each():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))

func after_each():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))

func _read_pointer() -> Dictionary:
	var file := FileAccess.open(POINTER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed

func test_write_current_chapter_pointer_writes_the_given_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer("chapter_02_bost")
	assert_true(FileAccess.file_exists(POINTER_PATH))
	assert_eq(_read_pointer()["chapter_id"], "chapter_02_bost")

func test_write_current_chapter_pointer_with_null_clears_an_existing_pointer():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer("chapter_02_bost")
	assert_true(FileAccess.file_exists(POINTER_PATH), "sanity check: must exist first")

	chapter_view._write_current_chapter_pointer(null)
	assert_false(FileAccess.file_exists(POINTER_PATH))

func test_write_current_chapter_pointer_with_null_and_no_existing_pointer_does_not_error():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer(null)
	assert_false(FileAccess.file_exists(POINTER_PATH))

func test_completing_a_chapter_writes_the_pointer_to_its_next_chapter_id():
	# A synthetic 2-node tree, not real chapter content - _save_and_finish()'s
	# pointer-writing only depends on the current node's own next_chapter_id
	# (or ChapterView.next_chapter_id, unused here), never on real content,
	# so this stays independent of any specific chapter's real node count.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([
		{"id": "n01", "text": "", "choices": [{"text": "Continue.", "next_id": "n02", "effects": {}}]},
		{"id": "n02", "text": "", "choices": [], "next_chapter_id": "chapter_02_bost"},
	], "n01")
	chapter_view._on_choice_pressed(0)
	assert_true(FileAccess.file_exists(POINTER_PATH))
	assert_eq(_read_pointer()["chapter_id"], "chapter_02_bost")

func test_reaching_a_true_ending_clears_the_pointer():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer("chapter_02_bost")
	assert_true(FileAccess.file_exists(POINTER_PATH), "sanity check: must exist first")

	chapter_view.dialogue_engine.load_tree([
		{"id": "n01", "text": "", "choices": [{"text": "Continue.", "next_id": "n02", "effects": {}}]},
		{"id": "n02", "text": "", "choices": []},
	], "n01")
	chapter_view._on_choice_pressed(0)
	assert_false(FileAccess.file_exists(POINTER_PATH))
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_chapter_view_save_pointer.gd` FAILS - `_write_current_chapter_pointer()` doesn't exist yet.

- [ ] **Step 3: Add `_write_current_chapter_pointer()` to `ChapterView.gd` and call it from `_save_and_finish()`**

Add this new method anywhere in the file (e.g. directly after `_save_and_finish()`):

```gdscript
func _write_current_chapter_pointer(next_id) -> void:
	var pointer_path := "user://borrowed_fortune_current_chapter.json"
	if next_id == null:
		if FileAccess.file_exists(pointer_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(pointer_path))
		return
	var file := FileAccess.open(pointer_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"chapter_id": next_id}))
	file.close()
```

In `_save_and_finish()`, the current code reads:

```gdscript
	var resolved_next_chapter_id = dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)
	if resolved_next_chapter_id == null:
		return
```

Insert one new line between those two, so it reads:

```gdscript
	var resolved_next_chapter_id = dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)
	_write_current_chapter_pointer(resolved_next_chapter_id)
	if resolved_next_chapter_id == null:
		return
```

Nothing else in `_save_and_finish()` changes.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_chapter_view_save_pointer.gd` passes, and every pre-existing test still passes too (241 tests before this task).

- [ ] **Step 5: Write the failing tests in `tests/unit/test_main.gd`**

No test file for `Main.gd`/`Main.tscn` exists yet in this project - confirmed by direct search before writing this plan.

```gdscript
extends GutTest

const MainScene := preload("res://scenes/main/Main.tscn")
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

func before_each():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))

func after_each():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))

func _write_pointer(data: Dictionary) -> void:
	var file := FileAccess.open(POINTER_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func test_resolve_starting_chapter_id_defaults_to_the_prologue_with_no_pointer_file():
	var main = add_child_autofree(MainScene.instantiate())
	assert_eq(main._resolve_starting_chapter_id(), "chapter_00_prologue")

func test_resolve_starting_chapter_id_uses_the_pointers_chapter_id_when_present():
	_write_pointer({"chapter_id": "chapter_03_farah"})
	var main = add_child_autofree(MainScene.instantiate())
	assert_eq(main._resolve_starting_chapter_id(), "chapter_03_farah")

func test_resolve_starting_chapter_id_falls_back_to_the_prologue_with_malformed_json():
	var file := FileAccess.open(POINTER_PATH, FileAccess.WRITE)
	file.store_string("not valid json{{{")
	file.close()
	var main = add_child_autofree(MainScene.instantiate())
	assert_eq(main._resolve_starting_chapter_id(), "chapter_00_prologue")

func test_resolve_starting_chapter_id_falls_back_to_the_prologue_when_chapter_id_key_missing():
	_write_pointer({"something_else": "value"})
	var main = add_child_autofree(MainScene.instantiate())
	assert_eq(main._resolve_starting_chapter_id(), "chapter_00_prologue")

func test_ready_loads_chapter_view_to_the_resolved_starting_chapter():
	_write_pointer({"chapter_id": "chapter_01_teginabad"})
	var main = add_child_autofree(MainScene.instantiate())
	assert_eq(main.chapter_view.chapter_id, "chapter_01_teginabad")
```

- [ ] **Step 6: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_main.gd` FAILS - `_resolve_starting_chapter_id()` doesn't exist yet, and `_ready()` always hardcodes `"chapter_00_prologue"`.

- [ ] **Step 7: Replace `Main.gd`'s hardcoded load with `_resolve_starting_chapter_id()`**

Current full content of `Main.gd`:

```gdscript
extends Control

@onready var chapter_view = $ChapterView

func _ready() -> void:
	chapter_view.load_chapter_by_id("chapter_00_prologue")
```

Replace it with:

```gdscript
extends Control

@onready var chapter_view = $ChapterView
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

func _ready() -> void:
	chapter_view.load_chapter_by_id(_resolve_starting_chapter_id())

func _resolve_starting_chapter_id() -> String:
	if not FileAccess.file_exists(POINTER_PATH):
		return "chapter_00_prologue"
	var file := FileAccess.open(POINTER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary) or not parsed.has("chapter_id"):
		return "chapter_00_prologue"
	return parsed["chapter_id"]
```

- [ ] **Step 8: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_main.gd` passes, and the whole suite is still green (241 tests before this task; 251 after - 5 new in `test_chapter_view_save_pointer.gd` + 5 new in `test_main.gd`).

- [ ] **Step 9: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd scenes/main/Main.gd tests/unit/test_chapter_view_save_pointer.gd tests/unit/test_main.gd
git commit -m "feat: add a save-pointer so Continue can resume at the right chapter"
```

---

## Task 2: the menu scene

**Files:**
- Create: `scenes/main_menu/MainMenu.tscn`
- Create: `scenes/main_menu/MainMenu.gd`
- Modify: `project.godot`
- Modify: `tools/pixellab/locations.json`
- Test: `tests/unit/test_main_menu.gd` (new)

**Interfaces:**
- Consumes: the exact pointer path and shape Task 1 produces (`"user://borrowed_fortune_current_chapter.json"`, `{"chapter_id": "..."}`) - **this task genuinely depends on Task 1 being merged first**, unlike the background/portrait passes' independent task pairs. Do not start this task until Task 1's tests are green and committed.
- Produces: nothing later depends on this - last task in the plan.

- [ ] **Step 1: Write the failing tests in `tests/unit/test_main_menu.gd`**

```gdscript
extends GutTest

const MainMenuScene := preload("res://scenes/main_menu/MainMenu.tscn")
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

func before_each():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))

func after_each():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))

func test_continue_button_is_disabled_when_no_pointer_file_exists():
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var continue_button: Button = menu.get_node("ButtonsContainer/ContinueButton")
	assert_true(continue_button.disabled)

func test_continue_button_is_enabled_when_a_pointer_file_exists():
	var file := FileAccess.open(POINTER_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"chapter_id": "chapter_02_bost"}))
	file.close()
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var continue_button: Button = menu.get_node("ButtonsContainer/ContinueButton")
	assert_false(continue_button.disabled)
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both tests FAIL - `res://scenes/main_menu/MainMenu.tscn` doesn't exist yet, so the `preload()` itself errors.

- [ ] **Step 3: Write `scenes/main_menu/MainMenu.gd`**

```gdscript
extends Control

const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

@onready var background: TextureRect = $Background
@onready var continue_button: Button = $ButtonsContainer/ContinueButton
@onready var new_game_button: Button = $ButtonsContainer/NewGameButton
@onready var quit_button: Button = $ButtonsContainer/QuitButton

func _ready() -> void:
	_update_background()
	continue_button.disabled = not FileAccess.file_exists(POINTER_PATH)
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
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

func _on_new_game_pressed() -> void:
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
```

- [ ] **Step 4: Write `scenes/main_menu/MainMenu.tscn`**

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

[node name="TitleLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 16.0
offset_top = 64.0
offset_right = -16.0
offset_bottom = 120.0
theme_override_font_sizes/font_size = 36
horizontal_alignment = 1
text = "Borrowed Fortune"

[node name="ButtonsContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = -80.0
offset_right = 100.0
offset_bottom = 80.0

[node name="NewGameButton" type="Button" parent="ButtonsContainer"]
layout_mode = 2
text = "New Game"

[node name="ContinueButton" type="Button" parent="ButtonsContainer"]
layout_mode = 2
text = "Continue"

[node name="QuitButton" type="Button" parent="ButtonsContainer"]
layout_mode = 2
text = "Quit"
```

(`anchors_preset = 15` is `PRESET_FULL_RECT`, `10` is `PRESET_TOP_WIDE`, `8` is `PRESET_CENTER` - the same enum values already used throughout `ChapterView.tscn`. `horizontal_alignment = 1` is `HORIZONTAL_ALIGNMENT_CENTER`, matching `StatusReadout`'s existing use of `2` for `HORIZONTAL_ALIGNMENT_RIGHT` in the same file elsewhere in this project. The button box's exact height is a starting point, not pixel-perfect - fine to nudge after visually running the game once, this isn't covered by any automated test.)

- [ ] **Step 5: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both tests in `test_main_menu.gd` pass, and the whole suite is still green (251 tests before this task; 253 after - 2 new in `test_main_menu.gd`).

- [ ] **Step 6: Change `project.godot`'s entry point**

Current full content:

```
; Engine configuration file.
config_version=5

[application]

config/name="Borrowed Fortune"
run/main_scene="res://scenes/main/Main.tscn"
config/features=PackedStringArray("4.3", "Forward Plus")

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

Change only the `run/main_scene` line:

```
run/main_scene="res://scenes/main_menu/MainMenu.tscn"
```

Nothing else in the file changes. This has no effect on the test suite - GUT's headless runner never reads this value (see Global Constraints).

- [ ] **Step 7: Add the menu background entry to `tools/pixellab/locations.json`**

Read the current file first (it's the same 10-entry array from the backgrounds pass) and add one new entry to the array:

```json
  {
    "output": "main_menu.png",
    "chapter_ids": ["main_menu"],
    "description": "a dawn scene, a caravan and its animals loaded and ready at a city gate, about to set out on the road"
  }
```

`"main_menu"` is not a real chapter id in `manifest.json` - it's just a string that becomes the output filename via `generate_backgrounds.py`'s existing chapter-id-keyed naming convention (`generate_location()` doesn't check `chapter_ids` against the manifest, it only uses those strings to build `res://assets/backgrounds/<value>.png` paths). This produces `assets/backgrounds/main_menu.png`, which is exactly the path `MainMenu.gd`'s `_update_background()` reads. No Python code changes - running `python3 tools/pixellab/generate_backgrounds.py` again (by hand, afterward, same as every previous manual art-generation step this project has done) picks up only this one new entry; the other 10 are already on disk and get skipped.

- [ ] **Step 8: Run the full suite one more time to confirm nothing regressed**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: still green, same count as Step 5 (this step touched no GDScript).

- [ ] **Step 9: Commit**

```bash
git add scenes/main_menu/MainMenu.tscn scenes/main_menu/MainMenu.gd project.godot tools/pixellab/locations.json tests/unit/test_main_menu.gd
git commit -m "feat: add a main menu with working New Game/Continue/Quit"
```

---

## Self-Review Notes

- **Spec coverage:** save-pointer write/clear mechanism → Task 1 Steps 1-4. `Main.gd`'s resolver + fallback behavior → Task 1 Steps 5-8. Menu scene, background, button wiring → Task 2 Steps 1-5. `project.godot` entry-point switch → Task 2 Step 6. New art manifest entry, no new Python → Task 2 Step 7. Task-dependency ordering (not independent, unlike prior pixellab passes) → stated in both tasks' Interfaces blocks and in the plan's own Architecture line.
- **Placeholder scan:** none found - every step has literal file content or an exact, complete code block, including the full current-and-after content of both small files this plan edits in place (`Main.gd`, `project.godot`).
- **Type consistency:** `_write_current_chapter_pointer(next_id)` accepts `String` or `null` (matching `_save_and_finish()`'s own `resolved_next_chapter_id` variable, which is untyped precisely because it can be either) in both its definition (Task 1 Step 3) and every call site across both task's tests. `_resolve_starting_chapter_id() -> String` always returns a `String` (never `null`) - checked consistently across its own tests and its one call site in `_ready()`.
- **Task independence explicitly NOT claimed this time:** Task 2's Interfaces block states the real dependency plainly, and Task 2's tests (`test_main_menu.gd`) rely on the exact pointer path/shape Task 1 defines - if Task 1's shape ever changed, Task 2's tests would need updating too. This is a deliberate, correct departure from the background/portrait passes' independent-task pattern, not an oversight.
- **Known limitation, not new:** `MainMenu.gd`'s background loader uses the same raw `FileAccess`/`Image.load_from_file()` pattern as every other art loader in this project, and inherits the same already-accepted, already-recorded exported-build limitation (raw `res://` PNGs don't survive an export). Not re-documented as a new decision.
