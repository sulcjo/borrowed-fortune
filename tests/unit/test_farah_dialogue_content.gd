extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_03_farah/farah.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n18a_departure_farah_mystery", "n19b_departure_farah_plunder"])

func test_both_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n18a_departure_farah_mystery"].has("next_chapter_id"))
	assert_eq(by_id["n18a_departure_farah_mystery"]["next_chapter_id"], null)
	assert_true(by_id["n19b_departure_farah_plunder"].has("next_chapter_id"))
	assert_eq(by_id["n19b_departure_farah_plunder"]["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_farah_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/farah_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_checkpoint_fork_sets_distinct_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04_the_choice_at_the_checkpoint")
	var vouch_effects := engine.choose(0) # "Tell him they're traveling with you."
	assert_eq(vouch_effects["flags"], ["vouched_for_the_family_at_farah"])
	assert_eq(int(vouch_effects["reputation"]["townsfolk"]), 2)
	assert_eq(int(vouch_effects["reputation"]["ghaznavid_officials"]), -1)

func test_the_checkpoint_forks_other_branch_sets_its_own_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	var uninvolved_effects := engine.choose(1) # "Say nothing. It isn't your caravan to risk."
	assert_eq(uninvolved_effects["flags"], ["stayed_uninvolved_at_farah"])
	assert_eq(int(uninvolved_effects["reputation"]["ghaznavid_officials"]), 1)

func test_the_family_again_bonus_is_available_when_vouched():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(11):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_the_common_room")
	assert_eq(engine.available_choices().size(), 2, "the family-again bonus should be visible because index 0 at the checkpoint choice vouches for the family")

func test_the_family_again_bonus_is_hidden_when_uninvolved():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	engine.choose(1) # "Say nothing. It isn't your caravan to risk." - does not set the vouched flag
	for i in range(7):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_the_common_room")
	assert_eq(engine.available_choices().size(), 1, "the family-again bonus should be hidden because the family was never vouched for")

func test_the_price_of_a_bed_fork_carries_coin_spent_and_reputation_differently():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_price_of_a_bed")
	var paid_full_effects := engine.choose(0) # "Pay what she asks."
	assert_almost_eq(float(paid_full_effects["coin_spent_dirham_equivalent"]), 15.0, 0.0001)
	assert_eq(int(paid_full_effects["reputation"]["trading_families"]), 1)

func test_the_haggle_branch_costs_less_coin_and_no_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(9):
		engine.choose(0)
	var haggled_effects := engine.choose(1) # "Haggle her down."
	assert_almost_eq(float(haggled_effects["coin_spent_dirham_equivalent"]), 6.0, 0.0001)
	assert_eq(haggled_effects.get("reputation", {}), {})

func test_the_name_already_known_bonus_is_gated_on_the_bost_pressed_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(13):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice", "without the flag, index 0 at n13 should always skip straight past the bonus")

func test_the_name_already_known_bonus_is_visible_when_the_flag_is_set():
	var engine := DialogueEngine.new()
	engine.flags["pressed_mihran_for_the_name"] = true
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(12):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n13_two_doors")
	assert_eq(engine.available_choices().size(), 2, "the name-already-known bonus should be visible because pressed_mihran_for_the_name is set")

func test_the_mystery_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(13):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(0) # "Go to Umm-Kavus's channel."
	assert_eq(fork_effects["flags"], ["chose_umm_kavus_channel"])
	assert_eq(int(fork_effects["reputation"]["trading_families"]), 1)
	engine.choose(0) # n15a_umm_kavus_channel -> continue
	engine.choose(0) # n16a_the_wait -> continue
	var name_effects := engine.choose(0) # n17a_the_name_given_cleanly -> continue
	assert_eq(name_effects["flags"], ["knows_the_second_marks_name"])
	assert_eq(int(name_effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n18a_departure_farah_mystery")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_umm_kavus_channel", false))
	assert_true(engine.flags.get("knows_the_second_marks_name", false))

func test_the_plunder_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(13):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(1) # "Seek out Tahir."
	assert_eq(fork_effects["flags"], ["chose_tahirs_price"])
	assert_eq(int(fork_effects["reputation"]["trading_families"]), -1)
	engine.choose(0) # n15b_finding_tahir -> continue
	engine.choose(0) # n16b_tahirs_price -> continue
	engine.choose(0) # n17b_the_war_he_carries -> continue
	var favor_effects := engine.choose(0) # n18b_the_favor_owed -> continue
	assert_eq(favor_effects["flags"], ["knows_the_second_marks_name", "owes_tahir_a_favor"])
	assert_eq(int(favor_effects["reputation"]["townsfolk"]), -1)
	assert_eq(engine.current_node()["id"], "n19b_departure_farah_plunder")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_tahirs_price", false))
	assert_true(engine.flags.get("owes_tahir_a_favor", false))

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n18a_departure_farah_mystery")
