extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_01_teginabad/teginabad.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n12_departure_provisioned"])

func test_every_glossed_term_id_exists_in_the_teginabad_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/teginabad_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_choice")
	var effects := engine.choose(0) # "Pay for expedited passage."
	# NOTE: not a single assert_eq(effects, {...}) — JSON.parse_string() always returns
	# floats for JSON numbers, and Godot's native Dictionary `==` (what assert_eq uses for
	# Dictionary values) requires exact type equality at every nested leaf, so a
	# whole-dict comparison against int literals here would fail regardless of whether the
	# content is correct. Asserting flags and each reputation value individually verifies
	# the identical content without hitting that type-strictness trap. The int() casts on the
	# JSON-sourced side are required for the same underlying reason at a smaller scale:
	# without them the value comparison still passes, but GUT logs a "Float/Int comparison"
	# warning and this suite's output must stay clean. Do not simplify them away.
	assert_eq(effects.size(), 3)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 6)
	assert_eq(effects["flags"], ["bribed_teginabad_official"])
	assert_eq(effects["reputation"].size(), 3)
	assert_eq(int(effects["reputation"]["townsfolk"]), -1)
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
	engine.choose(0) # n07a_bribe -> continue
	assert_eq(engine.current_node()["id"], "n08_guide_transition")
	assert_true(engine.flags.get("bribed_teginabad_official", false))

func test_the_honest_path_is_walkable_and_converges_on_the_same_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_choice")
	var effects := engine.choose(1) # "Let the inspection happen."
	# See NOTE in test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation() above
	# on why this is split instead of one assert_eq(effects, {...}).
	assert_eq(effects.size(), 2)
	assert_eq(effects["flags"], ["honest_at_teginabad"])
	assert_eq(effects["reputation"].size(), 1)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 2)
	engine.choose(0) # n07b_inspection -> "Say nothing."
	assert_eq(engine.current_node()["id"], "n08_guide_transition")
	assert_true(engine.flags.get("honest_at_teginabad", false))

func test_letter_callback_choice_only_appears_with_the_prologue_flag_set():
	var engine_without_flag := DialogueEngine.new()
	engine_without_flag.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine_without_flag.choose(0)
	engine_without_flag.choose(1) # "Let the inspection happen."
	assert_eq(engine_without_flag.available_choices().size(), 1)

	var engine_with_flag := DialogueEngine.new()
	engine_with_flag.load_tree(_load_nodes(), "n01_teginabad_arrival")
	engine_with_flag.flags["read_unsigned_letter"] = true
	for i in range(5):
		engine_with_flag.choose(0)
	engine_with_flag.choose(1)
	assert_eq(engine_with_flag.available_choices().size(), 2)

	var chosen_effects := engine_with_flag.choose(1) # "Tell him what you read..."
	# See NOTE in test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation() above
	# on why this is split instead of one assert_eq(chosen_effects, {...}).
	assert_eq(chosen_effects.size(), 2)
	assert_eq(chosen_effects["flags"], ["revealed_letter_to_said"])
	assert_eq(chosen_effects["reputation"].size(), 1)
	assert_eq(int(chosen_effects["reputation"]["ghaznavid_officials"]), 1)
	engine_with_flag.choose(0) # n07b_letter_callback -> continue
	assert_eq(engine_with_flag.current_node()["id"], "n08_guide_transition")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")

func test_paying_the_provisioner_fair_price_spends_eight_and_gains_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_provisioner")
	var effects := engine.choose(0) # "Pay what she asks."
	# See NOTE in test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation() above
	# on why this is split instead of one assert_eq(effects, {...}).
	assert_eq(effects.size(), 2)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 8)
	assert_eq(effects["reputation"].size(), 1)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n11b_the_provisioners_stake")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")

func test_haggling_then_accepting_the_counter_spends_seven_and_sets_the_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_provisioner")
	engine.choose(1) # "Try to talk her down."
	assert_eq(engine.current_node()["id"], "n11_provisioner_pushback")
	var effects := engine.choose(0) # "Take the seven."
	assert_eq(effects.size(), 2)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 7)
	assert_eq(effects["flags"], ["haggled_at_teginabad"])
	assert_eq(engine.current_node()["id"], "n11b_the_provisioners_stake")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")
	assert_true(engine.flags.get("haggled_at_teginabad", false))

func test_haggling_then_backing_off_spends_eight_and_still_gains_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	engine.choose(1) # "Try to talk her down."
	assert_eq(engine.current_node()["id"], "n11_provisioner_pushback")
	var effects := engine.choose(1) # "Pay the eight after all."
	assert_eq(effects.size(), 2)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 8)
	assert_eq(effects["reputation"].size(), 1)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n11b_the_provisioners_stake")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")
	assert_false(engine.flags.get("haggled_at_teginabad", false), "backing off must not set the flag the accept-the-counter path sets")

func test_taking_only_water_spends_three_with_no_reputation_or_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_provisioner")
	var effects := engine.choose(2) # "Take the water, skip the rest, and go."
	assert_eq(effects.size(), 1)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 3)
	assert_eq(engine.current_node()["id"], "n11b_the_provisioners_stake")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")

func test_the_packet_reads_as_a_closed_door_if_the_letter_went_unread():
	# Declining to unfold Nasuh's letter in Ghazni already has a consequence here: the
	# "tell him what you read" option is gated on read_unsigned_letter and simply never
	# appears. That absence was silent - nothing told the player they lacked anything.
	# The variant makes it felt without changing what is on offer.
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n07b_inspection")
	var neutral := engine.current_text()

	engine.flags["avoided_unsigned_letter"] = true
	var avoided := engine.current_text()
	assert_ne(avoided, neutral, "choosing not to read the letter must reach the packet scene")

func test_the_packet_scene_offers_the_same_choices_whether_or_not_the_letter_was_read():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n07b_inspection")
	var baseline := engine.available_choices().size()
	engine.flags["avoided_unsigned_letter"] = true
	assert_eq(engine.available_choices().size(), baseline,
		"the variant must not change what is on offer; only read_unsigned_letter does that")

func test_reading_the_letter_still_opens_the_extra_option_at_the_packet():
	# Guards the other side: the gated choice must keep working alongside the variant.
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n07b_inspection")
	var without := engine.available_choices().size()
	engine.flags["read_unsigned_letter"] = true
	assert_eq(engine.available_choices().size(), without + 1)
