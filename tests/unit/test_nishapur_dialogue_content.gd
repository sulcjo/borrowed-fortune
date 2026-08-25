extends GutTest

# Walks use Nav.expect_reaches rather than a hardcoded press count, so adding a beat
# of prose to this chapter does not fail a test that found nothing wrong. See
# tests/helpers/navigation.gd.
const Nav := preload("res://tests/helpers/navigation.gd")

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_08_nishapur/nishapur.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n10a_ending_the_self_that_endures", "n10b_ending_the_self_dissolved"])

func test_both_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	for terminal_id in ["n10a_ending_the_self_that_endures", "n10b_ending_the_self_dissolved"]:
		assert_true(by_id[terminal_id].has("next_chapter_id"), "%s must carry its own next_chapter_id" % terminal_id)
		assert_eq(by_id[terminal_id]["next_chapter_id"], null, "%s must end the game - this is the long route's actual finale, no Chapter 9 exists" % terminal_id)

func test_every_glossed_term_id_exists_in_the_nishapur_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/nishapur_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_family_sideroad_is_hidden_without_the_token_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(5):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b -> n03c -> n04
	Nav.expect_reaches(self, engine, "n04_the_choice_before_the_khaneqah")
	assert_eq(engine.available_choices().size(), 1, "without the flag, only the fallback should be visible")
	engine.choose(0) # the only visible choice is the fallback, "Let the city's business come first."
	assert_eq(engine.current_node()["id"], "n05c_asking_after_mansur", "the fallback must skip straight past the family sideroad and into the mandatory Mansur beat")

func test_the_family_sideroad_is_visible_and_taken_with_the_token_flag():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	Nav.expect_reaches(self, engine, "n04_the_choice_before_the_khaneqah")
	assert_eq(engine.available_choices().size(), 2, "with the flag set, both choices should be visible")
	engine.choose(0) # available_choices()[0] is the gated choice when the flag is set - "Seek out the family..."
	Nav.expect_reaches(self, engine, "n05a_bahrams_family")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05c_asking_after_mansur", "the sideroad must converge on the same node the fallback reaches")

func test_the_forewarning_mention_is_hidden_without_word_sent_from_merv():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(6):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b -> n03c -> n04(gated) -> n05a
	Nav.expect_reaches(self, engine, "n05a_bahrams_family")
	assert_eq(engine.available_choices().size(), 1, "without word sent ahead from Merv, only the fallback should be visible")
	engine.choose(0)
	Nav.expect_reaches(self, engine, "n05c_asking_after_mansur")

func test_the_forewarning_mention_is_visible_and_taken_when_word_was_sent_from_merv():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.flags["warned_bahrams_household"] = true
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(6):
		engine.choose(0)
	Nav.expect_reaches(self, engine, "n05a_bahrams_family")
	assert_eq(engine.available_choices().size(), 2, "with the Merv flag set, both choices should be visible")
	engine.choose(0) # available_choices()[0] is the gated "Mention that word may have already reached them." choice
	assert_eq(engine.current_node()["id"], "n05b_word_had_reached_them")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05c_asking_after_mansur", "the forewarning beat must converge on the same node the fallback reaches")

func test_the_mansur_scene_is_mandatory_and_reveals_the_fathers_reason():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(6):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b -> n03c -> n04(fallback) -> n05c
	Nav.expect_reaches(self, engine, "n05c_asking_after_mansur")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05d_what_the_shipment_was")
	engine.choose(0)
	Nav.expect_reaches(self, engine, "n05e_why_his_father")
	var effects := engine.choose(0) # without mihran_read_the_seal, only the fallback is visible
	assert_eq(effects["flags"], ["learned_the_fathers_reason"])
	assert_eq(engine.current_node()["id"], "n05f_the_seal_shown_too_late")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_khaneqah_at_dusk", "the Mansur beat must converge on the same node every other path reaches")

func test_the_seal_reveal_at_nishapur_takes_the_fallback_without_mihrans_read():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(6):
		engine.choose(0)
	engine.choose(0) # n05c -> n05d
	engine.choose(0) # n05d -> n05e
	Nav.expect_reaches(self, engine, "n05e_why_his_father")
	assert_eq(engine.available_choices().size(), 1, "without mihran_read_the_seal, only the fallback should be visible")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05f_the_seal_shown_too_late")

func test_the_seal_reveal_at_nishapur_takes_the_richer_branch_with_mihrans_read():
	var engine := DialogueEngine.new()
	engine.flags["mihran_read_the_seal"] = true
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(6):
		engine.choose(0)
	engine.choose(0) # n05c -> n05d
	engine.choose(0) # n05d -> n05e
	Nav.expect_reaches(self, engine, "n05e_why_his_father")
	assert_eq(engine.available_choices().size(), 2, "with mihran_read_the_seal set, both choices should be visible")
	engine.choose(0) # available_choices()[0] is the gated richer branch
	assert_eq(engine.current_node()["id"], "n05f_the_unanswerable_part")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_khaneqah_at_dusk", "both seal-reveal variants must converge on the same node")

func test_sending_coin_to_nasuh_repays_part_of_his_debt_and_reaches_n04():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(3):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b
	assert_eq(engine.current_node()["id"], "n03b_word_to_nasuh")
	var effects := engine.choose(0) # "Send what you can spare toward Nasuh's wages."
	assert_eq(effects["debt_repaid"], {"creditor_name": "Nasuh's own back wages, unpaid four months", "amount_dirham_equivalent": 20.0})
	assert_eq(engine.current_node()["id"], "n03c_what_was_sent")
	engine.choose(0) # "Continue."
	Nav.expect_reaches(self, engine, "n04_the_choice_before_the_khaneqah")

func test_letting_nasuhs_wages_wait_reaches_n04_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(3):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b
	assert_eq(engine.current_node()["id"], "n03b_word_to_nasuh")
	var effects := engine.choose(1) # "There's nothing to spare. Let it wait."
	assert_eq(effects, {})
	Nav.expect_reaches(self, engine, "n04_the_choice_before_the_khaneqah")

func test_the_endures_choice_reaches_its_terminal_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(13):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b -> n03c -> n04(fallback) -> n05c -> n05d -> n05e -> n05f -> n06 -> n07 -> n08 -> n09
	Nav.expect_reaches(self, engine, "n09_the_final_choice")
	var effects := engine.choose(0) # "Hold to the self that carried you this far."
	assert_eq(effects["flags"], ["chose_the_self_that_endures"])
	assert_eq(engine.current_node()["id"], "n10a_ending_the_self_that_endures")
	assert_true(engine.is_chapter_end())

func test_the_dissolved_choice_reaches_its_terminal_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	Nav.expect_reaches(self, engine, "n09_the_final_choice")
	var effects := engine.choose(1) # "Let go of insisting on being anyone in particular."
	assert_eq(effects["flags"], ["chose_the_self_dissolved"])
	assert_eq(engine.current_node()["id"], "n10b_ending_the_self_dissolved")
	assert_true(engine.is_chapter_end())

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n10a_ending_the_self_that_endures", "without the token flag, choose(0) at n04 takes the fallback, and choose(0) at n09 takes the 'endures' ending")
