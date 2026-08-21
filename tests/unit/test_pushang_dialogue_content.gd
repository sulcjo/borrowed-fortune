extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_06_pushang/pushang.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n12_departure_pushang"])

func test_the_terminal_node_now_points_at_chapter_7():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n12_departure_pushang":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_07_sarakhs")

func test_every_glossed_term_id_exists_in_the_pushang_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/pushang_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])
		# Variant prose is only shown on some histories, so an unknown term in one
		# would otherwise surface as a silently missing margin note rather than a
		# test failure.
		for variant in node.get("text_variants", []):
			for term_id in GlossedTextParser.extract_term_ids(variant["text"]):
				assert_true(glossary_data.has(term_id),
					"node %s variant glosses unknown term '%s'" % [node["id"], term_id])

func test_the_comply_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(11):
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05 -> n06 -> n06b -> n07 -> n08 -> n08b -> n08c -> n09
	assert_eq(engine.current_node()["id"], "n09_the_officers_demand")
	var effects := engine.choose(0) # "Pay what he asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 12.0, 0.0001)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
	assert_eq(engine.current_node()["id"], "n10a_complied")

func test_the_haggle_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(11):
		engine.choose(0)
	var effects := engine.choose(1) # "Argue him down to something smaller."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 6.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n10b_haggled")

func test_the_refuse_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(11):
		engine.choose(0)
	var effects := engine.choose(2) # "Refuse outright."
	assert_eq(effects.get("coin_spent_dirham_equivalent", 0.0), 0.0)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), -2)
	assert_eq(engine.current_node()["id"], "n10c_refused")

func test_the_bribe_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(11):
		engine.choose(0)
	var effects := engine.choose(3) # "Offer him something quieter, off the list."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 10.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), -1)
	assert_eq(engine.current_node()["id"], "n10d_bribed")

func test_the_merchants_reasoning_beat_offers_a_reaction_choice_and_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(5):
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05 -> n06
	assert_eq(engine.current_node()["id"], "n06_two_names_one_people")
	engine.choose(0) # continue -> n06b
	assert_eq(engine.current_node()["id"], "n06b_the_merchants_reasoning")
	var effects := engine.choose(0) # "Tell him you understand the calculation."
	assert_eq(int(effects["reputation"]["townsfolk"]), 1)
	assert_eq(engine.current_node()["id"], "n07_the_garrison_gate")

func test_saying_nothing_to_the_merchant_has_no_effects_and_still_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(6):
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05 -> n06 -> n06b
	assert_eq(engine.current_node()["id"], "n06b_the_merchants_reasoning")
	var effects := engine.choose(1) # "Say nothing. It isn't your business to comment on."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n07_the_garrison_gate")

func test_asking_about_the_khutba_sets_a_flag_and_reaches_the_officers_demand():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n08b_the_khutba")
	var effects := engine.choose(0) # "Ask a passerby if the khutba's always this exact."
	assert_eq(effects["flags"], ["asked_about_the_khutba"])
	assert_eq(engine.current_node()["id"], "n08c_the_passerbys_answer")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n09_the_officers_demand")
	assert_true(engine.flags.get("asked_about_the_khutba", false))

func test_noticing_the_khutba_silently_reaches_the_officers_demand_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n08b_the_khutba")
	var effects := engine.choose(1) # "Notice how practiced the words sound, and say nothing."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n09_the_officers_demand")
	assert_false(engine.flags.get("asked_about_the_khutba", false))

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n12_departure_pushang")

func test_the_gate_officer_reads_differently_if_farrukh_bribed_at_teginabad():
	# Teginabad's inspection fork (bribe vs let it happen, five chapters back) reaches
	# this beat. Conditional text is invisible in the node graph, so without this test
	# the thread can be silently removed by an unrelated edit.
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n09_the_officers_demand")
	var neutral := engine.current_text()

	engine.flags["bribed_teginabad_official"] = true
	var bribed := engine.current_text()
	assert_ne(bribed, neutral, "the bribe at Teginabad must change this beat")

	engine.flags.erase("bribed_teginabad_official")
	engine.flags["honest_at_teginabad"] = true
	var honest := engine.current_text()
	assert_ne(honest, neutral, "the honest declaration at Teginabad must change this beat")
	assert_ne(honest, bribed, "the two histories must not read the same")

func test_the_gate_officer_keeps_its_four_choices_on_every_history():
	# A variant changes what a moment means, never what happens next.
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n09_the_officers_demand")
	assert_eq(engine.available_choices().size(), 4)
	engine.flags["bribed_teginabad_official"] = true
	assert_eq(engine.available_choices().size(), 4)
	engine.flags.erase("bribed_teginabad_official")
	engine.flags["honest_at_teginabad"] = true
	assert_eq(engine.available_choices().size(), 4)
