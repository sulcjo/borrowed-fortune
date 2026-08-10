# Main Menu Design

**Status:** approved, pending implementation plan.

## Goal

Give the game an actual entry point. Today `project.godot` launches straight
into `Main.tscn`, which unconditionally loads the Prologue - there is no menu
screen at all. This adds one: New Game / Continue / Quit, with a real,
working Continue backed by a small addition to the save mechanism that
already exists but has never been read back.

This is the first sub-project of two (main menu, then a journey-map screen)
split out during brainstorming because they're genuinely independent
features - this spec covers the menu only.

## Continue: extending an existing mechanism, not building a new one

`SaveManager`/`GameState` already exist and already write a per-chapter save
file (`user://borrowed_fortune_<chapter_id>.json`) every time a chapter ends
- `ChapterView._save_and_finish()` already calls `save_manager.save(...)` on
every chapter completion. `SaveManager.load()` already exists too. None of
this is read back today; closing and reopening the game always restarts at
the Prologue regardless of how much of the campaign was completed.

What's actually missing is a way to know **which** chapter's save represents
the player's current position - there's one file per chapter ever visited,
not one "current position" pointer. Adding a single small file,
`user://borrowed_fortune_current_chapter.json`, written at the exact point
`_save_and_finish()` already resolves the next chapter, gives both
`Main.gd` and the new menu a shared answer to "where is the player right
now."

**Position alone isn't enough - Continue must restore state, not just
place the player at the right chapter.** `ChapterView` is a single
long-lived instance for a whole play session today, so reputation, ledger,
and dialogue flags already persist naturally as the player moves from
chapter to chapter without a restart. A fresh app launch creates a brand
new `ChapterView` with a brand new `Ledger`/`ReputationTracker`/
`DialogueEngine`, so resuming at the right chapter with none of that
carried over would silently zero the player's coin, debt, reputation, and
story flags - not a granularity tradeoff, a correctness bug. It's also
concretely dangerous: `chapter_05_plunder_ending`'s fork is entirely
gated on `requires_flag` (`chose_to_stay_entangled`/`chose_to_pivot_away`,
both set back in 4B) - resuming there with empty flags means every choice
filters out and the player lands on a dead-end node with nothing to
click.

The fix reuses what already exists rather than inventing a second save
shape: the pointer file carries the same `GameState.to_dict()` that
`_save_and_finish()` already builds for the per-chapter save, with its
`chapter_id` field overwritten to the chapter being resumed *into* (the
completed chapter's own save keeps the completed chapter's id; the
pointer is the only place that needs the *next* one). `ReputationTracker`
and `Ledger` already have unused `load_from_dict()` methods for exactly
this; `DialogueEngine.load_tree()` never touches `flags`, so restoring
`dialogue_engine.flags` before loading the chapter is enough for
flag-gated choices to resolve correctly the moment the chapter renders.

The pointer's `dialogue_node_id` and `unlocked_glossary_terms` fields ride
along unused, since `state.to_dict()` is reused as-is rather than
hand-picking fields. Neither is read back: resuming always starts at the
chapter's first node (the confirmed chapter-boundary granularity), and a
previously-unlocked glossary term only stays "known" (`has_entry()`) once
that term's own chapter's glossary file has been loaded in this session -
replaying every previously-visited chapter's glossary just to restore
unlock flags is out of scope. This is cosmetic only: no choice is ever
gated on glossary-unlock state, unlike flags and reputation.

**Granularity, confirmed with the user:** this only ever resumes at the
*start* of a chapter, never an exact mid-chapter node - saves already only
happen at chapter boundaries today, so this doesn't change that, it just
stops discarding what's already being saved. Losing in-progress state within
an unfinished chapter on quit is accepted as-is; chapters are short (9-27
nodes).

**On a true ending** (`next_chapter_id` resolves to `null` - the player has
reached one of the game's terminal nodes), the pointer is cleared rather
than written. There's no post-completion content to continue into, so
Continue disabling itself once a playthrough is actually finished is the
correct behavior, not an edge case to work around.

## `ChapterView.gd` change

`_save_and_finish()` gains one new call, right where `resolved_next_chapter_id`
is already computed (before the existing early-return-on-null check, so the
clearing behavior above falls out of the same code path rather than needing
a separate case). It passes the `state` object `_save_and_finish()` already
builds, so the pointer carries the same reputation/ledger/flags data as the
per-chapter save, not just a chapter id:

```gdscript
func _save_and_finish() -> void:
	# ...existing save code, unchanged...
	var resolved_next_chapter_id = dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)
	_write_current_chapter_pointer(resolved_next_chapter_id, state)
	if resolved_next_chapter_id == null:
		return
	# ...existing transition code, unchanged...

func _write_current_chapter_pointer(next_id, state: GameState) -> void:
	var pointer_path := "user://borrowed_fortune_current_chapter.json"
	if next_id == null:
		if FileAccess.file_exists(pointer_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(pointer_path))
		return
	var pointer_data := state.to_dict()
	pointer_data["chapter_id"] = next_id
	var file := FileAccess.open(pointer_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(pointer_data))
	file.close()
```

No other line in `_save_and_finish()` changes. Every existing test that
exercises a full playthrough already reaches this method repeatedly; none of
them assert anything about this new file, so this is additive, not a
behavior change to anything already tested.

A new `resume()` method is the single entry point both a fresh boot and a
Continue go through - restoring state before loading means the restored
values are already in place by the time the chapter's first node renders
(`load_chapter_by_id()` renders synchronously at the end of `load_chapter()`):

```gdscript
func resume(id: String, state_data: Dictionary) -> void:
	if state_data.has("reputation_data"):
		reputation_tracker.load_from_dict(state_data["reputation_data"])
	if state_data.has("ledger_data"):
		ledger.load_from_dict(state_data["ledger_data"])
	if state_data.has("dialogue_flags"):
		dialogue_engine.flags = state_data["dialogue_flags"]
	load_chapter_by_id(id)
```

An empty `state_data` (a fresh boot with no pointer) leaves all three
untouched, so `resume(id, {})` behaves exactly like today's
`load_chapter_by_id(id)` - one code path for both cases, not two that can
drift apart. `load_chapter_by_id()` itself is unchanged and stays callable
directly, since every existing test in this project already calls it that
way.

## `Main.gd` change: resolve a starting chapter and its state instead of hardcoding the Prologue

```gdscript
extends Control

@onready var chapter_view = $ChapterView
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"

func _ready() -> void:
	chapter_view.resume(_resolve_starting_chapter_id(), _read_pointer_file())

func _resolve_starting_chapter_id() -> String:
	var pointer := _read_pointer_file()
	if not pointer.has("chapter_id"):
		return "chapter_00_prologue"
	return pointer["chapter_id"]

func _read_pointer_file() -> Dictionary:
	if not FileAccess.file_exists(POINTER_PATH):
		return {}
	var file := FileAccess.open(POINTER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		return {}
	return parsed
```

`_read_pointer_file()` is the one place that opens and parses the pointer;
both `_resolve_starting_chapter_id()` and `_ready()` go through it rather
than parsing the file twice. Missing, malformed, or incomplete pointer data
all fall back to the Prologue (via `_resolve_starting_chapter_id()`) with an
empty state (via `_read_pointer_file()` returning `{}`) rather than
erroring - same null-safe-fallback discipline the background/portrait art
already established for missing files.

## The menu itself

New `scenes/main_menu/MainMenu.tscn` + `.gd`. `project.godot`'s
`run/main_scene` changes from `res://scenes/main/Main.tscn` to
`res://scenes/main_menu/MainMenu.tscn` - the menu becomes the actual entry
point; `Main.tscn` (gameplay) is reached only by pressing a button.

Scene tree: a `Background` `TextureRect` (identical pattern to
`ChapterView`'s - raw `FileAccess`/`Image.load_from_file()`, null-safe if the
art doesn't exist yet), a `TitleLabel` reading "Borrowed Fortune", and a
`VBoxContainer` holding three default-styled `Button`s: New Game / Continue
/ Quit. No custom button skinning this pass (confirmed with the user) - art
is the background only, buttons stay Godot's default `Button`, same as
every choice button in `ChapterView` today.

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

New Game clears the pointer (if present) before transitioning, so `Main.gd`
falls back to the Prologue. Continue transitions without touching it. Old
per-chapter save files from a previous playthrough are left alone - nothing
reads them except by exact chapter id via the pointer, so they're harmless
and get overwritten naturally as a new playthrough re-reaches those
chapters.

## Art: one new background, reusing the existing pipeline unchanged

One new entry in `tools/pixellab/locations.json`, `output: "main_menu.png"`,
`chapter_ids: ["main_menu"]` - not a real manifest chapter id, just a string
that becomes the output filename via the generator's existing chapter-id-
keyed file-naming convention (`generate_location()` doesn't care whether its
`chapter_ids` values are real manifest keys). No new Python code - the
existing `generate_backgrounds.py` picks up the new entry on its next run
and only generates that one (everything else already exists, skipped as
usual). Description: a dawn scene, a caravan preparing to set out from
Ghazni - distinct from Chapter 00's own bazaar/graveyard background so the
menu doesn't repeat the exact image the player sees seconds later.

## Testing

- `_write_current_chapter_pointer()`'s behavior (writes the correct chapter
  id and state on a real transition, clears the file on a true ending) and
  `resume()`'s behavior (restores reputation/ledger/flags before the
  chapter loads; a no-op with empty state data) get their own new test
  file, `tests/unit/test_chapter_view_save_pointer.gd` - same reasoning as
  the background/portrait passes: a fixture that touches a real file on
  disk shouldn't run around unrelated tests in the 390-line
  `test_chapter_view.gd`. Any test in this file that reaches
  `_save_and_finish()` without first calling `load_chapter_by_id()` writes
  to the default `chapter_id`'s own save file
  (`user://borrowed_fortune_chapter_00_prologue.json`), so that path is
  cleared in `before_each`/`after_each` alongside the pointer file.
- `Main.gd`'s `_resolve_starting_chapter_id()` gets `tests/unit/test_main.gd`:
  falls back to the Prologue with no pointer file, with a malformed one, and
  with one missing the `chapter_id` key; resolves to the pointer's value
  when it's present and valid. Two additional tests verify full observable
  effects after `_ready()` runs: `chapter_view.chapter_id` reflects the
  resolved chapter, and - the round trip that actually proves Continue
  works - `chapter_view.reputation_tracker`, `chapter_view.ledger`, and
  `chapter_view.dialogue_engine.flags` all reflect a pointer file's
  `reputation_data`/`ledger_data`/`dialogue_flags`, not just its
  `chapter_id`.
- `MainMenu.gd` gets `tests/unit/test_main_menu.gd`: `continue_button.disabled`
  is `true` with no pointer file, `false` with one present.
- No test relies on `project.godot`'s `run/main_scene` value - GUT's headless
  test runner (`-s addons/gut/gut_cmdln.gd`) never goes through the normal
  scene-launch path, so changing the entry point has zero effect on how the
  existing suite runs.

## Task dependency, explicitly not independent this time

Unlike the background and portrait passes, this feature's two natural tasks
genuinely depend on each other: the menu's Continue-button check reads the
exact pointer path the `ChapterView`/`Main.gd` change defines. The
implementation plan should sequence them accordingly rather than presenting
them as parallel-safe.

## What this pass does not do

- No exact mid-chapter resume - confirmed, chapter-boundary granularity is
  accepted.
- No custom button skinning or a full `Theme` resource - confirmed,
  background art only, default `Button`s.
- No journey-map screen - that's the second, separate sub-project split out
  during brainstorming, with its own spec to follow.
- No confirmation dialog on New Game (e.g. "overwrite your progress?") - no
  modal infrastructure exists anywhere in this project outside
  `MarginPopup`, and old per-chapter saves aren't actually destroyed by
  starting a new game (see above), so there's nothing to warn about.
