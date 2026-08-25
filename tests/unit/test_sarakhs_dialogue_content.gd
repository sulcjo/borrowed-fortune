extends GutTest

# Walks use Nav.expect_reaches rather than a hardcoded press count, so adding a beat
# of prose to this chapter does not fail a test that found nothing wrong. See
# tests/helpers/navigation.gd.
const Nav := preload("res://tests/helpers/navigation.gd")

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_07_sarakhs/sarakhs.json", FileAccess.READ)
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

func test_exactly_two_nodes_have_no_choices_and_they_are_the_two_terminal_nodes():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	end_node_ids.sort()
	assert_eq(end_node_ids, ["n11_departure_sarakhs", "n11b_departure_via_merv"])

func test_the_terminal_node_now_points_at_chapter_8():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n11_departure_sarakhs":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_08_nishapur")

func test_every_glossed_term_id_exists_in_the_sarakhs_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/sarakhs_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_choosing_the_yard_visits_the_sideroad_then_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Linger in the garrison's outer yard." -> n03a
	assert_eq(engine.current_node()["id"], "n03a_the_ghulams_road")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_treasurys_long_reach")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04b_a_wife_also_chosen")
	engine.choose(0) # "Ask if it's always arranged that way."
	assert_eq(engine.current_node()["id"], "n04c_what_the_arrangement_makes")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper", "the sideroad must converge on the same node the direct choice reaches")

func test_asking_about_the_arrangement_sets_a_flag_and_reaches_bahram():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Linger in the garrison's outer yard." -> n03a
	engine.choose(0) # n03a -> n04a
	engine.choose(0) # n04a -> n04b
	assert_eq(engine.current_node()["id"], "n04b_a_wife_also_chosen")
	var effects := engine.choose(0) # "Ask if it's always arranged that way."
	assert_eq(effects["flags"], ["learned_of_arranged_ghulam_marriages"])
	assert_eq(engine.current_node()["id"], "n04c_what_the_arrangement_makes")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper")
	assert_true(engine.flags.get("learned_of_arranged_ghulam_marriages", false))

func test_saying_nothing_about_the_arrangement_reaches_bahram_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Linger in the garrison's outer yard." -> n03a
	engine.choose(0) # n03a -> n04a
	engine.choose(0) # n04a -> n04b
	assert_eq(engine.current_node()["id"], "n04b_a_wife_also_chosen")
	var effects := engine.choose(1) # "Say nothing. It's not yours to ask about."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper")
	assert_false(engine.flags.get("learned_of_arranged_ghulam_marriages", false))

func test_choosing_straight_to_the_commander_skips_the_sideroad():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Go straight to whoever commands this gate." -> n05 directly
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper")

func test_the_accept_freely_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad ("Go straight to whoever commands this gate.")
	Nav.expect_reaches(self, engine, "n08_the_commanders_charge")
	var effects := engine.choose(0) # "Take it. Ask for nothing in return."
	assert_eq(effects["flags"], ["carries_the_commanders_token"])
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
	assert_eq(engine.current_node()["id"], "n09a_accepted_freely")

func test_the_accept_for_coin_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	for i in range(3):
		engine.choose(0) # n05 -> n06 -> n07 -> n08
	var effects := engine.choose(1) # "Take it, but only for a fair price."
	assert_eq(effects["flags"], ["carries_the_commanders_token", "accepted_the_charge_for_payment"])
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 12.0, 0.0001)
	assert_eq(engine.current_node()["id"], "n09b_accepted_for_coin")

func test_the_decline_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	for i in range(3):
		engine.choose(0) # n05 -> n06 -> n07 -> n08
	var effects := engine.choose(2) # "Decline. You already carry enough."
	assert_eq(effects["flags"], ["declined_the_commanders_charge"])
	assert_eq(effects.get("coin_gained_dirham_equivalent", 0.0), 0.0)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n09c_declined_plainly")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n11_departure_sarakhs")

func test_the_merv_terminal_node_points_at_the_merv_chapter():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n11b_departure_via_merv":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_07b_merv")

func test_the_road_fork_straight_to_nishapur_reaches_the_unchanged_terminal():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	Nav.expect_reaches(self, engine, "n10b_the_road_forks")
	engine.choose(0) # "Take the road straight to Nishapur."
	assert_eq(engine.current_node()["id"], "n11_departure_sarakhs")
	assert_true(engine.is_chapter_end())

func test_the_road_fork_via_merv_reaches_its_own_terminal():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	Nav.expect_reaches(self, engine, "n10b_the_road_forks")
	engine.choose(1) # "Take the longer road through Merv first."
	Nav.expect_reaches(self, engine, "n11b_departure_via_merv")
	assert_true(engine.is_chapter_end())
