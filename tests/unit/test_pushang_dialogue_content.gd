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

func test_the_terminal_node_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n12_departure_pushang":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_pushang_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/pushang_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_comply_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05 -> n06 -> n07 -> n08 -> n09
	assert_eq(engine.current_node()["id"], "n09_the_officers_demand")
	var effects := engine.choose(0) # "Pay what he asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 12.0, 0.0001)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
	assert_eq(engine.current_node()["id"], "n10a_complied")

func test_the_haggle_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	var effects := engine.choose(1) # "Argue him down to something smaller."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 6.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n10b_haggled")

func test_the_refuse_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	var effects := engine.choose(2) # "Refuse outright."
	assert_eq(effects.get("coin_spent_dirham_equivalent", 0.0), 0.0)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), -2)
	assert_eq(engine.current_node()["id"], "n10c_refused")

func test_the_bribe_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	var effects := engine.choose(3) # "Offer him something quieter, off the list."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 10.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), -1)
	assert_eq(engine.current_node()["id"], "n10d_bribed")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n12_departure_pushang")
