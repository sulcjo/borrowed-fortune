extends GutTest

# Yusuf is the game's only recurring NPC, appearing in Teginabad, Bost and Sarakhs.
# His three appearances used to be one "Continue." each: three cameos and no arc.
# They are now three decisions whose consequences reach the later two, and this file
# is the only place that can test that, because the arc spans three chapters.

const TEGINABAD := "res://content/chapters/chapter_01_teginabad/teginabad.json"
const BOST := "res://content/chapters/chapter_02_bost/bost.json"
const SARAKHS := "res://content/chapters/chapter_07_sarakhs/sarakhs.json"

func _nodes(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func _text_at(path: String, node_id: String, flags: Dictionary) -> String:
	var engine := DialogueEngine.new()
	engine.flags = flags
	engine.load_tree(_nodes(path), node_id)
	return engine.current_text()

func test_meeting_yusuf_is_a_decision_not_a_continue():
	var engine := DialogueEngine.new()
	engine.load_tree(_nodes(TEGINABAD), "n11d_yusuf_at_teginabad")
	assert_eq(engine.available_choices().size(), 2,
		"the first meeting must offer a way to answer him, not just a Continue")

func test_both_first_meeting_answers_converge_without_adding_nodes():
	# The whole point: more possibility, not more prose. Both answers lead to the same
	# next node, so decision density rises and node count does not.
	var engine := DialogueEngine.new()
	engine.load_tree(_nodes(TEGINABAD), "n11d_yusuf_at_teginabad")
	var targets := {}
	for choice in engine.available_choices():
		targets[choice["next_id"]] = true
	assert_eq(targets.size(), 1, "both answers must rejoin the same beat")
	assert_true(targets.has("n11c_the_desert_crossing"))

func test_the_second_meeting_reads_differently_for_each_first_answer():
	var neutral := _text_at(BOST, "n09c_yusuf_at_bost", {})
	var told := _text_at(BOST, "n09c_yusuf_at_bost", {"told_yusuf_his_errand": true})
	var withheld := _text_at(BOST, "n09c_yusuf_at_bost", {"matched_yusufs_reticence": true})
	assert_ne(told, neutral, "having told him must reach Bost")
	assert_ne(withheld, neutral, "having withheld must reach Bost too")
	assert_ne(told, withheld, "the two histories must not read the same")

func test_the_second_meeting_is_also_a_decision():
	var engine := DialogueEngine.new()
	engine.load_tree(_nodes(BOST), "n09c_yusuf_at_bost")
	assert_eq(engine.available_choices().size(), 2)
	var targets := {}
	for choice in engine.available_choices():
		targets[choice["next_id"]] = true
	assert_eq(targets.size(), 1, "both answers must rejoin the same beat")

func test_the_farewell_reads_differently_for_each_second_answer():
	# Five chapters after Bost, and on the far side of a branch point.
	var neutral := _text_at(SARAKHS, "n10e_yusufs_farewell", {})
	var pressed := _text_at(SARAKHS, "n10e_yusufs_farewell", {"pressed_yusuf_on_his_uncle": true})
	var let_be := _text_at(SARAKHS, "n10e_yusufs_farewell", {"let_yusuf_keep_his_business": true})
	assert_ne(pressed, neutral, "having pressed him must reach Sarakhs")
	assert_ne(let_be, neutral, "having let it go must reach Sarakhs")
	assert_ne(pressed, let_be, "the two histories must not read the same")

func test_the_farewell_is_a_decision_with_no_downstream_flags():
	# Deliberately sets nothing: it is the last time Yusuf appears, so a flag here
	# would be recorded and never read - dead state the ratchet would rightly flag.
	var engine := DialogueEngine.new()
	engine.load_tree(_nodes(SARAKHS), "n10e_yusufs_farewell")
	var choices := engine.available_choices()
	assert_eq(choices.size(), 2)
	for choice in choices:
		assert_eq(choice.get("effects", {}).get("flags", []), [],
			"the farewell must not create state nothing can read")

func test_every_yusuf_appearance_still_names_him():
	for path in [TEGINABAD, BOST, SARAKHS]:
		var found := false
		for node in _nodes(path):
			if "Yusuf" in JSON.stringify(node):
				found = true
		assert_true(found, "Yusuf should still appear in %s" % path)
