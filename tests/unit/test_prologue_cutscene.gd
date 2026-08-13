extends GutTest

const PrologueCutsceneScript := preload("res://scenes/prologue_cutscene/PrologueCutscene.gd")
const PrologueCutsceneScene := preload("res://scenes/prologue_cutscene/PrologueCutscene.tscn")

func test_compute_panel_duration_seconds_clamps_short_captions_to_the_minimum():
	var short_caption := "Word word word."
	assert_almost_eq(PrologueCutsceneScript.compute_panel_duration_seconds(short_caption), 4.0, 0.0001)

func test_compute_panel_duration_seconds_clamps_long_captions_to_the_maximum():
	var words: Array[String] = []
	for i in range(50):
		words.append("word")
	var long_caption := " ".join(words)
	assert_almost_eq(PrologueCutsceneScript.compute_panel_duration_seconds(long_caption), 12.0, 0.0001)

func test_compute_panel_duration_seconds_scales_with_word_count_in_between():
	var words: Array[String] = []
	for i in range(24):
		words.append("word")
	var mid_caption := " ".join(words)
	assert_almost_eq(PrologueCutsceneScript.compute_panel_duration_seconds(mid_caption), 8.0, 0.0001)

func test_displaying_panel_data_sets_the_caption_and_starts_the_advance_timer():
	var cutscene = add_child_autofree(PrologueCutsceneScene.instantiate())
	var words: Array[String] = []
	for i in range(12):
		words.append("word")
	var caption := " ".join(words)
	cutscene._display_panel_data({"image_path": "res://this_fixture_path_does_not_need_to_exist.png", "caption": caption})
	assert_eq(cutscene.caption_label.get_parsed_text(), caption)
	assert_almost_eq(cutscene._advance_timer.wait_time, 4.0, 0.0001)

func test_prologue_intro_content_has_eleven_panels_each_with_a_caption_and_image_path():
	var file := FileAccess.open("res://content/cutscenes/prologue_intro.json", FileAccess.READ)
	var panels = JSON.parse_string(file.get_as_text())
	file.close()
	assert_eq(panels.size(), 11)
	for i in range(panels.size()):
		var panel: Dictionary = panels[i]
		assert_true(panel.get("caption", "").length() > 0, "panel %d must have a non-empty caption" % i)
		assert_eq(panel.get("image_path", ""), "res://assets/cutscenes/prologue_intro_%02d.png" % (i + 1))
