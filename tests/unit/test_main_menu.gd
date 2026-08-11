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
