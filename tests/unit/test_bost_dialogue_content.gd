extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_02_bost/bost.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n10_departure_bost"])

func test_every_glossed_term_id_exists_in_the_bost_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/bost_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_pressed_path_is_walkable_and_sets_its_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(6):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n07_the_offer")
	var effects := engine.choose(0) # "Ask him plainly."
	assert_eq(effects["flags"], ["pressed_mihran_for_the_name"])
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(int(effects["reputation"]["townsfolk"]), -1)
	engine.choose(0) # n08a_pressed -> continue
	assert_eq(engine.current_node()["id"], "n09_the_palace_glimpsed")
	assert_true(engine.flags.get("pressed_mihran_for_the_name", false))

func test_the_patient_path_is_walkable_and_converges_on_the_same_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(6):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n07_the_offer")
	var effects := engine.choose(1) # "Don't make him say it."
	assert_eq(effects["flags"], ["earned_mihrans_trust"])
	assert_eq(int(effects["reputation"]["trading_families"]), 2)
	engine.choose(0) # n08b_patient -> continue
	assert_eq(engine.current_node()["id"], "n09_the_palace_glimpsed")
	assert_true(engine.flags.get("earned_mihrans_trust", false))

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n10_departure_bost")
