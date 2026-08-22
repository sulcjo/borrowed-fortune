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

func _engine_at_the_correspondent(token_flag: String) -> DialogueEngine:
	# The bazaar is now one opportunity of three in Merv's stay rather than a stop on
	# a fixed tour, so reaching the correspondent means spending a slot on it.
	var engine := DialogueEngine.new()
	engine.slots = MERV_SLOTS
	if token_flag != "":
		engine.flags[token_flag] = true
	engine.load_tree(_load_nodes(), "n01b_the_stay")
	engine.choose(2)  # "Find the bazaar at the crossing."
	engine.choose(0)  # the bazaar -> the money-changing row
	return engine

func test_the_message_scene_falls_back_to_no_one_waiting_without_the_token_flag():
	var engine := _engine_at_the_correspondent("")
	assert_eq(engine.current_node()["id"], "n04_a_network_reaching_far")
	assert_eq(engine.available_choices().size(), 1, "without the token flag, only the no-one-waiting fallback should be visible")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05b_word_for_no_one_waiting", "the fallback must not depend on having declined the token specifically - it's the safe default for any other state")

func test_carrying_the_token_reaches_the_bahrams_household_framing():
	var engine := _engine_at_the_correspondent("carries_the_commanders_token")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05a_word_for_bahrams_household")
	var effects := engine.choose(0) # "Pay what she asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 8.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(effects["flags"], ["warned_bahrams_household"])
	assert_eq(engine.current_node()["id"], "n06a_word_sent")

func test_having_declined_the_token_reaches_the_no_one_waiting_framing():
	var engine := _engine_at_the_correspondent("declined_the_commanders_charge")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05b_word_for_no_one_waiting")
	var effects := engine.choose(0) # "Pay what she asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 8.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(effects.get("flags", []), [], "declining Bahram's token means there's no household left to warn")
	assert_eq(engine.current_node()["id"], "n06a_word_sent")

func test_the_haggle_choice_sets_the_warned_flag_only_on_the_bahram_path():
	var engine := _engine_at_the_correspondent("carries_the_commanders_token")
	engine.choose(0)
	var effects := engine.choose(1) # "Try to talk her down."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 5.0, 0.0001)
	assert_eq(effects["flags"], ["warned_bahrams_household"])
	assert_eq(engine.current_node()["id"], "n06b_word_sent_cheaper")

func test_the_decline_choice_on_the_bahram_path_reaches_its_own_terminal_flavor():
	var engine := _engine_at_the_correspondent("carries_the_commanders_token")
	engine.choose(0)
	var effects := engine.choose(2) # "Decide the word can wait. Keep the coin."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n06c_word_unsent_bahram")

func test_the_decline_choice_on_the_no_one_waiting_path_reaches_its_own_terminal_flavor():
	var engine := _engine_at_the_correspondent("declined_the_commanders_charge")
	engine.choose(0)
	var effects := engine.choose(2) # "Decide the word can wait. Keep the coin."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n06c_word_unsent_no_one")

const MERV_SLOTS := ["the afternoon he arrived", "the next morning"]

func _hub_engine() -> DialogueEngine:
	# Merv's slots live in the real manifest; a content test driving the engine
	# directly has to supply them, so there is a test below pinning the manifest too.
	var engine := DialogueEngine.new()
	engine.slots = MERV_SLOTS
	engine.load_tree(_load_nodes(), "n01b_the_stay")
	return engine

func test_the_manifest_gives_merv_two_named_slots():
	var file := FileAccess.open("res://content/chapters/manifest.json", FileAccess.READ)
	var manifest = JSON.parse_string(file.get_as_text())
	file.close()
	var stay: Dictionary = manifest["chapter_07b_merv"].get("stay", {})
	assert_eq(stay.get("slots", []).size(), 2)
	assert_eq(str(stay["slots"][0]), MERV_SLOTS[0])

func test_merv_declares_exactly_one_stay_hub():
	var hubs := 0
	for node in _load_nodes():
		if node.get("stay_hub", false):
			hubs += 1
	assert_eq(hubs, 1)

func test_the_stay_offers_three_things_and_no_way_out_yet():
	var engine := _hub_engine()
	var choices := engine.available_choices()
	assert_eq(choices.size(), 3, "three opportunities, the road not yet among them")
	for choice in choices:
		assert_true(choice.get("spends_slot", false), "every opportunity must cost time")

func test_taking_an_opportunity_spends_a_slot_and_retires_it():
	var engine := _hub_engine()
	engine.choose(0)
	assert_eq(engine.slot_index, 1)
	while engine.current_node()["id"] != "n01b_the_stay":
		engine.choose(0)
	assert_eq(engine.available_choices().size(), 2, "the one just taken is gone")

func test_the_road_west_opens_only_once_both_slots_are_spent():
	var engine := _hub_engine()
	engine.choose(0)
	while engine.current_node()["id"] != "n01b_the_stay":
		engine.choose(0)
	for choice in engine.available_choices():
		assert_ne(choice["next_id"], "n06d_the_last_stretch", "one slot left; the road must wait")

	engine.choose(0)
	while engine.current_node()["id"] != "n01b_the_stay":
		engine.choose(0)
	var exits := 0
	for choice in engine.available_choices():
		if choice["next_id"] == "n06d_the_last_stretch":
			exits += 1
	assert_eq(exits, 1, "with the stay spent, only the road remains")
	assert_eq(engine.available_choices().size(), 1)

func test_the_thing_there_was_no_time_for_is_recorded():
	# Two slots against three opportunities, so one is always declined. Taking the
	# first two leaves the bazaar untouched.
	var engine := _hub_engine()
	engine.choose(0)
	while engine.current_node()["id"] != "n01b_the_stay":
		engine.choose(0)
	engine.choose(0)
	while engine.current_node()["id"] != "n01b_the_stay":
		engine.choose(0)
	assert_true(engine.flags.get("never_reached_mervs_bazaar", false),
		"the bazaar was never reached and must be recorded as such")
	assert_false(engine.flags.get("never_walked_mervs_old_quarter", false))
	assert_false(engine.flags.get("never_saw_mervs_new_canal", false))

func test_skipping_the_bazaar_means_bahrams_household_is_never_warned():
	# The real cost of the stay: warned_bahrams_household is read in Nishapur, and
	# spending both slots elsewhere means it is never set at all.
	var engine := _hub_engine()
	engine.flags["carries_the_commanders_token"] = true
	engine.choose(0)
	while engine.current_node()["id"] != "n01b_the_stay":
		engine.choose(0)
	engine.choose(0)
	while engine.current_node()["id"] != "n01b_the_stay":
		engine.choose(0)
	assert_false(engine.flags.get("warned_bahrams_household", false))

func test_spending_a_slot_on_the_bazaar_still_reaches_the_correspondent():
	var engine := _hub_engine()
	engine.flags["carries_the_commanders_token"] = true
	# The bazaar is the third opportunity offered.
	engine.choose(2)
	assert_eq(engine.current_node()["id"], "n03_the_bazaar_at_the_crossing")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04_a_network_reaching_far")
	engine.choose(0)  # the token-gated Bahram framing
	assert_eq(engine.current_node()["id"], "n05a_word_for_bahrams_household")
	engine.choose(0)  # pay what she asks
	assert_true(engine.flags.get("warned_bahrams_household", false))
	# and the branch returns to the stay rather than running on to the road
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n01b_the_stay")

func test_the_full_tree_is_walkable_from_start_to_end_carrying_the_token():
	var engine := DialogueEngine.new()
	engine.slots = MERV_SLOTS
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	engine.flags["carries_the_commanders_token"] = true
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end(), "the chapter must still reach an end")
	assert_eq(engine.current_node()["id"], "n07_departure_merv")

func test_the_full_tree_is_walkable_from_start_to_end_having_declined_the_token():
	var engine := DialogueEngine.new()
	engine.slots = MERV_SLOTS
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	engine.flags["declined_the_commanders_charge"] = true
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n07_departure_merv")
