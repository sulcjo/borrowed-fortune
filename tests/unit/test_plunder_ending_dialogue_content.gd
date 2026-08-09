extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_05_plunder_ending/plunder_ending.json", FileAccess.READ)
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

func test_exactly_four_nodes_have_no_choices_and_they_are_the_four_terminal_nodes():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	end_node_ids.sort()
	assert_eq(end_node_ids, ["n06a_departure_bound_believed", "n06a_departure_bound_clear_eyed", "n06b_departure_free_believed", "n06b_departure_free_uncertain"])

func test_all_four_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	for terminal_id in ["n06a_departure_bound_believed", "n06a_departure_bound_clear_eyed", "n06b_departure_free_believed", "n06b_departure_free_uncertain"]:
		assert_true(by_id[terminal_id].has("next_chapter_id"), "%s must carry its own next_chapter_id" % terminal_id)
		assert_eq(by_id[terminal_id]["next_chapter_id"], null, "%s must end the game (this is Chapter 5's own final state, no further chapter exists yet)" % terminal_id)

func test_the_fork_only_shows_the_bound_choice_when_that_flag_is_set():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_stay_entangled"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	engine.choose(0) # n01 -> n02
	assert_eq(engine.available_choices().size(), 1, "only the bound branch's choice should be visible")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n03a_the_shape_of_the_understanding")

func test_the_fork_only_shows_the_free_choice_when_that_flag_is_set():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_pivot_away"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	engine.choose(0)
	assert_eq(engine.available_choices().size(), 1, "only the free branch's choice should be visible")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n03b_the_shape_of_the_refusal")

func test_the_bound_branch_believed_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_stay_entangled"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0) # n01 -> n02 -> n03a -> n04a -> n05a
	assert_eq(engine.current_node()["id"], "n05a_the_lie_he_might_tell")
	var effects := engine.choose(0) # "Tell yourself it was only ever going to be one more errand."
	assert_eq(effects["flags"], ["chose_to_believe_the_lie"])
	assert_eq(engine.current_node()["id"], "n06a_departure_bound_believed")
	assert_true(engine.is_chapter_end())

func test_the_bound_branch_clear_eyed_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_stay_entangled"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0)
	var effects := engine.choose(1) # "Admit, at least to yourself, what you've actually become."
	assert_eq(effects["flags"], ["chose_to_see_clearly"])
	assert_eq(engine.current_node()["id"], "n06a_departure_bound_clear_eyed")
	assert_true(engine.is_chapter_end())

func test_the_free_branch_believed_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_pivot_away"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0) # n01 -> n02 -> n03b -> n04b -> n05b
	assert_eq(engine.current_node()["id"], "n05b_the_bet_he_could_not_confirm")
	var effects := engine.choose(0) # "Let yourself believe the danger has passed."
	assert_eq(effects["flags"], ["chose_to_believe_the_danger_passed"])
	assert_eq(engine.current_node()["id"], "n06b_departure_free_believed")
	assert_true(engine.is_chapter_end())

func test_the_free_branch_uncertain_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_pivot_away"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0)
	var effects := engine.choose(1) # "Accept that you may never know if it has."
	assert_eq(effects["flags"], ["chose_to_accept_uncertainty"])
	assert_eq(engine.current_node()["id"], "n06b_departure_free_uncertain")
	assert_true(engine.is_chapter_end())
