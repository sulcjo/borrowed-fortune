extends GutTest

# Nishapur is the game's main ending, and it is the one case where a flag set at the
# final choice has nowhere else to be read: both terminal nodes have nothing after them,
# so the outro is the only thing left that can respond to the choice. That makes these
# assertions the only guard on the ending actually varying - nothing in the node graph
# shows that a cutscene is reading its flags.

const CutsceneScript := preload("res://scenes/cutscene/Cutscene.gd")
const OUTRO_PATH := "res://content/cutscenes/nishapur_outro.json"

const ENDURES := "chose_the_self_that_endures"
const DISSOLVED := "chose_the_self_dissolved"
const KNEW_WHY := "learned_the_fathers_reason"

func _panels() -> Array:
	var file := FileAccess.open(OUTRO_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func _captions(flags: Dictionary) -> Array:
	var result: Array = []
	for panel in CutsceneScript.visible_panels(_panels(), flags):
		result.append(panel["caption"])
	return result

func test_each_ending_gets_a_full_length_sequence():
	# The plunder ending shows six panels. An ending that resolves the whole game in
	# three would read as truncated, so every reachable combination matches it.
	for flags in [
		{ENDURES: true, KNEW_WHY: true},
		{ENDURES: true},
		{DISSOLVED: true, KNEW_WHY: true},
		{DISSOLVED: true},
	]:
		assert_eq(_captions(flags).size(), 6,
			"expected six panels for %s" % [flags])

func test_the_two_selves_end_differently():
	var endures := _captions({ENDURES: true})
	var dissolved := _captions({DISSOLVED: true})
	assert_ne(endures, dissolved, "the final choice must change the outro")
	# Not merely different somewhere - the last thing the player reads must differ.
	assert_ne(endures[endures.size() - 1], dissolved[dissolved.size() - 1],
		"the closing caption must differ between the two endings")

func test_learning_the_fathers_reason_is_answered_either_way():
	# The one flag here that is not the final choice. Both states say something; the
	# absence of the knowledge is itself a line, rather than a missing panel.
	var knew := _captions({ENDURES: true, KNEW_WHY: true})
	var never := _captions({ENDURES: true})
	assert_ne(knew, never, "knowing his father's reason must change the outro")
	assert_eq(knew.size(), never.size(),
		"the two states should be alternatives, not one extra panel")

func test_the_sequence_never_comes_out_empty():
	# A save that failed to load leaves no flags at all. The outro must still play
	# something rather than hang on a black screen with only Skip working.
	assert_gt(_captions({}).size(), 0, "an unflagged outro must still have panels")

func test_every_gated_panel_names_a_flag_the_chapter_can_actually_set():
	var settable := {}
	var file := FileAccess.open("res://content/chapters/chapter_08_nishapur/nishapur.json", FileAccess.READ)
	var nodes = JSON.parse_string(file.get_as_text())
	file.close()
	for node in nodes:
		for choice in node.get("choices", []):
			for flag_name in choice.get("effects", {}).get("flags", []):
				settable[flag_name] = true
	for panel in _panels():
		for key in ["requires_flag", "forbids_flag"]:
			if panel.has(key):
				assert_true(settable.has(panel[key]),
					"outro gates on '%s', which Nishapur never sets" % panel[key])

func test_every_declared_image_exists():
	# A caption-only panel is a deliberate composition; a broken path is not. The two
	# look similar at runtime, so the difference is asserted here instead.
	for panel in _panels():
		if panel.has("image_path"):
			assert_true(ResourceLoader.exists(panel["image_path"]),
				"outro references missing art: %s" % panel["image_path"])
