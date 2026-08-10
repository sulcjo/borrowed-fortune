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
