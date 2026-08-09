extends GutTest

func _sample_nodes() -> Array:
	return [
		{
			"id": "n1",
			"text": "Opening beat.",
			"choices": [{"text": "Continue.", "next_id": "n2", "effects": {}}],
		},
		{
			"id": "n2",
			"text": "A real fork.",
			"choices": [
				{"text": "Speak now.", "next_id": "n3a", "effects": {"flags": ["spoke_now"]}},
				{"text": "Wait.", "next_id": "n3b", "effects": {"flags": ["waited"]}},
			],
		},
		{"id": "n3a", "text": "You spoke.", "choices": [{"text": "Continue.", "next_id": "n4", "effects": {}}]},
		{"id": "n3b", "text": "You waited.", "choices": [{"text": "Continue.", "next_id": "n4", "effects": {}}]},
		{
			"id": "n4",
			"text": "A gated option.",
			"choices": [
				{"text": "Always available.", "next_id": "n5", "effects": {}},
				{"text": "Only if you spoke.", "next_id": "n5", "requires_flag": "spoke_now", "effects": {}},
			],
		},
		{"id": "n5", "text": "The end.", "choices": []},
	]

func test_load_tree_sets_current_node_to_start_id():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n1")
	assert_eq(engine.current_node()["id"], "n1")

func test_available_choices_returns_all_ungated_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	assert_eq(engine.available_choices().size(), 2)

func test_choose_moves_to_the_chosen_next_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n3a")

func test_choose_applies_flags_from_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	engine.choose(0)
	assert_true(engine.flags.get("spoke_now", false))

func test_choose_returns_the_chosen_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	var effects := engine.choose(1)
	assert_eq(effects, {"flags": ["waited"]})

func test_choose_with_out_of_range_index_returns_empty_and_does_not_move():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	var effects := engine.choose(99)
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n2")

func test_is_chapter_end_false_when_choices_exist():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n1")
	assert_false(engine.is_chapter_end())

func test_is_chapter_end_true_on_final_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n5")
	assert_true(engine.is_chapter_end())

func test_gated_choice_hidden_until_flag_is_set_then_appears():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	engine.choose(1) # "Wait." -> sets "waited", not "spoke_now" -> n3b
	engine.choose(0) # n3b -> n4
	assert_eq(engine.available_choices().size(), 1) # gated option hidden

	var engine_via_speak := DialogueEngine.new()
	engine_via_speak.load_tree(_sample_nodes(), "n2")
	engine_via_speak.choose(0) # "Speak now." -> sets "spoke_now" -> n3a
	engine_via_speak.choose(0) # n3a -> n4
	assert_eq(engine_via_speak.available_choices().size(), 2) # gated option now visible

func test_validate_tree_flags_duplicate_ids():
	var nodes := [
		{"id": "a", "text": "one", "choices": []},
		{"id": "a", "text": "two", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "duplicate")

func test_validate_tree_flags_dangling_next_id():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "nonexistent"}]},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "dangling")

func test_validate_tree_flags_unparsed_gloss_token():
	var nodes := [
		{"id": "a", "text": "hello {{term_a, term_b|broken}}", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "unparsed gloss")

func test_validate_tree_returns_empty_for_a_valid_graph():
	var nodes := [
		{"id": "a", "text": "hello {{term_a|hi}}", "choices": [{"text": "go", "next_id": "b"}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_eq(errors, [])

func test_reputation_gated_choice_hidden_until_reputation_met():
	var nodes := [
		{
			"id": "n1",
			"text": "A merchant sizes you up.",
			"choices": [
				{"text": "Always available.", "next_id": "n2", "effects": {}},
				{"text": "Invoke your standing.", "next_id": "n2", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}, "effects": {}},
			],
		},
		{"id": "n2", "text": "The end.", "choices": []},
	]
	var engine := DialogueEngine.new()
	engine.load_tree(nodes, "n1")
	assert_eq(engine.available_choices().size(), 1)

	engine.reputation = {"trading_families": 2}
	assert_eq(engine.available_choices().size(), 2)

func test_reputation_gated_choice_uses_at_least_semantics():
	var nodes := [
		{
			"id": "n1",
			"text": "A merchant sizes you up.",
			"choices": [
				{"text": "Invoke your standing.", "next_id": "n2", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}, "effects": {}},
			],
		},
		{"id": "n2", "text": "The end.", "choices": []},
	]
	var engine := DialogueEngine.new()
	engine.load_tree(nodes, "n1")
	engine.reputation = {"trading_families": 5}
	assert_eq(engine.available_choices().size(), 1, "5 >= 2, the choice should be visible")

	engine.reputation = {"trading_families": 1}
	assert_eq(engine.available_choices().size(), 0, "1 < 2, the choice should be hidden")

func test_requires_flag_and_requires_reputation_can_combine():
	var nodes := [
		{
			"id": "n1",
			"text": "Complex gate.",
			"choices": [
				{"text": "Needs both.", "next_id": "n2", "requires_flag": "met_the_merchant", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}, "effects": {}},
			],
		},
		{"id": "n2", "text": "The end.", "choices": []},
	]
	var engine := DialogueEngine.new()
	engine.load_tree(nodes, "n1")
	engine.reputation = {"trading_families": 5}
	assert_eq(engine.available_choices().size(), 0, "flag not set yet, reputation alone isn't enough")

	engine.flags["met_the_merchant"] = true
	assert_eq(engine.available_choices().size(), 1, "both conditions now met")

func test_validate_tree_flags_a_requires_reputation_missing_faction_id():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": {"min_score": 2}}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "requires_reputation")

func test_validate_tree_flags_a_requires_reputation_missing_min_score():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": {"faction_id": "trading_families"}}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "requires_reputation")

func test_validate_tree_flags_a_requires_reputation_that_is_not_a_dictionary():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": "trading_families"}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "requires_reputation")

func test_validate_tree_accepts_a_well_formed_requires_reputation():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_eq(errors, [])
