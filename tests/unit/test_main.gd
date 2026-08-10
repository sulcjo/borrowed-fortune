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

func test_ready_restores_reputation_ledger_and_flags_from_the_pointer():
	# The round trip that actually proves Continue works, not just that it
	# lands on the right chapter - reputation/ledger/flags all silently
	# reset without this (see the design spec's Continue section).
	_write_pointer({
		"chapter_id": "chapter_01_teginabad",
		"reputation_data": {"test_faction": 3},
		"ledger_data": {"purse": [], "debts": [], "spent_dirham_equivalent": -12.5},
		"dialogue_flags": {"test_flag": true},
	})
	var main = add_child_autofree(MainScene.instantiate())
	assert_eq(main.chapter_view.reputation_tracker.get_reputation("test_faction"), 3)
	assert_eq(main.chapter_view.ledger.total_wealth_dirham_equivalent(), 12.5)
	assert_true(main.chapter_view.dialogue_engine.flags.get("test_flag", false))
