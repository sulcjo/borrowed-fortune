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
