extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_07b_merv/merv.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n07_departure_merv"])

func test_the_terminal_node_points_at_chapter_8():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n07_departure_merv":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_08_nishapur")

func test_every_glossed_term_id_exists_in_the_merv_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/merv_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	var checked := 0
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])
			checked += 1
	assert_eq(checked, 0, "Merv currently glosses no terms at all - if this fails, a glossed term was added; bump this count instead of deleting the assertion")

func test_the_message_scene_falls_back_to_no_one_waiting_without_the_token_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(4):
		engine.choose(0) # n01 -> n02 -> n02b -> n03 -> n04
	assert_eq(engine.current_node()["id"], "n04_a_network_reaching_far")
	assert_eq(engine.available_choices().size(), 1, "without the token flag, only the no-one-waiting fallback should be visible")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05b_word_for_no_one_waiting", "the fallback must not depend on having declined the token specifically - it's the safe default for any other state")

func test_carrying_the_token_reaches_the_bahrams_household_framing():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(5):
		engine.choose(0) # n01 -> n02 -> n02b -> n03 -> n04 -> n05a
	assert_eq(engine.current_node()["id"], "n05a_word_for_bahrams_household")
	var effects := engine.choose(0) # "Pay what she asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 8.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(effects["flags"], ["warned_bahrams_household"])
	assert_eq(engine.current_node()["id"], "n06a_word_sent")

func test_having_declined_the_token_reaches_the_no_one_waiting_framing():
	var engine := DialogueEngine.new()
	engine.flags["declined_the_commanders_charge"] = true
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(5):
		engine.choose(0) # n01 -> n02 -> n02b -> n03 -> n04 -> n05b
	assert_eq(engine.current_node()["id"], "n05b_word_for_no_one_waiting")
	var effects := engine.choose(0) # "Pay what she asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 8.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(effects.get("flags", []), [], "declining Bahram's token means there's no household left to warn")
	assert_eq(engine.current_node()["id"], "n06a_word_sent")

func test_the_haggle_choice_sets_the_warned_flag_only_on_the_bahram_path():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(5):
		engine.choose(0)
	var effects := engine.choose(1) # "Try to talk her down."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 5.0, 0.0001)
	assert_eq(effects["flags"], ["warned_bahrams_household"])
	assert_eq(engine.current_node()["id"], "n06b_word_sent_cheaper")

func test_the_decline_choice_on_the_bahram_path_reaches_its_own_terminal_flavor():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(5):
		engine.choose(0)
	var effects := engine.choose(2) # "Decide the word can wait. Keep the coin."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n06c_word_unsent_bahram")

func test_the_decline_choice_on_the_no_one_waiting_path_reaches_its_own_terminal_flavor():
	var engine := DialogueEngine.new()
	engine.flags["declined_the_commanders_charge"] = true
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(5):
		engine.choose(0)
	var effects := engine.choose(2) # "Decide the word can wait. Keep the coin."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n06c_word_unsent_no_one")

func test_the_full_tree_is_walkable_from_start_to_end_carrying_the_token():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n07_departure_merv")

func test_the_full_tree_is_walkable_from_start_to_end_having_declined_the_token():
	var engine := DialogueEngine.new()
	engine.flags["declined_the_commanders_charge"] = true
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n07_departure_merv")
