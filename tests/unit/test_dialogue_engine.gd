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
