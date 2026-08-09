extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_04b_herat_favor/herat_favor.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n17a_departure_bound", "n17b_departure_free"])

func test_both_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n17a_departure_bound"].has("next_chapter_id"))
	assert_eq(by_id["n17a_departure_bound"]["next_chapter_id"], null)
	assert_true(by_id["n17b_departure_free"].has("next_chapter_id"))
	assert_eq(by_id["n17b_departure_free"]["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_herat_favor_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/herat_favor_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_choosing_rostam_directly_skips_the_sideroad():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Find Rostam without delay." -> n05 directly
	assert_eq(engine.current_node()["id"], "n05_the_far_edge_of_herat")

func test_choosing_the_mint_visits_the_sideroad_then_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "The mint draws your eye first." -> n03a
	assert_eq(engine.current_node()["id"], "n03a_the_mint_at_work")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_debasement")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_the_far_edge_of_herat", "the sideroad must converge on the same node the direct choice reaches")

func test_the_payment_negotiations_insist_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0) # n01 -> n02 -> n03a -> n04a -> n05 -> n06 -> n07 -> n08
	assert_eq(engine.current_node()["id"], "n08_the_price_of_a_favor")
	var effects := engine.choose(0) # "Insist on the price you agreed."
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 15.0, 0.0001)
	assert_eq(int(effects["reputation"]["hidden_network"]), 1)
	assert_eq(engine.current_node()["id"], "n09a_paid_as_agreed")

func test_the_payment_negotiations_push_too_far_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0)
	engine.choose(1) # "Push for more - he owes you for the risk." -> n09b
	assert_eq(engine.current_node()["id"], "n09b_pushing_for_more")
	var effects := engine.choose(1) # "Keep pushing." -> n10
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 20.0, 0.0001)
	assert_eq(int(effects["reputation"]["hidden_network"]), -1)
	assert_eq(engine.current_node()["id"], "n10_extracted_more")

func test_the_payment_negotiations_backing_off_reaches_the_same_node_as_insisting():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0)
	engine.choose(1) # push -> n09b
	var effects := engine.choose(0) # "Back off. His agreed price is fine." -> n09a
	assert_eq(engine.current_node()["id"], "n09a_paid_as_agreed")
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 15.0, 0.0001, "backing off to the agreed price must pay the same as insisting on it up front")
	assert_eq(int(effects["reputation"]["hidden_network"]), 1)

func test_the_payment_negotiations_passive_path_has_no_reputation_effect():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(7):
		engine.choose(0)
	var effects := engine.choose(2) # "Take whatever he offers. Just be done with it."
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 5.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n09c_took_the_scraps")

func test_the_stay_entangled_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(12):
		engine.choose(0) # reach n14_the_choice via the sideroad + insist-on-price defaults
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(0) # "Agree to keep working with him."
	assert_eq(fork_effects["flags"], ["chose_to_stay_entangled"])
	assert_eq(int(fork_effects["reputation"]["hidden_network"]), 1)
	engine.choose(0) # n15a -> n16a
	engine.choose(0) # n16a -> n17a
	assert_eq(engine.current_node()["id"], "n17a_departure_bound")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_to_stay_entangled", false))

func test_the_pivot_away_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(12):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(1) # "Tell him this ends here."
	assert_eq(fork_effects["flags"], ["chose_to_pivot_away"])
	assert_eq(int(fork_effects["reputation"]["hidden_network"]), -1)
	engine.choose(0) # n15b -> n16b
	engine.choose(0) # n16b -> n17b
	assert_eq(engine.current_node()["id"], "n17b_departure_free")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_to_pivot_away", false))

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n17a_departure_bound")

func test_no_node_mentions_ardashir_or_the_non_standard_demonym():
	var nodes := _load_nodes()
	for node in nodes:
		assert_false(node["text"].contains("Ardashir"), "node %s references Ardashir, a Chapter 4A-exclusive NPC this branch's Farrukh never meets" % node["id"])
		assert_false(node["text"].contains("Heratigan"), "node %s uses the non-standard demonym 'Heratigan' instead of 'Herati'" % node["id"])

func test_the_weight_of_knowing_hedges_rather_than_asserts_the_gated_backstory():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var text: String = by_id["n13_the_weight_of_knowing"]["text"]
	assert_false(text.contains("Mihran had first named"), "must not overclaim what Bost's Mihran actually said - he never names a network, and gives no name at all on the patient path")
	assert_false(text.contains("crucified"), "the Buyid/crucifixion backstory is Chapter 4A's gated reward - 4B must not state it as free, settled fact")
	assert_false(text.contains("nine years ago"))
