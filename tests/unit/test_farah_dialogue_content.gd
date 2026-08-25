extends GutTest

# Walks use Nav.expect_reaches rather than a hardcoded press count, so adding a beat
# of prose to this chapter does not fail a test that found nothing wrong. See
# tests/helpers/navigation.gd.
const Nav := preload("res://tests/helpers/navigation.gd")

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

func test_the_plunder_terminal_node_now_points_at_chapter_4b():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_eq(by_id["n19b_departure_farah_plunder"]["next_chapter_id"], "chapter_04b_herat_favor")

func test_the_mystery_terminal_node_now_points_at_chapter_4a():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_eq(by_id["n18a_departure_farah_mystery"]["next_chapter_id"], "chapter_04a_herat")

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
	Nav.expect_reaches(self, engine, "n04_the_choice_at_the_checkpoint")
	var vouch_effects := engine.choose(0) # "Tell him they're traveling with you."
	assert_eq(vouch_effects["flags"], ["vouched_for_the_family_at_farah"])
	assert_eq(int(vouch_effects["reputation"]["townsfolk"]), 2)
	assert_eq(int(vouch_effects["reputation"]["ghaznavid_officials"]), -1)

func test_the_checkpoint_forks_other_branch_sets_its_own_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	var uninvolved_effects := engine.choose(1) # "Say nothing. It isn't your caravan to risk."
	assert_false(uninvolved_effects.has("flags"), "stayed_uninvolved_at_farah was removed - it was never read anywhere in content/")
	assert_eq(int(uninvolved_effects["reputation"]["ghaznavid_officials"]), 1)

func test_the_family_again_bonus_is_available_when_vouched():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	Nav.expect_reaches(self, engine, "n12_the_common_room")
	assert_eq(engine.available_choices().size(), 2, "the family-again bonus should be visible because index 0 at the checkpoint choice vouches for the family")

func test_the_family_again_bonus_is_hidden_when_uninvolved():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	engine.choose(1) # "Say nothing. It isn't your caravan to risk." - does not set the vouched flag
	Nav.expect_reaches(self, engine, "n12_the_common_room")
	assert_eq(engine.available_choices().size(), 1, "the family-again bonus should be hidden because the family was never vouched for")

func test_the_ledgers_first_entry_is_mandatory_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	Nav.expect_reaches(self, engine, "n12_the_common_room")
	var effects := engine.choose(0) # "Continue." - the always-visible first choice
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n12y_the_ledgers_first_entry")
	var ledger_effects := engine.choose(0)
	assert_eq(ledger_effects["flags"], ["began_his_own_ledger"])
	assert_eq(engine.current_node()["id"], "n13_two_doors")

func test_the_price_of_a_bed_fork_carries_coin_spent_and_reputation_differently():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	Nav.expect_reaches(self, engine, "n10_the_price_of_a_bed")
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
	for i in range(14):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice", "without the flag, index 0 at n13 should always skip straight past the bonus")

func test_the_name_already_known_bonus_is_visible_when_the_flag_is_set():
	var engine := DialogueEngine.new()
	engine.flags["pressed_mihran_for_the_name"] = true
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	Nav.expect_reaches(self, engine, "n13_two_doors")
	assert_eq(engine.available_choices().size(), 2, "the name-already-known bonus should be visible because pressed_mihran_for_the_name is set")

func test_the_mystery_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	Nav.expect_reaches(self, engine, "n14_the_choice")
	var fork_effects := engine.choose(0) # "Go to Umm-Kavus's channel."
	assert_eq(fork_effects["flags"], ["chose_umm_kavus_channel"])
	assert_eq(int(fork_effects["reputation"]["trading_families"]), 1)
	engine.choose(0) # n15a_umm_kavus_channel -> continue
	engine.choose(0) # n16a_the_wait -> continue
	var name_effects := engine.choose(0) # n17a_the_name_given_cleanly -> continue
	assert_eq(name_effects["flags"], ["knows_the_second_marks_name"])
	assert_eq(int(name_effects["reputation"]["trading_families"]), 1)
	Nav.expect_reaches(self, engine, "n18a_departure_farah_mystery")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_umm_kavus_channel", false))
	assert_true(engine.flags.get("knows_the_second_marks_name", false))

func test_the_plunder_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	Nav.expect_reaches(self, engine, "n14_the_choice")
	var fork_effects := engine.choose(1) # "Seek out Tahir."
	assert_eq(fork_effects["flags"], ["chose_tahirs_price"])
	assert_eq(int(fork_effects["reputation"]["trading_families"]), -1)
	engine.choose(0) # n15b_finding_tahir -> continue
	engine.choose(0) # n16b_tahirs_price -> continue
	engine.choose(0) # n17b_the_war_he_carries -> continue
	var favor_effects := engine.choose(0) # n18b_the_favor_owed -> continue
	assert_eq(favor_effects["flags"], ["knows_the_second_marks_name", "owes_tahir_a_favor"])
	assert_eq(int(favor_effects["reputation"]["townsfolk"]), -1)
	Nav.expect_reaches(self, engine, "n19b_departure_farah_plunder")
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
	Nav.expect_reaches(self, engine, "n18a_departure_farah_mystery")

func test_the_clean_reveal_resolves_the_second_mark_not_the_main_seal():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var reveal_text: String = by_id["n17a_the_name_given_cleanly"]["text"]
	assert_true(reveal_text.contains("the owner of the second mark itself"), "the clean channel must resolve the second mark, matching what knows_the_second_marks_name actually claims")
	assert_false(reveal_text.contains("the same house whose seal Mihran had first recognized"), "must not merely re-confirm the already-known main house seal")

func test_tahirs_campaign_dates_are_anchored_to_the_1035_present():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n16b_tahirs_price"]["text"].contains("ten years gone"))
	assert_true(by_id["n18b_the_favor_owed"]["text"].contains("ten years cold"))
	assert_false(by_id["n16b_tahirs_price"]["text"].contains("three years gone"))
	assert_false(by_id["n18b_the_favor_owed"]["text"].contains("three years cold"))

# Four threads reaching Farah from Teginabad and Bost. Conditional text is invisible
# in the node graph, so without a test per thread an unrelated edit can remove one
# and nothing notices.

func _text_at(node_id: String, flags: Dictionary) -> String:
	var engine := DialogueEngine.new()
	engine.flags = flags
	engine.load_tree(_load_nodes(), node_id)
	return engine.current_text()

func test_earning_mihrans_trust_changes_how_the_name_is_carried_to_umm_kavus():
	# The base text says the name was given "under duress", which is only true on the
	# path where Farrukh asked plainly. On the patient path Mihran volunteered it, so
	# the base reading was factually wrong there - this fixes that as well as adding
	# the consequence.
	var neutral := _text_at("n13x_the_name_already_known", {})
	var trusted := _text_at("n13x_the_name_already_known", {"earned_mihrans_trust": true})
	assert_ne(trusted, neutral, "having earned his trust must reach Umm-Kavus")
	assert_true(neutral.contains("under duress"), "the base reading still assumes it was extracted")
	assert_false(trusted.contains("under duress"), "on the patient path nothing was extracted")

func test_having_told_said_about_the_letter_reaches_the_checkpoint():
	var neutral := _text_at("n04_the_choice_at_the_checkpoint", {})
	var revealed := _text_at("n04_the_choice_at_the_checkpoint", {"revealed_letter_to_said": true})
	assert_ne(revealed, neutral, "volunteering to one official must colour facing the next")

func test_the_two_mints_dispute_reaches_the_first_ledger_entry():
	var neutral := _text_at("n12y_the_ledgers_first_entry", {})
	var learned := _text_at("n12y_the_ledgers_first_entry", {"learned_of_two_mints_dispute": true})
	assert_ne(learned, neutral, "what he learned about rival coin must reach what he writes down")

func test_heeding_the_desert_warning_reaches_the_arrival_at_farah():
	var neutral := _text_at("n01_farah_arrival", {})
	var heeded := _text_at("n01_farah_arrival", {"heeded_the_desert_warning": true})
	assert_ne(heeded, neutral, "provisioning for the crossing must change arriving from it")

func test_none_of_the_four_payoffs_change_what_is_on_offer():
	# A variant changes what a moment means, never what happens next.
	var sites := {
		"n13x_the_name_already_known": "earned_mihrans_trust",
		"n04_the_choice_at_the_checkpoint": "revealed_letter_to_said",
		"n12y_the_ledgers_first_entry": "learned_of_two_mints_dispute",
		"n01_farah_arrival": "heeded_the_desert_warning",
	}
	for node_id in sites:
		var plain := DialogueEngine.new()
		plain.load_tree(_load_nodes(), node_id)
		var baseline := plain.available_choices().size()

		var flagged := DialogueEngine.new()
		flagged.flags[sites[node_id]] = true
		flagged.load_tree(_load_nodes(), node_id)
		assert_eq(flagged.available_choices().size(), baseline,
			"%s must offer the same choices either way" % node_id)
