extends GutTest

# Walks use Nav.expect_reaches rather than a hardcoded press count, so adding a beat
# of prose to this chapter does not fail a test that found nothing wrong. See
# tests/helpers/navigation.gd.
const Nav := preload("res://tests/helpers/navigation.gd")

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
	Nav.expect_reaches(self, engine, "n07_the_offer")
	var effects := engine.choose(0) # "Ask him plainly."
	assert_eq(effects["flags"], ["pressed_mihran_for_the_name"])
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(int(effects["reputation"]["townsfolk"]), -1)
	engine.choose(0) # n08a_pressed -> continue
	Nav.expect_reaches(self, engine, "n09_the_palace_glimpsed")
	assert_true(engine.flags.get("pressed_mihran_for_the_name", false))

func test_the_patient_path_is_walkable_and_converges_on_the_same_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	Nav.expect_reaches(self, engine, "n07_the_offer")
	var effects := engine.choose(1) # "Don't make him say it."
	assert_eq(effects["flags"], ["earned_mihrans_trust"])
	assert_eq(int(effects["reputation"]["trading_families"]), 2)
	engine.choose(0) # n08b_patient -> continue
	Nav.expect_reaches(self, engine, "n09_the_palace_glimpsed")
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

func test_mihran_has_a_small_unstated_zoroastrian_cue():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var sarraf_text: String = by_id["n02_seeking_the_sarraf"]["text"]
	assert_true(sarraf_text.contains("a small clay lamp burning steadily"), "Mihran's shop should carry a legible-but-unspoken sacred-fire cue")

func test_bost_arrival_names_saeed_by_name_not_just_teginabad_generically():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var arrival_text: String = by_id["n01_bost_arrival"]["text"]
	assert_true(arrival_text.contains("Sa'id ibn Yaqub"), "the Teginabad comparison should name Sa'id specifically, not stay generic")

func test_the_ordinary_business_choices_have_the_right_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	Nav.expect_reaches(self, engine, "n02b_the_ordinary_business")
	assert_eq(engine.current_node()["npc_portrait"], "mihran")

	var thorough_effects := engine.choose(0) # "Thorough. Weigh every coin."
	assert_eq(thorough_effects.size(), 1)
	assert_eq(int(thorough_effects["coin_spent_dirham_equivalent"]), 2)
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")
	assert_eq(engine.current_node()["npc_portrait"], "mihran")

func test_taking_the_quick_option_spends_less_and_gains_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	Nav.expect_reaches(self, engine, "n02b_the_ordinary_business")
	var quick_effects := engine.choose(1) # "Quick is fine. I trust you."
	assert_eq(quick_effects.size(), 2)
	assert_eq(int(quick_effects["coin_spent_dirham_equivalent"]), 1)
	assert_eq(quick_effects["reputation"].size(), 1)
	assert_eq(int(quick_effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")

func test_asking_about_the_mint_sets_a_flag_and_reaches_the_letters_of_credit_scene():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	Nav.expect_reaches(self, engine, "n02b_the_ordinary_business")
	engine.choose(0) # "Thorough. Weigh every coin."
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")
	var effects := engine.choose(0) # "Ask what happened to the mint's authority."
	assert_eq(effects["flags"], ["learned_of_two_mints_dispute"])
	assert_eq(engine.current_node()["id"], "n02e_the_mint_in_question")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
	assert_true(engine.flags.get("learned_of_two_mints_dispute", false))

func test_letting_the_light_coin_go_reaches_the_letters_of_credit_scene_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	Nav.expect_reaches(self, engine, "n02b_the_ordinary_business")
	engine.choose(0) # "Thorough. Weigh every coin."
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")
	var effects := engine.choose(1) # "Let it go. It's his problem now."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
	assert_false(engine.flags.get("learned_of_two_mints_dispute", false))

func test_the_seal_choice_is_hidden_without_the_prologue_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	Nav.expect_reaches(self, engine, "n05_ibn_hasan")
	assert_eq(engine.available_choices().size(), 1, "without the Prologue flag, only the fallback should be visible")
	engine.choose(0) # the only visible choice is "Keep it to yourself."
	assert_eq(engine.current_node()["id"], "n06_the_danger")

func test_showing_mihran_the_seal_reveals_its_personal_not_commercial_nature():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_unmarked_seal"] = true
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	Nav.expect_reaches(self, engine, "n05_ibn_hasan")
	assert_eq(engine.available_choices().size(), 2, "with the flag set, both choices should be visible")
	engine.choose(0) # available_choices()[0] is the gated "Show him the seal..." choice
	assert_eq(engine.current_node()["id"], "n05b_mihran_reads_the_seal")
	var effects := engine.choose(0)
	assert_eq(effects["flags"], ["mihran_read_the_seal"])
	assert_eq(engine.current_node()["id"], "n06_the_danger", "the seal beat must converge on the same node the fallback reaches")

func test_mihran_has_heard_how_the_graveside_went():
	# The Prologue's graveside fork - step forward himself, or let an elder answer -
	# happened in front of half the western bazaar, and Mihran is a sarraf who would
	# have heard which it was. Conditional text is invisible in the node graph, so
	# without this test the thread can be removed by an unrelated edit.
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n05_ibn_hasan")
	var neutral := engine.current_text()

	engine.flags["spoke_now"] = true
	var spoke := engine.current_text()
	assert_ne(spoke, neutral, "speaking for himself at the grave must reach Mihran")

	engine.flags.erase("spoke_now")
	engine.flags["waited"] = true
	var waited := engine.current_text()
	assert_ne(waited, neutral, "letting an elder answer must reach Mihran")
	assert_ne(waited, spoke, "the two histories must not read the same")

func test_the_graveside_history_does_not_change_what_mihran_offers():
	# A text variant changes what a moment means, never what happens next. Compared
	# against the unflagged count rather than a literal, because this node's
	# "Show him the seal" option is separately gated on carries_the_unmarked_seal.
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n05_ibn_hasan")
	var baseline := engine.available_choices().size()

	engine.flags["spoke_now"] = true
	assert_eq(engine.available_choices().size(), baseline)

	engine.flags.erase("spoke_now")
	engine.flags["waited"] = true
	assert_eq(engine.available_choices().size(), baseline)
