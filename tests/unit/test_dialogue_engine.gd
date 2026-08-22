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

func test_conditions_met_accepts_a_holder_with_no_conditions():
	var engine := DialogueEngine.new()
	assert_true(engine._conditions_met({}))

func test_conditions_met_honours_requires_flag():
	var engine := DialogueEngine.new()
	assert_false(engine._conditions_met({"requires_flag": "spoke_now"}))
	engine.flags["spoke_now"] = true
	assert_true(engine._conditions_met({"requires_flag": "spoke_now"}))

func test_conditions_met_honours_requires_reputation():
	var engine := DialogueEngine.new()
	var holder := {"requires_reputation": {"faction_id": "officials", "min_score": 2}}
	assert_false(engine._conditions_met(holder))
	engine.reputation["officials"] = 2
	assert_true(engine._conditions_met(holder))

func test_conditions_met_requires_both_when_both_are_present():
	var engine := DialogueEngine.new()
	var holder := {
		"requires_flag": "spoke_now",
		"requires_reputation": {"faction_id": "officials", "min_score": 2},
	}
	engine.flags["spoke_now"] = true
	assert_false(engine._conditions_met(holder), "reputation still unmet")
	engine.reputation["officials"] = 2
	assert_true(engine._conditions_met(holder))

func _variant_nodes() -> Array:
	return [{
		"id": "n1",
		"text": "An officer named a sum.",
		"text_variants": [
			{"requires_flag": "bribed_before", "text": "An officer named a sum; he knew you paid."},
			{"requires_reputation": {"faction_id": "officials", "min_score": 2},
			 "text": "An officer named a sum, and named it politely."},
		],
		"choices": [{"text": "Pay.", "next_id": "n1", "effects": {}}],
	}]

func test_current_text_returns_the_base_text_when_a_node_has_no_variants():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n1")
	assert_eq(engine.current_text(), "Opening beat.")

func test_current_text_returns_the_base_text_when_no_variant_matches():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	assert_eq(engine.current_text(), "An officer named a sum.")

func test_current_text_returns_a_flag_variant_when_its_flag_is_held():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.flags["bribed_before"] = true
	assert_eq(engine.current_text(), "An officer named a sum; he knew you paid.")

func test_current_text_returns_a_reputation_variant_at_the_threshold():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.reputation["officials"] = 2
	assert_eq(engine.current_text(), "An officer named a sum, and named it politely.")

func test_current_text_ignores_a_reputation_variant_below_the_threshold():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.reputation["officials"] = 1
	assert_eq(engine.current_text(), "An officer named a sum.")

func test_current_text_takes_the_first_matching_variant_when_several_match():
	# Documents the ordering rule: array order is priority, most specific first.
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.flags["bribed_before"] = true
	engine.reputation["officials"] = 5
	assert_eq(engine.current_text(), "An officer named a sum; he knew you paid.",
		"the earlier variant must win")

func test_current_text_is_empty_for_an_unknown_node():
	var engine := DialogueEngine.new()
	assert_eq(engine.current_text(), "")

# These call validate_tree() directly rather than load_tree(), which asserts on
# invalid input and would abort the run.

func test_validate_tree_rejects_a_variant_with_no_text():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [{"requires_flag": "f"}],
		"choices": [],
	}])
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("n1"), "the error must name the node")

func test_validate_tree_rejects_a_variant_with_malformed_requires_reputation():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [{"requires_reputation": {"faction_id": "officials"}, "text": "V."}],
		"choices": [],
	}])
	assert_eq(errors.size(), 1)

func test_validate_tree_rejects_an_unparsed_gloss_token_inside_a_variant():
	# A typo in a variant would otherwise reach the screen as literal braces; the base
	# text is already checked for this and variants must be too.
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [{"requires_flag": "f", "text": "A {{dallal|dallal}} and a {{broken"}],
		"choices": [],
	}])
	assert_eq(errors.size(), 1)

func test_validate_tree_accepts_well_formed_variants():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [
			{"requires_flag": "f", "text": "Variant."},
			{"requires_reputation": {"faction_id": "officials", "min_score": 2}, "text": "Other."},
		],
		"choices": [],
	}])
	assert_eq(errors, [])

func test_current_slot_name_is_empty_when_no_stay_is_declared():
	var engine := DialogueEngine.new()
	assert_eq(engine.current_slot_name(), "")

func test_current_slot_name_tracks_the_slot_index():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening", "the next morning"]
	assert_eq(engine.current_slot_name(), "the first evening")
	engine.slot_index = 1
	assert_eq(engine.current_slot_name(), "the next morning")

func test_current_slot_name_is_empty_once_the_slots_are_spent():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening"]
	engine.slot_index = 1
	assert_eq(engine.current_slot_name(), "")

func test_slots_spent_is_false_when_no_stay_is_declared():
	# A chapter without a stay must behave exactly as it does today, so an exit gated
	# on requires_slots_spent would be permanently hidden there. That is deliberate,
	# and validation guards against making the mistake.
	var engine := DialogueEngine.new()
	assert_false(engine.slots_spent())

func test_slots_spent_flips_when_the_index_reaches_the_end():
	var engine := DialogueEngine.new()
	engine.slots = ["one", "two"]
	assert_false(engine.slots_spent())
	engine.slot_index = 2
	assert_true(engine.slots_spent())

func test_forbids_flag_hides_a_choice_once_its_flag_is_set():
	var engine := DialogueEngine.new()
	var holder := {"forbids_flag": "already_went"}
	assert_true(engine._conditions_met(holder))
	engine.flags["already_went"] = true
	assert_false(engine._conditions_met(holder))

func test_requires_slots_spent_hides_a_choice_while_time_remains():
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	var holder := {"requires_slots_spent": true}
	assert_false(engine._conditions_met(holder))
	engine.slot_index = 1
	assert_true(engine._conditions_met(holder))

func test_all_four_conditions_can_combine_on_one_choice():
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	var holder := {
		"requires_flag": "has_token",
		"forbids_flag": "already_went",
		"requires_reputation": {"faction_id": "officials", "min_score": 1},
		"requires_slots_spent": true,
	}
	engine.flags["has_token"] = true
	engine.reputation["officials"] = 1
	engine.slot_index = 1
	assert_true(engine._conditions_met(holder))
	engine.flags["already_went"] = true
	assert_false(engine._conditions_met(holder), "forbids_flag must still veto")

func _hub_nodes() -> Array:
	return [
		{
			"id": "hub",
			"stay_hub": true,
			"text": "The city, and time enough for some of it.",
			"choices": [
				{"text": "Visit the widow.", "next_id": "widow", "spends_slot": true,
				 "forbids_flag": "visited_widow", "forgone_flag": "never_visited_widow",
				 "effects": {"flags": ["visited_widow"]}},
				{"text": "Ask after the caravan master.", "next_id": "caravan", "spends_slot": true,
				 "forbids_flag": "asked_caravan", "forgone_flag": "never_asked_caravan",
				 "effects": {"flags": ["asked_caravan"]}},
				{"text": "Ask the innkeeper the day's news.", "next_id": "hub", "effects": {}},
				{"text": "Leave the city.", "next_id": "out", "requires_slots_spent": true, "effects": {}},
			],
		},
		{"id": "widow", "text": "She took the token.", "choices": [{"text": "Back.", "next_id": "hub", "effects": {}}]},
		{"id": "caravan", "text": "He had little to say.", "choices": [{"text": "Back.", "next_id": "hub", "effects": {}}]},
		{"id": "out", "text": "The road again.", "choices": []},
	]

func test_taking_an_opportunity_spends_a_slot():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening", "the next morning"]
	engine.load_tree(_hub_nodes(), "hub")
	assert_eq(engine.slot_index, 0)
	engine.choose(0)
	assert_eq(engine.slot_index, 1)

func test_a_free_choice_does_not_spend_a_slot():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening", "the next morning"]
	engine.load_tree(_hub_nodes(), "hub")
	# available_choices() order: widow, caravan, innkeeper; the exit is hidden.
	engine.choose(2)
	assert_eq(engine.slot_index, 0)

func test_a_taken_opportunity_stops_being_offered():
	var engine := DialogueEngine.new()
	engine.slots = ["one", "two"]
	engine.load_tree(_hub_nodes(), "hub")
	var before := engine.available_choices().size()
	engine.choose(0)  # widow, sets visited_widow
	engine.choose(0)  # "Back." to the hub
	assert_eq(engine.available_choices().size(), before - 1,
		"the visited opportunity must be hidden by its forbids_flag")

func test_the_exit_is_hidden_until_the_slots_are_spent():
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	engine.load_tree(_hub_nodes(), "hub")
	for choice in engine.available_choices():
		assert_ne(choice["next_id"], "out", "the exit must not be offered while time remains")
	engine.choose(0)  # spend the only slot
	engine.choose(0)  # back to the hub
	var exits := 0
	for choice in engine.available_choices():
		if choice["next_id"] == "out":
			exits += 1
	assert_eq(exits, 1, "the exit must appear once the stay is spent")

func test_spending_the_last_slot_records_every_untaken_opportunity():
	var engine := DialogueEngine.new()
	engine.slots = ["the only evening"]
	engine.load_tree(_hub_nodes(), "hub")
	engine.choose(0)  # visit the widow, spending the only slot
	assert_true(engine.flags.get("visited_widow", false), "the taken one is recorded as taken")
	assert_true(engine.flags.get("never_asked_caravan", false), "the untaken one is recorded as declined")
	assert_false(engine.flags.get("never_visited_widow", false),
		"an opportunity that was taken must not also be recorded as forgone")

func test_forgone_flags_are_not_written_while_time_remains():
	var engine := DialogueEngine.new()
	engine.slots = ["one", "two"]
	engine.load_tree(_hub_nodes(), "hub")
	engine.choose(0)
	assert_false(engine.flags.get("never_asked_caravan", false),
		"there is still a slot left; nothing has been declined yet")

func test_which_opportunity_was_taken_decides_which_flags_are_written():
	# The same single slot as above, spent the other way round, so the pairing of
	# taken and declined is proven in both directions rather than once.
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	engine.load_tree(_hub_nodes(), "hub")
	engine.choose(1)  # ask after the caravan master
	assert_true(engine.flags.get("never_visited_widow", false), "the widow was declined")
	assert_false(engine.flags.get("never_asked_caravan", false), "the caravan master was taken")

func test_validate_tree_rejects_two_stay_hubs():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([
		{"id": "a", "stay_hub": true, "text": "one", "choices": []},
		{"id": "b", "stay_hub": true, "text": "two", "choices": []},
	])
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "stay_hub")

func test_validate_tree_rejects_a_forgone_flag_with_no_forbids_flag():
	# Without forbids_flag there is no way to tell taken from untaken, so the
	# opportunity would be recorded as forgone even after being taken.
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "a", "stay_hub": true, "text": "one",
		"choices": [{"text": "go", "next_id": "a", "forgone_flag": "never_went"}],
	}])
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "forgone_flag")

func test_validate_tree_rejects_spends_slot_outside_a_hub():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "a", "text": "one",
		"choices": [{"text": "go", "next_id": "a", "spends_slot": true}],
	}])
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "spends_slot")

func test_validate_tree_accepts_a_well_formed_hub():
	var engine := DialogueEngine.new()
	assert_eq(engine.validate_tree(_hub_nodes()), [])
