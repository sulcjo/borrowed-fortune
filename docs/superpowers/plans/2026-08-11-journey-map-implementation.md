# Journey Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a read-only "you are here" journey map, reached from a new fourth button on the main menu, showing the player's progress along the caravan route using the location art already generated.

**Architecture:** Two tasks, genuinely sequential like the main menu pass's Task 1/Task 2. Task 1 is the pure engine layer (`JourneyMapBuilder`) with zero file I/O - fully unit-testable against an in-test route-data literal. Task 2 is everything that actually touches the filesystem or the scene tree: the real `content/map/route.json` (created here, not Task 1, since nothing reads it from disk until this task), the `JourneyMapScreen` scene, and the new `MapButton` on `MainMenu`.

**Tech Stack:** Godot 4.3 / GDScript. No new Python code, no new art - reuses the 11 existing `assets/backgrounds/*.png` files.

## Global Constraints

- Godot 4.3 floor.
- GUT headless test discipline: prime once per fresh worktree (`godot --headless --path . --editor --quit` - a SIGSEGV on this first run is expected and harmless, resources still import correctly despite the crash; never re-run priming twice in the same worktree), then `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`.
- Commit per task.
- No reviewer subagent dispatch, task-level or final - standing project override. Controller self-verifies every diff and test run directly.
- Baseline before this plan: 258 tests (257 passing + 1 pre-existing harmless "risky" zero-assertion test, unrelated to this feature - do not attempt to fix it).
- Every waypoint chapter id below is verified real, taken directly from `content/chapters/manifest.json` and the `next_chapter_id` overrides inside each chapter's own dialogue JSON (confirmed during brainstorming, not assumed from the manifest alone, since most manifest entries have `next_chapter_id: null` and the real chaining lives in per-node overrides).

---

## Task 1: `JourneyMapBuilder` - the pure engine layer

**Files:**
- Create: `engine/map/JourneyMapBuilder.gd`
- Test: `tests/unit/test_journey_map_builder.gd` (new)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `JourneyMapBuilder.build_waypoints(route_data: Dictionary, visited_chapter_ids: Dictionary, current_chapter_id: String) -> Array` - each element `{"chapter_id": String, "display_name": String, "status": "current"|"visited"|"unvisited", "is_ending": bool}`. Also `JourneyMapBuilder.all_chapter_ids(route_data: Dictionary) -> Array` - every chapter id that appears anywhere in `route_data` (both routes), used by Task 2 in two places (scanning which chapters have a save file, and the main menu's Map-button gating) so the id list is derived from the data once, in one tested place, instead of hardcoded twice in scene code.
- `route_data`'s exact shape (both methods take the same parsed structure - this is the schema Task 2's real `content/map/route.json` file must match exactly):

```json
{
  "display_names": {
    "chapter_00_prologue": "Ghazni",
    "chapter_01_teginabad": "Teginabad",
    "chapter_02_bost": "Bost",
    "chapter_03_farah": "Farah",
    "chapter_04a_herat": "Herat",
    "chapter_04b_herat_favor": "Herat",
    "chapter_06_pushang": "Pushang",
    "chapter_07_sarakhs": "Sarakhs",
    "chapter_07b_merv": "Merv",
    "chapter_08_nishapur": "Nishapur",
    "chapter_05_plunder_ending": "Plunder"
  },
  "shared_prefix": ["chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah"],
  "fork": {"main": "chapter_04a_herat", "favor": "chapter_04b_herat_favor"},
  "main_suffix": ["chapter_06_pushang", "chapter_07_sarakhs", {"chapter_id": "chapter_07b_merv", "optional": true}, "chapter_08_nishapur"],
  "favor_suffix": ["chapter_05_plunder_ending"]
}
```

- [ ] **Step 1: Write the failing tests in `tests/unit/test_journey_map_builder.gd`**

```gdscript
extends GutTest

func _route_data() -> Dictionary:
	return {
		"display_names": {
			"chapter_00_prologue": "Ghazni",
			"chapter_01_teginabad": "Teginabad",
			"chapter_02_bost": "Bost",
			"chapter_03_farah": "Farah",
			"chapter_04a_herat": "Herat",
			"chapter_04b_herat_favor": "Herat",
			"chapter_06_pushang": "Pushang",
			"chapter_07_sarakhs": "Sarakhs",
			"chapter_07b_merv": "Merv",
			"chapter_08_nishapur": "Nishapur",
			"chapter_05_plunder_ending": "Plunder",
		},
		"shared_prefix": [
			"chapter_00_prologue",
			"chapter_01_teginabad",
			"chapter_02_bost",
			"chapter_03_farah",
		],
		"fork": {
			"main": "chapter_04a_herat",
			"favor": "chapter_04b_herat_favor",
		},
		"main_suffix": [
			"chapter_06_pushang",
			"chapter_07_sarakhs",
			{"chapter_id": "chapter_07b_merv", "optional": true},
			"chapter_08_nishapur",
		],
		"favor_suffix": [
			"chapter_05_plunder_ending",
		],
	}

func _chapter_ids(waypoints: Array) -> Array:
	var ids: Array = []
	for waypoint in waypoints:
		ids.append(waypoint["chapter_id"])
	return ids

func test_prefix_only_preview_before_fork_resolves():
	var builder := JourneyMapBuilder.new()
	var visited := {"chapter_00_prologue": true, "chapter_01_teginabad": true}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_02_bost")

	assert_eq(waypoints.size(), 4)
	assert_eq(_chapter_ids(waypoints), ["chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah"])
	assert_eq(waypoints[0]["status"], "visited")
	assert_eq(waypoints[2]["status"], "current")
	assert_eq(waypoints[3]["status"], "unvisited")

func test_main_route_resolution_walks_main_suffix_and_flags_nishapur_as_ending():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_07_sarakhs")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_08_nishapur",
	])
	assert_eq(waypoints[6]["status"], "current")
	var nishapur = waypoints[7]
	assert_eq(nishapur["status"], "unvisited")
	assert_true(nishapur["is_ending"])

func test_favor_route_resolution_never_shows_main_suffix_and_flags_plunder_as_ending():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04b_herat_favor": true, "chapter_05_plunder_ending": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04b_herat_favor", "chapter_05_plunder_ending",
	])
	var ids := _chapter_ids(waypoints)
	for chapter_id in ["chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur"]:
		assert_false(ids.has(chapter_id))
	var plunder = waypoints[5]
	assert_eq(plunder["status"], "visited")
	assert_true(plunder["is_ending"])

func test_merv_appears_when_visited():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true, "chapter_07_sarakhs": true, "chapter_07b_merv": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_08_nishapur")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur",
	])
	assert_eq(waypoints[7]["status"], "visited")
	assert_eq(waypoints[8]["status"], "current")

func test_merv_skipped_silently_without_stopping_the_walk():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true, "chapter_07_sarakhs": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "chapter_08_nishapur")

	assert_eq(_chapter_ids(waypoints), [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_06_pushang", "chapter_07_sarakhs", "chapter_08_nishapur",
	])
	assert_false(_chapter_ids(waypoints).has("chapter_07b_merv"))
	assert_eq(waypoints[7]["status"], "current")

func test_finished_game_with_no_current_chapter_marks_nothing_as_current():
	var builder := JourneyMapBuilder.new()
	var visited := {
		"chapter_00_prologue": true, "chapter_01_teginabad": true, "chapter_02_bost": true, "chapter_03_farah": true,
		"chapter_04a_herat": true, "chapter_06_pushang": true, "chapter_07_sarakhs": true, "chapter_08_nishapur": true,
	}
	var waypoints := builder.build_waypoints(_route_data(), visited, "")

	for waypoint in waypoints:
		assert_ne(waypoint["status"], "current")
	assert_eq(waypoints[7]["chapter_id"], "chapter_08_nishapur")
	assert_eq(waypoints[7]["status"], "visited")
	assert_true(waypoints[7]["is_ending"])

func test_all_chapter_ids_returns_every_id_across_both_routes():
	var builder := JourneyMapBuilder.new()
	var ids := builder.all_chapter_ids(_route_data())
	assert_eq(ids.size(), 11)
	for expected_id in [
		"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
		"chapter_04a_herat", "chapter_04b_herat_favor",
		"chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur",
		"chapter_05_plunder_ending",
	]:
		assert_true(ids.has(expected_id), "missing %s" % expected_id)
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_journey_map_builder.gd` FAILS - `JourneyMapBuilder` doesn't exist yet.

- [ ] **Step 3: Write `engine/map/JourneyMapBuilder.gd`**

```gdscript
extends RefCounted
class_name JourneyMapBuilder

func build_waypoints(route_data: Dictionary, visited_chapter_ids: Dictionary, current_chapter_id: String) -> Array:
	var display_names: Dictionary = route_data.get("display_names", {})
	var waypoints: Array = []

	for chapter_id in route_data.get("shared_prefix", []):
		waypoints.append(_make_waypoint(chapter_id, display_names, visited_chapter_ids, current_chapter_id, false))

	var fork: Dictionary = route_data.get("fork", {})
	var main_id: String = fork.get("main", "")
	var favor_id: String = fork.get("favor", "")

	if _is_reached(main_id, visited_chapter_ids, current_chapter_id):
		waypoints.append(_make_waypoint(main_id, display_names, visited_chapter_ids, current_chapter_id, false))
		_append_suffix(waypoints, route_data.get("main_suffix", []), display_names, visited_chapter_ids, current_chapter_id)
	elif _is_reached(favor_id, visited_chapter_ids, current_chapter_id):
		waypoints.append(_make_waypoint(favor_id, display_names, visited_chapter_ids, current_chapter_id, false))
		_append_suffix(waypoints, route_data.get("favor_suffix", []), display_names, visited_chapter_ids, current_chapter_id)

	return waypoints

func all_chapter_ids(route_data: Dictionary) -> Array:
	var ids: Array = []
	for chapter_id in route_data.get("shared_prefix", []):
		ids.append(chapter_id)
	var fork: Dictionary = route_data.get("fork", {})
	if fork.has("main"):
		ids.append(fork["main"])
	if fork.has("favor"):
		ids.append(fork["favor"])
	for entry in route_data.get("main_suffix", []):
		ids.append(_entry_chapter_id(entry))
	for entry in route_data.get("favor_suffix", []):
		ids.append(_entry_chapter_id(entry))
	return ids

func _entry_chapter_id(entry) -> String:
	if entry is Dictionary:
		return entry["chapter_id"]
	return entry

func _append_suffix(waypoints: Array, suffix: Array, display_names: Dictionary, visited_chapter_ids: Dictionary, current_chapter_id: String) -> void:
	var last_index := suffix.size() - 1
	for i in range(suffix.size()):
		var entry = suffix[i]
		var chapter_id := _entry_chapter_id(entry)
		var is_optional: bool = entry is Dictionary and entry.get("optional", false)
		var is_ending := i == last_index
		if is_optional and not _is_reached(chapter_id, visited_chapter_ids, current_chapter_id):
			continue
		waypoints.append(_make_waypoint(chapter_id, display_names, visited_chapter_ids, current_chapter_id, is_ending))

func _is_reached(chapter_id: String, visited_chapter_ids: Dictionary, current_chapter_id: String) -> bool:
	if chapter_id == "":
		return false
	return chapter_id == current_chapter_id or visited_chapter_ids.has(chapter_id)

func _make_waypoint(chapter_id: String, display_names: Dictionary, visited_chapter_ids: Dictionary, current_chapter_id: String, is_ending: bool) -> Dictionary:
	var status: String
	if chapter_id == current_chapter_id:
		status = "current"
	elif visited_chapter_ids.has(chapter_id):
		status = "visited"
	else:
		status = "unvisited"
	return {
		"chapter_id": chapter_id,
		"display_name": display_names.get(chapter_id, chapter_id),
		"status": status,
		"is_ending": is_ending,
	}
```

`class_name JourneyMapBuilder` makes it globally available, same as `DialogueEngine`/`Ledger`/`ReputationTracker` elsewhere in this project - no `preload()` needed anywhere that uses it, including the test file above.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: every test in `test_journey_map_builder.gd` passes, and every pre-existing test still passes too (258 tests before this task; 265 after - 7 new, all in `test_journey_map_builder.gd`).

- [ ] **Step 5: Commit**

```bash
git add engine/map/JourneyMapBuilder.gd tests/unit/test_journey_map_builder.gd
git commit -m "feat: add JourneyMapBuilder, the pure route-walking logic for the journey map"
```

---

## Task 2: the journey map screen and the main menu's new Map button

**Files:**
- Create: `content/map/route.json`
- Create: `scenes/journey_map/JourneyMapScreen.tscn`
- Create: `scenes/journey_map/JourneyMapScreen.gd`
- Modify: `scenes/main_menu/MainMenu.tscn`
- Modify: `scenes/main_menu/MainMenu.gd`
- Test: `tests/unit/test_journey_map_screen.gd` (new)
- Test: `tests/unit/test_main_menu.gd` (extend the existing 2 tests with 3 more)

**Interfaces:**
- Consumes: `JourneyMapBuilder.build_waypoints(route_data, visited_chapter_ids, current_chapter_id) -> Array` and `JourneyMapBuilder.all_chapter_ids(route_data) -> Array` from Task 1, exactly as defined there - **this task genuinely depends on Task 1 being merged first**, since `content/map/route.json`'s schema must match what `JourneyMapBuilder` expects, and both `JourneyMapScreen.gd` and `MainMenu.gd` call `all_chapter_ids()` directly rather than each hardcoding their own copy of the id list. Do not start this task until Task 1's tests are green and committed.
- Produces: nothing later depends on this - last task in the plan.
- `JourneyMapScreen.gd`'s `_load_route_data()` (opens and parses `content/map/route.json`) and `MainMenu.gd`'s equivalent are two small, separately-written copies of the same ~8-line `FileAccess.open()`/`JSON.parse_string()` boilerplate - this matches existing precedent in this codebase (`ChapterView`/`MainMenu` each have their own separate `_update_background()`, `Main.gd`/`MainMenu.gd` each have their own separate pointer-file-reading code) rather than introducing a new shared file-I/O utility for it. The part that *would* actually drift if duplicated - the schema-walking logic - is the part Task 1 already extracted into `all_chapter_ids()`.

- [ ] **Step 1: Create `content/map/route.json`**

```json
{
  "display_names": {
    "chapter_00_prologue": "Ghazni",
    "chapter_01_teginabad": "Teginabad",
    "chapter_02_bost": "Bost",
    "chapter_03_farah": "Farah",
    "chapter_04a_herat": "Herat",
    "chapter_04b_herat_favor": "Herat",
    "chapter_06_pushang": "Pushang",
    "chapter_07_sarakhs": "Sarakhs",
    "chapter_07b_merv": "Merv",
    "chapter_08_nishapur": "Nishapur",
    "chapter_05_plunder_ending": "Plunder"
  },
  "shared_prefix": [
    "chapter_00_prologue",
    "chapter_01_teginabad",
    "chapter_02_bost",
    "chapter_03_farah"
  ],
  "fork": {
    "main": "chapter_04a_herat",
    "favor": "chapter_04b_herat_favor"
  },
  "main_suffix": [
    "chapter_06_pushang",
    "chapter_07_sarakhs",
    {"chapter_id": "chapter_07b_merv", "optional": true},
    "chapter_08_nishapur"
  ],
  "favor_suffix": [
    "chapter_05_plunder_ending"
  ]
}
```

This is exactly the schema Task 1's `JourneyMapBuilder` and its tests already assume. This is a data file with no consumer until Step 4 - the JSON-validity check below is the whole verification for this step; there is no GUT test to write or fail here, unlike every other step in this plan.

```bash
python3 -c "import json; json.load(open('content/map/route.json'))"
```

Expected: no output, no error (valid JSON).

- [ ] **Step 2: Write the failing tests in `tests/unit/test_journey_map_screen.gd`**

```gdscript
extends GutTest

const JourneyMapScreenScene := preload("res://scenes/journey_map/JourneyMapScreen.tscn")
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"
const ALL_CHAPTER_IDS := [
	"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
	"chapter_04a_herat", "chapter_04b_herat_favor",
	"chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur",
	"chapter_05_plunder_ending",
]

func before_each():
	_clear_fixture_files()

func after_each():
	_clear_fixture_files()

func _clear_fixture_files():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	for chapter_id in ALL_CHAPTER_IDS:
		var path := "user://borrowed_fortune_%s.json" % chapter_id
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _write_save(chapter_id: String) -> void:
	var file := FileAccess.open("user://borrowed_fortune_%s.json" % chapter_id, FileAccess.WRITE)
	file.store_string(JSON.stringify({"chapter_id": chapter_id}))
	file.close()

func _write_pointer(chapter_id: String) -> void:
	var file := FileAccess.open(POINTER_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"chapter_id": chapter_id}))
	file.close()

func test_renders_the_correct_number_of_waypoints_and_marks_the_current_one():
	_write_save("chapter_00_prologue")
	_write_save("chapter_01_teginabad")
	_write_pointer("chapter_02_bost")
	var screen = add_child_autofree(JourneyMapScreenScene.instantiate())
	assert_eq(screen.waypoints_container.get_child_count(), 4)
	var current_label: Label = screen.waypoints_container.get_child(2).get_node("Label")
	assert_true(current_label.text.contains("Bost"))

func test_renders_the_ending_marker_when_an_ending_has_been_reached():
	_write_save("chapter_00_prologue")
	_write_save("chapter_01_teginabad")
	_write_save("chapter_02_bost")
	_write_save("chapter_03_farah")
	_write_save("chapter_04b_herat_favor")
	_write_save("chapter_05_plunder_ending")
	var screen = add_child_autofree(JourneyMapScreenScene.instantiate())
	assert_eq(screen.waypoints_container.get_child_count(), 6)
	var ending_label: Label = screen.waypoints_container.get_child(5).get_node("Label")
	assert_eq(ending_label.text, "Journey's End")
```

- [ ] **Step 3: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both tests FAIL - `res://scenes/journey_map/JourneyMapScreen.tscn` doesn't exist yet, so the `preload()` itself errors.

- [ ] **Step 4: Write `scenes/journey_map/JourneyMapScreen.gd`**

```gdscript
extends Control

const ROUTE_PATH := "res://content/map/route.json"
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

@onready var waypoints_container: HBoxContainer = $WaypointsContainer
@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_render_waypoints()

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
	texture_rect.custom_minimum_size = Vector2(80, 45)
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

The "you are here" marker is a `"▶ "` text prefix on the current waypoint's
label, and the ending marker replaces the label text with `"Journey's
End"` - both plain `Label` text, no new art or shader, matching the
`modulate`-only approach already used for the dim/unvisited state.

- [ ] **Step 5: Write `scenes/journey_map/JourneyMapScreen.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/journey_map/JourneyMapScreen.gd" id="1"]

[node name="JourneyMapScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="WaypointsContainer" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -400.0
offset_top = -60.0
offset_right = 400.0
offset_bottom = 60.0

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

(`anchors_preset = 8` is `PRESET_CENTER`, matching `MainMenu.tscn`'s
`ButtonsContainer`. `anchors_preset = 2` is `PRESET_BOTTOM_LEFT` - new to
this project's scenes, but a standard Godot preset value; it anchors the
button to the bottom-left corner with a fixed 100x40 size via the
offsets. The waypoint row's exact width/spacing is a starting point, not
pixel-perfect - fine to nudge after visually running the game once, same
as the main menu's button box; this isn't covered by any automated test.)

- [ ] **Step 6: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both tests in `test_journey_map_screen.gd` pass, and the whole suite is still green (265 tests before this step; 267 after - 2 new).

- [ ] **Step 7: Write the failing tests for `MapButton` in `tests/unit/test_main_menu.gd`**

Current full content of `tests/unit/test_main_menu.gd`:

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

Replace it with:

```gdscript
extends GutTest

const MainMenuScene := preload("res://scenes/main_menu/MainMenu.tscn")
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"
const ALL_CHAPTER_IDS := [
	"chapter_00_prologue", "chapter_01_teginabad", "chapter_02_bost", "chapter_03_farah",
	"chapter_04a_herat", "chapter_04b_herat_favor",
	"chapter_06_pushang", "chapter_07_sarakhs", "chapter_07b_merv", "chapter_08_nishapur",
	"chapter_05_plunder_ending",
]

func before_each():
	_clear_fixture_files()

func after_each():
	_clear_fixture_files()

func _clear_fixture_files():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	for chapter_id in ALL_CHAPTER_IDS:
		var path := "user://borrowed_fortune_%s.json" % chapter_id
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _write_save(chapter_id: String) -> void:
	var file := FileAccess.open("user://borrowed_fortune_%s.json" % chapter_id, FileAccess.WRITE)
	file.store_string(JSON.stringify({"chapter_id": chapter_id}))
	file.close()

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

func test_map_button_is_disabled_when_nothing_has_been_visited():
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var map_button: Button = menu.get_node("ButtonsContainer/MapButton")
	assert_true(map_button.disabled)

func test_map_button_is_enabled_when_any_chapter_has_a_save_file():
	_write_save("chapter_00_prologue")
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var map_button: Button = menu.get_node("ButtonsContainer/MapButton")
	assert_false(map_button.disabled)

func test_map_button_is_enabled_after_a_finished_game_even_though_continue_is_disabled():
	# The case that motivated giving MapButton its own gating rule instead of
	# reusing ContinueButton's pointer-file check: the pointer is cleared on a
	# true ending, but a finished playthrough still has real per-chapter saves.
	_write_save("chapter_08_nishapur")
	var menu = add_child_autofree(MainMenuScene.instantiate())
	var continue_button: Button = menu.get_node("ButtonsContainer/ContinueButton")
	var map_button: Button = menu.get_node("ButtonsContainer/MapButton")
	assert_true(continue_button.disabled)
	assert_false(map_button.disabled)
```

The `before_each`/`after_each` now clear every known chapter's save path,
not just the pointer file - the two existing `ContinueButton` tests only
ever touch the pointer, so this is a strictly-safer superset for them,
and it's required for the three new `MapButton` tests below to start from
a genuinely clean slate regardless of what any other test elsewhere in
the 265-test suite might have left on disk.

- [ ] **Step 8: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: the 3 new `MapButton` tests FAIL (`ButtonsContainer/MapButton` doesn't exist yet); the 2 existing `ContinueButton` tests still pass unchanged.

- [ ] **Step 9: Add `MapButton` to `MainMenu.tscn` and wire it up in `MainMenu.gd`**

Current full content of `scenes/main_menu/MainMenu.tscn`:

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

Replace the `ButtonsContainer` node's `offset_top`/`offset_bottom` (to fit
a fourth button) and insert `MapButton` between `ContinueButton` and
`QuitButton`:

```
[node name="ButtonsContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = -100.0
offset_right = 100.0
offset_bottom = 100.0

[node name="NewGameButton" type="Button" parent="ButtonsContainer"]
layout_mode = 2
text = "New Game"

[node name="ContinueButton" type="Button" parent="ButtonsContainer"]
layout_mode = 2
text = "Continue"

[node name="MapButton" type="Button" parent="ButtonsContainer"]
layout_mode = 2
text = "Map"

[node name="QuitButton" type="Button" parent="ButtonsContainer"]
layout_mode = 2
text = "Quit"
```

Current full content of `scenes/main_menu/MainMenu.gd`:

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

Replace it with:

```gdscript
extends Control

const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"
const ROUTE_PATH := "res://content/map/route.json"

@onready var background: TextureRect = $Background
@onready var continue_button: Button = $ButtonsContainer/ContinueButton
@onready var new_game_button: Button = $ButtonsContainer/NewGameButton
@onready var map_button: Button = $ButtonsContainer/MapButton
@onready var quit_button: Button = $ButtonsContainer/QuitButton

func _ready() -> void:
	_update_background()
	continue_button.disabled = not FileAccess.file_exists(POINTER_PATH)
	map_button.disabled = _map_button_should_be_disabled()
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

**`MapButton.disabled` deliberately does not reuse `continue_button`'s
`POINTER_PATH` check** - see this task's Interfaces note and the design
spec's own "MainMenu.gd change" section: the pointer is cleared on a true
ending, but a finished playthrough still has real per-chapter save files,
so `MapButton` must stay enabled exactly when `ContinueButton` becomes
disabled for that reason.

- [ ] **Step 10: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: all 5 tests in `test_main_menu.gd` pass, and the whole suite is still green (267 tests before this step; 270 after - 3 new in `test_main_menu.gd`).

- [ ] **Step 11: Commit**

```bash
git add content/map/route.json scenes/journey_map/JourneyMapScreen.tscn scenes/journey_map/JourneyMapScreen.gd scenes/main_menu/MainMenu.tscn scenes/main_menu/MainMenu.gd tests/unit/test_journey_map_screen.gd tests/unit/test_main_menu.gd
git commit -m "feat: add the journey map screen and a Map button on the main menu"
```

---

## Self-Review Notes

- **Spec coverage:** route model (shared prefix / fork / two suffixes, exact JSON schema) → Task 1's Interfaces block and Task 2 Step 1. `JourneyMapBuilder`'s full algorithm (unconditional prefix preview, fork resolution, optional-entry skip-without-stopping, ending tagging, finished-game case) → Task 1 Steps 1-4. `JourneyMapScreen` (route/save/pointer reading, `modulate` dim treatment, current/ending text markers, Back button) → Task 2 Steps 2-6. `MainMenu`'s new `MapButton` and its independent gating rule → Task 2 Steps 7-10. Testing plan's every enumerated case → present verbatim in Task 1 Step 1's 7 tests and Task 2 Steps 2 and 7's tests.
- **Placeholder scan:** none found - every step has literal, complete code or file content. The one place the spec explicitly left a technique open (the current/ending visual markers) is pinned down concretely here (`"▶ "` text prefix, `"Journey's End"` label swap, both plain `Label.text`) rather than carried forward as an open decision.
- **Type consistency:** `build_waypoints()`'s return shape (`chapter_id`/`display_name`/`status`/`is_ending` keys, matching value types) is used identically in every Task 1 test, in `JourneyMapScreen._build_waypoint_node()`, and nowhere else. `all_chapter_ids()` returns a plain `Array` of `String`s, consumed identically by `JourneyMapScreen._scan_visited_chapter_ids()` and `MainMenu._map_button_should_be_disabled()`.
- **Duplication decision made explicit, not left implicit:** the spec flagged the small `_load_route_data()` FileAccess/JSON-parse snippet as a duplication decision for the plan to make. Resolved here by duplicating that ~8-line snippet (matching this project's own established precedent - `_update_background()` and pointer-reading are already each duplicated per-script rather than centralized) while keeping the actual route-schema-walking logic (`all_chapter_ids()`) in exactly one place, in `JourneyMapBuilder`, called by both consumers. This avoids the real drift risk (two different hand-rolled walks of the same nested JSON shape going out of sync) without introducing a new shared utility for the trivial part.
- **Task independence explicitly NOT claimed:** Task 2's Interfaces block states the real dependency on Task 1's exact method signatures and route-data schema, matching the main menu plan's own precedent for its two sequential tasks.
- **Test-fixture discipline:** every new test file that touches real `user://` save files (`test_journey_map_screen.gd`, the rewritten `test_main_menu.gd`) clears every one of the 11 known chapter ids' save paths in both `before_each` and `after_each`, not just the ones that specific test happens to write - the same lesson this project already learned twice during the main menu pass, applied proactively here rather than caught after the fact.
- **Cross-file pollution checked, not assumed:** `test_map_button_is_disabled_when_nothing_has_been_visited` asserts a global negative ("no chapter anywhere has a save file"), which only a `before_each` that covers the *complete* id set can protect against real files another test script left behind. Verified directly (not just reasoned about): `tests/unit/test_chapter_view.gd` has no `before_each`/`after_each` at all and its several full-playthrough tests do leave real production save files on disk after a run (confirmed by inspecting the actual Godot user-data directory - 8 stray `borrowed_fortune_chapter_*.json` files were sitting there from an earlier run of this exact suite). `ALL_CHAPTER_IDS` in both `test_main_menu.gd` and `test_journey_map_screen.gd` is the same 11-id set `JourneyMapBuilder.all_chapter_ids()` would ever produce from `route.json` (confirmed by listing both side by side), so `before_each`'s cleanup fully neutralizes this pre-existing pollution regardless of what ran before it in the same suite. Fixing `test_chapter_view.gd`'s own missing cleanup is a legitimate follow-up but is out of scope for this plan - it predates this feature and nothing here depends on it being fixed.
