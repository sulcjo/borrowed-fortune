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

func test_resume_restores_a_non_empty_purse_and_debt_through_a_real_json_round_trip():
	# Ledger.load_from_dict() reconstructs Coin/Debt objects via Coin.from_dict()/
	# Debt.from_dict() - unlike reputation (coerced back to int by
	# get_reputation()'s own -> int return type) or flags (a plain Dictionary),
	# a Coin's "metal" field is a typed int enum fed by a value that has been
	# through a real JSON.stringify()/JSON.parse_string() round trip (via the
	# pointer file on disk), which turns every number into a float. This test
	# proves that round trip - not just the in-memory Ledger.to_dict()/
	# load_from_dict() pairing test_ledger.gd already covers - restores the
	# player's wealth and debt correctly, since Continue is exactly this path.
	var writer_chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	var state := GameState.new()
	state.ledger_data = {
		"purse": [{"metal": Coin.Metal.GOLD, "actual_weight_grams": 4.25, "purity": 1.0}],
		"debts": [{"creditor_name": "Ibrahim al-Sarraf", "amount_dirham_equivalent": 340.0, "is_guaranteed_by_kafala": true}],
		"spent_dirham_equivalent": 0.0,
	}
	writer_chapter_view._write_current_chapter_pointer("chapter_02_bost", state)

	var pointer := _read_pointer()
	var reader_chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	reader_chapter_view.resume("chapter_01_teginabad", pointer)

	assert_almost_eq(reader_chapter_view.ledger.total_wealth_dirham_equivalent(), 14.2, 0.0001)
	assert_almost_eq(reader_chapter_view.ledger.total_debt_owed(), 340.0, 0.0001)
