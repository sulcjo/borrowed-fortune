extends GutTest

const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")
const POINTER_PATH := "user://borrowed_fortune_current_chapter.json"
const PROLOGUE_SAVE_PATH := "user://borrowed_fortune_chapter_00_prologue.json"

func before_each():
	_clear_fixture_files()

func after_each():
	_clear_fixture_files()

func _clear_fixture_files():
	if FileAccess.file_exists(POINTER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(POINTER_PATH))
	if FileAccess.file_exists(PROLOGUE_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROLOGUE_SAVE_PATH))

func _read_pointer() -> Dictionary:
	var file := FileAccess.open(POINTER_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed

func test_write_current_chapter_pointer_writes_the_given_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer("chapter_02_bost", GameState.new())
	assert_true(FileAccess.file_exists(POINTER_PATH))
	assert_eq(_read_pointer()["chapter_id"], "chapter_02_bost")

func test_write_current_chapter_pointer_with_null_clears_an_existing_pointer():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer("chapter_02_bost", GameState.new())
	assert_true(FileAccess.file_exists(POINTER_PATH), "sanity check: must exist first")

	chapter_view._write_current_chapter_pointer(null, GameState.new())
	assert_false(FileAccess.file_exists(POINTER_PATH))

func test_write_current_chapter_pointer_with_null_and_no_existing_pointer_does_not_error():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer(null, GameState.new())
	assert_false(FileAccess.file_exists(POINTER_PATH))

func test_write_current_chapter_pointer_includes_reputation_ledger_and_flags_from_the_given_state():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	var state := GameState.new()
	state.reputation_data = {"test_faction": 3}
	state.ledger_data = {"purse": [], "debts": [], "spent_dirham_equivalent": -12.5}
	state.dialogue_flags = {"test_flag": true}
	chapter_view._write_current_chapter_pointer("chapter_02_bost", state)
	var pointer := _read_pointer()
	assert_eq(pointer["reputation_data"], {"test_faction": 3.0})
	assert_eq(pointer["ledger_data"], {"purse": [], "debts": [], "spent_dirham_equivalent": -12.5})
	assert_eq(pointer["dialogue_flags"], {"test_flag": true})

func test_completing_a_chapter_writes_the_pointer_with_its_next_chapter_id_and_current_state():
	# A synthetic 2-node tree, not real chapter content - _save_and_finish()'s
	# pointer-writing only depends on the current node's own next_chapter_id
	# (or ChapterView.next_chapter_id, unused here) and on ChapterView's own
	# state, never on real content, so the setup stays independent of any
	# specific chapter's real node count. The auto-transition that follows
	# DOES load real Bost content (same as this project's other
	# auto-transition tests) - only the pointer's own values are asserted
	# here, not isolation from real content.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([
		{"id": "n01", "text": "", "choices": [{"text": "Continue.", "next_id": "n02", "effects": {"reputation": {"test_faction": 2}}}]},
		{"id": "n02", "text": "", "choices": [], "next_chapter_id": "chapter_02_bost"},
	], "n01")
	chapter_view._on_choice_pressed(0)
	assert_true(FileAccess.file_exists(POINTER_PATH))
	var pointer := _read_pointer()
	assert_eq(pointer["chapter_id"], "chapter_02_bost")
	assert_eq(pointer["reputation_data"], {"test_faction": 2.0})

func test_reaching_a_true_ending_clears_the_pointer():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._write_current_chapter_pointer("chapter_02_bost", GameState.new())
	assert_true(FileAccess.file_exists(POINTER_PATH), "sanity check: must exist first")

	chapter_view.dialogue_engine.load_tree([
		{"id": "n01", "text": "", "choices": [{"text": "Continue.", "next_id": "n02", "effects": {}}]},
		{"id": "n02", "text": "", "choices": []},
	], "n01")
	chapter_view._on_choice_pressed(0)
	assert_false(FileAccess.file_exists(POINTER_PATH))

func test_resume_with_empty_state_data_starts_the_given_chapter_fresh():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.resume("chapter_01_teginabad", {})
	assert_eq(chapter_view.chapter_id, "chapter_01_teginabad")
	assert_eq(chapter_view.reputation_tracker.to_dict(), {})

func test_resume_restores_reputation_ledger_and_flags_before_loading_the_chapter():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.resume("chapter_01_teginabad", {
		"reputation_data": {"test_faction": 5},
		"ledger_data": {"purse": [], "debts": [], "spent_dirham_equivalent": -7.0},
		"dialogue_flags": {"test_flag": true},
	})
	assert_eq(chapter_view.reputation_tracker.get_reputation("test_faction"), 5)
	assert_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 7.0)
	assert_true(chapter_view.dialogue_engine.flags.get("test_flag", false))
