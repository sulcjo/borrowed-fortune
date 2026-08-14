extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_04a_herat/herat.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n21_departure_herat"])

func test_the_terminal_node_now_points_at_chapter_6():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n21_departure_herat":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_06_pushang")

func test_every_glossed_term_id_exists_in_the_herat_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/herat_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_choosing_the_bazaar_directly_skips_the_sideroad():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Head straight for the bazaar." -> n05 directly
	assert_eq(engine.current_node()["id"], "n05_the_bazaar_of_herat")

func test_choosing_the_garrison_gate_visits_the_old_soldier_then_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Let the garrison gate draw you first." -> n03a
	assert_eq(engine.current_node()["id"], "n03a_the_old_soldier")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_1020_muster")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_the_bazaar_of_herat", "the sideroad must converge on the same node the direct-to-bazaar choice reaches")

func test_asking_about_the_mints_delay_sets_a_flag_and_reaches_ardashir():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Head straight for the bazaar." -> n05
	assert_eq(engine.current_node()["id"], "n05_the_bazaar_of_herat")
	engine.choose(0) # n05 -> n05b
	assert_eq(engine.current_node()["id"], "n05b_the_mint_of_herat")
	var effects := engine.choose(0) # "Ask what's holding up the line."
	assert_eq(effects["flags"], ["asked_about_the_mints_delay"])
	assert_eq(engine.current_node()["id"], "n05c_what_the_line_knows")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n06_ardashir_introduced")
	assert_true(engine.flags.get("asked_about_the_mints_delay", false))

func test_moving_on_from_the_mint_reaches_ardashir_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Head straight for the bazaar." -> n05
	engine.choose(0) # n05 -> n05b
	assert_eq(engine.current_node()["id"], "n05b_the_mint_of_herat")
	var effects := engine.choose(1) # "It's not your business today. Move on."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n06_ardashir_introduced")
	assert_false(engine.flags.get("asked_about_the_mints_delay", false))

func test_the_first_haggles_fair_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(8):
		engine.choose(0) # n01 -> n02 -> n03a -> n04a -> n05 -> n06 -> n07
	assert_eq(engine.current_node()["id"], "n07_the_exchange_rate")
	var effects := engine.choose(0) # "Accept his rate."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 10.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n08a_accepted_the_rate")

func test_the_first_haggles_push_too_far_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(8):
		engine.choose(0)
	engine.choose(1) # "Argue the discount." -> n08b
	assert_eq(engine.current_node()["id"], "n08b_argued_the_discount")
	var effects := engine.choose(1) # "Push further." -> n09
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 5.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(engine.current_node()["id"], "n09_grudging_exchange")

func test_the_first_haggles_backing_off_reaches_the_same_node_as_accepting():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(8):
		engine.choose(0)
	engine.choose(1) # argue -> n08b
	engine.choose(0) # "Back off, accept his rate." -> n08a
	assert_eq(engine.current_node()["id"], "n08a_accepted_the_rate")

func test_the_first_haggles_walk_away_path_has_no_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(8):
		engine.choose(0)
	var effects := engine.choose(2) # "Walk away, keep the old coin."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n08c_kept_the_old_coin")

func test_the_second_haggles_fair_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(11):
		engine.choose(0) # reach n07, accept (0), continue to n10, continue to n11
	assert_eq(engine.current_node()["id"], "n11_the_correspondence")
	var effects := engine.choose(0) # "Pay what he asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 20.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n12a_paid_in_full")

func test_the_second_haggles_push_too_far_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(11):
		engine.choose(0)
	engine.choose(1) # "Try to talk him down." -> n12b
	assert_eq(engine.current_node()["id"], "n12b_haggled_the_fee")
	var effects := engine.choose(1) # "Keep pushing." -> n14
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 10.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), -2)
	assert_eq(engine.current_node()["id"], "n14_pushed_too_far")

func test_the_second_haggles_reduced_fee_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(11):
		engine.choose(0)
	engine.choose(1) # haggle -> n12b
	var effects := engine.choose(0) # "Accept a small reduction." -> n13
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 14.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n13_reduced_fee")

func test_the_second_haggles_decline_path_has_no_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(11):
		engine.choose(0)
	var effects := engine.choose(2) # "Decide you don't need the service."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n12c_declined_the_service")

func test_the_default_path_reaches_the_partial_truth():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(16):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n18_the_moment_of_truth")
	assert_eq(engine.available_choices().size(), 1, "reputation defaults to empty, so the gated choice must be hidden")
	var effects := engine.choose(0) # "Ask him plainly, one merchant to another."
	assert_eq(effects["flags"], ["partial_network_reveal"])
	assert_eq(engine.current_node()["id"], "n19a_the_partial_truth")
	engine.choose(0) # continue -> n20
	assert_eq(engine.current_node()["id"], "n20_aftermath")

func test_sufficient_reputation_reveals_the_full_truth_choice():
	var engine := DialogueEngine.new()
	engine.reputation = {"trading_families": 4}
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(16):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n18_the_moment_of_truth")
	assert_eq(engine.available_choices().size(), 2, "reputation >= 4 should reveal the gated choice")
	var effects := engine.choose(1) # "Remind him what you've shown him, fairly, since you arrived."
	assert_eq(effects["flags"], ["full_network_reveal"])
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n19b_the_full_truth")

func test_insufficient_reputation_still_hides_the_gated_choice():
	var engine := DialogueEngine.new()
	engine.reputation = {"trading_families": 3}
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(16):
		engine.choose(0)
	assert_eq(engine.available_choices().size(), 1, "3 < 4, the gated choice must stay hidden")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n21_departure_herat")

func test_aftermath_nodes_do_not_assume_the_gated_full_truth_was_given():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var aftermath_text: String = by_id["n20_aftermath"]["text"]
	var departure_text: String = by_id["n21_departure_herat"]["text"]
	assert_false(aftermath_text.contains("Buyid"), "n20 must read true on the default partial-truth path, which never mentions Buyid")
	assert_false(aftermath_text.contains("missionary"), "n20 must read true on the default partial-truth path, which never mentions a missionary")
	assert_false(departure_text.contains("a name from Rayy"), "n21 must not imply Ardashir gave a specific name, which only happens on the gated full-truth path")

func test_no_node_uses_the_non_standard_demonym():
	var nodes := _load_nodes()
	for node in nodes:
		assert_false(node["text"].contains("Heratigan"), "node %s uses the non-standard demonym 'Heratigan' instead of 'Herati'" % node["id"])

func test_the_muster_and_rayy_dates_are_anchored_to_the_1035_present():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n04a_the_1020_muster"]["text"].contains("fifteen years gone"), "the 1020 muster is fifteen years before the story's 1035 present")
	assert_false(by_id["n04a_the_1020_muster"]["text"].contains("near twenty years"))
	assert_true(by_id["n19b_the_full_truth"]["text"].contains("Six years ago"), "Rayy fell / Majd al-Dawla was deposed in 1029, six years before the story's 1035 present")
	assert_false(by_id["n19b_the_full_truth"]["text"].contains("Nine years ago"))
