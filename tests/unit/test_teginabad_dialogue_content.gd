extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_01_teginabad/teginabad.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func test_every_next_id_points_at_a_node_that_exists():
	var nodes := _load_nodes()
	var known_ids: Dictionary = {}
	for node in nodes:
		known_ids[node["id"]] = true
	for node in nodes:
		for choice in node.get("choices", []):
			assert_true(known_ids.has(choice["next_id"]), "%s -> next_id '%s' does not exist" % [node["id"], choice["next_id"]])

func test_exactly_one_node_has_no_choices_and_it_is_the_last_node():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	assert_eq(end_node_ids, ["n09_departure_teginabad"])

func test_every_glossed_term_id_exists_in_the_teginabad_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/teginabad_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_choice")
	var effects := engine.choose(0) # "Pay for expedited passage."
	# NOTE: not a single assert_eq(effects, {...}) — JSON.parse_string() always returns
	# floats for JSON numbers, and Godot's native Dictionary `==` (what assert_eq uses for
	# Dictionary values) requires exact type equality at every nested leaf, so a
	# whole-dict comparison against int literals here would fail regardless of whether the
	# content is correct. Asserting flags and each reputation value individually verifies
	# the identical content without hitting that type-strictness trap.
	assert_eq(effects.size(), 2)
	assert_eq(effects["flags"], ["bribed_teginabad_official"])
	assert_eq(effects["reputation"].size(), 3)
	assert_eq(effects["reputation"]["townsfolk"], -1)
	assert_eq(effects["reputation"]["trading_families"], -1)
	assert_eq(effects["reputation"]["ghaznavid_officials"], 1)
	engine.choose(0) # n07a_bribe -> continue
	assert_eq(engine.current_node()["id"], "n08_guide_transition")
	assert_true(engine.flags.get("bribed_teginabad_official", false))

func test_the_honest_path_is_walkable_and_converges_on_the_same_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_choice")
	var effects := engine.choose(1) # "Let the inspection happen."
	# See NOTE in test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation() above
	# on why this is split instead of one assert_eq(effects, {...}).
	assert_eq(effects.size(), 2)
	assert_eq(effects["flags"], ["honest_at_teginabad"])
	assert_eq(effects["reputation"].size(), 1)
	assert_eq(effects["reputation"]["ghaznavid_officials"], 2)
	engine.choose(0) # n07b_inspection -> "Say nothing."
	assert_eq(engine.current_node()["id"], "n08_guide_transition")
	assert_true(engine.flags.get("honest_at_teginabad", false))

func test_letter_callback_choice_only_appears_with_the_prologue_flag_set():
	var engine_without_flag := DialogueEngine.new()
	engine_without_flag.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine_without_flag.choose(0)
	engine_without_flag.choose(1) # "Let the inspection happen."
	assert_eq(engine_without_flag.available_choices().size(), 1)

	var engine_with_flag := DialogueEngine.new()
	engine_with_flag.load_tree(_load_nodes(), "n01_teginabad_arrival")
	engine_with_flag.flags["read_unsigned_letter"] = true
	for i in range(5):
		engine_with_flag.choose(0)
	engine_with_flag.choose(1)
	assert_eq(engine_with_flag.available_choices().size(), 2)

	var chosen_effects := engine_with_flag.choose(1) # "Tell him what you read..."
	# See NOTE in test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation() above
	# on why this is split instead of one assert_eq(chosen_effects, {...}).
	assert_eq(chosen_effects.size(), 2)
	assert_eq(chosen_effects["flags"], ["revealed_letter_to_said"])
	assert_eq(chosen_effects["reputation"].size(), 1)
	assert_eq(chosen_effects["reputation"]["ghaznavid_officials"], 1)
	engine_with_flag.choose(0) # n07b_letter_callback -> continue
	assert_eq(engine_with_flag.current_node()["id"], "n08_guide_transition")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n09_departure_teginabad")
